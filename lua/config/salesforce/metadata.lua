--------------------------------------------------------------------------------
-- Salesforce metadata inventory — callback-safe org flow + project sf_cache
-- Reuses sf.nvim's legacy <Type>_<org>.json files so its lists and browser agree.
-- Browser-only indexes/manifests live below sf_cache/metadata-browser/.
--------------------------------------------------------------------------------

local M = {}
local process = require("config.salesforce.process")

local SCHEMA_VERSION = 1
local BROWSER_SLICE_SCHEMA = 1

-- Cached branches paint immediately; older branches refresh in the background.
local BROWSER_TTL_SECONDS = 300
-- local BROWSER_TTL_SECONDS = 0 -- always revalidate every opened branch

-- Bound org-list calls so an All refresh does not flood Metadata API.
local CONCURRENCY = 4
-- local CONCURRENCY = 2 -- gentler on slower orgs, but roughly twice as long

-- Used only when sfdx-project.json omits sourceApiVersion.
local FALLBACK_API_VERSION = "65.0"
-- local FALLBACK_API_VERSION = "64.0" -- pin older projects explicitly instead
local FOLDER_TYPES = {
  Dashboard = "DashboardFolder",
  Document = "DocumentFolder",
  EmailTemplate = "EmailFolder",
  Report = "ReportFolder",
}

local generation = 0
local refreshing = false
local orgs = {}
local orgs_root
local current_identity
local browser_inflight = {}
local browser_retrieving = false
local browser_retrieve_callback
local browser_retrieve_generation = 0
local target_selection_generation = 0
local target_selection_running = false
local pending_target_selection

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "SF metadata" })
end

local function sf_util()
  return require("sf.util")
end

local function safe_name(value)
  local sanitized = tostring(value or ""):gsub("[/\\:%z]", "_")
  return sanitized
end

local function cache_name(value)
  local text = tostring(value or "")
  return string.format("%s_%s", safe_name(text), vim.fn.sha256(text):sub(1, 12))
end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path, "b")
  if not ok or not lines or #lines == 0 then
    return nil
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and decoded or nil
end

local function atomic_write_json(path, value)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local tmp = string.format("%s.tmp.%s", path, (vim.uv or vim.loop).hrtime())
  local ok, encoded = pcall(vim.json.encode, value)
  if not ok then
    return false, encoded
  end

  local write_ok, write_err = pcall(vim.fn.writefile, { encoded }, tmp, "b")
  if not write_ok then
    return false, write_err
  end

  local renamed, rename_err = (vim.uv or vim.loop).fs_rename(tmp, path)
  if not renamed then
    pcall((vim.uv or vim.loop).fs_unlink, tmp)
    return false, rename_err
  end
  return true
end

local function atomic_write_lines(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local tmp = string.format("%s.tmp.%s", path, (vim.uv or vim.loop).hrtime())
  local write_ok, write_err = pcall(vim.fn.writefile, lines, tmp)
  if not write_ok then
    return false, write_err
  end

  local renamed, rename_err = (vim.uv or vim.loop).fs_rename(tmp, path)
  if not renamed then
    pcall((vim.uv or vim.loop).fs_unlink, tmp)
    return false, rename_err
  end
  return true
end

local function project_root()
  local bufnr = vim.api.nvim_get_current_buf()
  local tagged_root = vim.b[bufnr].sf_project_root
  if type(tagged_root) == "string" and tagged_root ~= "" then
    return vim.fs.normalize(tagged_root)
  end
  local util_ok, util = pcall(sf_util)
  local ok, root = false, nil
  if util_ok then
    ok, root = pcall(util.get_sf_root)
  end
  if not ok or not root then
    notify("Open this from a Salesforce project (sfdx-project.json required).", vim.log.levels.ERROR)
    return nil
  end
  return vim.fs.normalize(root)
end

local function target_org()
  local org = sf_util().target_org
  if not org or org == "" then
    notify("Set a local target org first with <leader>So.", vim.log.levels.ERROR)
    return nil
  end
  return org
end

local function source_api_version(root)
  local project = read_json(vim.fs.joinpath(root, "sfdx-project.json"))
  if project and type(project.sourceApiVersion) == "string" then
    return project.sourceApiVersion
  end
  return nil
end

local function cache_paths(root, org)
  local folder = ((vim.g.sf or {}).plugin_folder_name or "sf_cache"):gsub("^[/\\]+", ""):gsub("[/\\]+$", "")
  local cache = vim.fs.joinpath(root, folder)
  local browser = vim.fs.joinpath(cache, "metadata-browser", safe_name(org))
  local slices = vim.fs.joinpath(browser, "slices")
  return {
    root = cache,
    browser = browser,
    index = vim.fs.joinpath(browser, "index.json"),
    metadata_types = vim.fs.joinpath(cache, "metadata-types.json"),
    member = function(metadata_type)
      return vim.fs.joinpath(cache, string.format("%s_%s.json", safe_name(metadata_type), safe_name(org)))
    end,
    manifests = vim.fs.joinpath(browser, "manifests"),
    type_slice = function(metadata_type)
      return vim.fs.joinpath(slices, "types", cache_name(metadata_type) .. ".json")
    end,
    folder_slice = function(metadata_type, folder)
      return vim.fs.joinpath(slices, "folders", cache_name(metadata_type), cache_name(folder) .. ".json")
    end,
  }
end

local function context()
  local root = project_root()
  local org = root and target_org() or nil
  if not root or not org then
    return nil
  end
  local identity = current_identity
  if identity and identity.alias ~= org and identity.username ~= org then
    identity = nil
  end
  return {
    root = root,
    org = org,
    api_version = source_api_version(root),
    identity = identity,
    paths = cache_paths(root, org),
  }
end

local function run_json(args, opts, callback)
  opts = opts or {}
  local token = opts.generation or generation

  return process.run_sf_json(args, opts, function(err, result, obj)
    if token ~= generation then
      return
    end
    callback(err, result, obj)
  end)
end

local function with_api_version(args, api_version)
  if api_version and api_version ~= "" then
    vim.list_extend(args, { "--api-version", api_version })
  end
  return args
end

local function read_index(ctx)
  local index = read_json(ctx.paths.index)
  if type(index) ~= "table" or index.schema ~= SCHEMA_VERSION then
    index = {
      schema = SCHEMA_VERSION,
      org = ctx.org,
      api_version = ctx.api_version,
      updated_at = nil,
      catalog_fetched_at = nil,
      catalog_error = nil,
      types = {},
      fetched = {},
      errors = {},
      browser_errors = {},
    }
  end
  index.types = index.types or {}
  index.fetched = index.fetched or {}
  index.errors = index.errors or {}
  index.browser_errors = index.browser_errors or {}
  index.org = ctx.org
  index.api_version = ctx.api_version
  if ctx.identity then
    index.identity = ctx.identity
  end

  -- Hydrate an index from sf.nvim's legacy cache so cached type/member data is usable.
  local seen = {}
  for _, descriptor in ipairs(index.types or {}) do
    if descriptor.xmlName then
      seen[descriptor.xmlName] = true
    end
  end
  local legacy_types = read_json(ctx.paths.metadata_types)
  for _, descriptor in ipairs((legacy_types or {}).metadataObjects or {}) do
    if descriptor.xmlName and not seen[descriptor.xmlName] then
      index.types[#index.types + 1] = descriptor
      seen[descriptor.xmlName] = true
    end
  end
  for _, metadata_type in ipairs((vim.g.sf or {}).types_to_retrieve or {}) do
    if not seen[metadata_type] then
      index.types[#index.types + 1] = { xmlName = metadata_type, inFolder = false }
      seen[metadata_type] = true
    end
  end
  return index
end

local function save_index(ctx, index)
  index.updated_at = os.time()
  local ok, err = atomic_write_json(ctx.paths.index, index)
  if not ok then
    notify("Could not write metadata index: " .. tostring(err), vim.log.levels.ERROR)
  end
end

local function is_stale(timestamp, ttl)
  if not timestamp or BROWSER_TTL_SECONDS == 0 then
    return true
  end
  return os.time() - timestamp >= (ttl or BROWSER_TTL_SECONDS)
end

local function browser_context_id(ctx)
  return table.concat({ ctx.root, ctx.org }, "\0")
end

local function browser_context_is_current(ctx, token)
  if token ~= generation then
    return false
  end
  local ok, util = pcall(require, "sf.util")
  if not ok or util.target_org ~= ctx.org then
    return false
  end
  return true
end

local function complete_browser_request(key, ...)
  local request = browser_inflight[key]
  browser_inflight[key] = nil
  for _, callback in ipairs((request and request.callbacks) or {}) do
    local ok, err = pcall(callback, ...)
    if not ok then
      notify("Org Browser callback failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

local function invalidate_browser_requests(reason)
  generation = generation + 1
  refreshing = false
  browser_retrieving = false
  browser_retrieve_generation = browser_retrieve_generation + 1
  target_selection_generation = target_selection_generation + 1
  target_selection_running = false
  pending_target_selection = nil
  local retrieve_callback = browser_retrieve_callback
  browser_retrieve_callback = nil
  local pending = browser_inflight
  browser_inflight = {}
  for _, request in pairs(pending) do
    for _, callback in ipairs(request.callbacks or {}) do
      pcall(callback, false, nil, reason or "Salesforce context changed.")
    end
  end
  if retrieve_callback then
    pcall(retrieve_callback, false, nil, reason or "Salesforce context changed.")
  end
end

local function begin_browser_request(ctx, operation, callback, starter)
  local key = table.concat({ browser_context_id(ctx), operation }, "\0")
  if browser_inflight[key] then
    if callback then
      browser_inflight[key].callbacks[#browser_inflight[key].callbacks + 1] = callback
    end
    return browser_inflight[key].handle
  end

  local request = { callbacks = callback and { callback } or {} }
  browser_inflight[key] = request
  request.handle = starter(function(...)
    complete_browser_request(key, ...)
  end)
  return request.handle
end

local function slice_spec(ctx, reference, descriptor)
  if reference.folder then
    return {
      kind = "components",
      path = ctx.paths.folder_slice(reference.type, reference.folder),
    }
  end
  if descriptor and descriptor.inFolder == true then
    return {
      kind = "folders",
      path = ctx.paths.type_slice(reference.type),
    }
  end
  return {
    kind = "components",
    path = ctx.paths.type_slice(reference.type),
  }
end

local function read_browser_slice(ctx, reference, descriptor)
  local spec = slice_spec(ctx, reference, descriptor)
  local slice = read_json(spec.path)
  if
    type(slice) ~= "table"
    or slice.schema ~= BROWSER_SLICE_SCHEMA
    or slice.org ~= ctx.org
    or slice.type ~= reference.type
    or slice.folder ~= reference.folder
  then
    return nil
  end
  slice.kind = spec.kind
  slice.items = type(slice.items) == "table" and slice.items or {}
  slice.stale = is_stale(slice.fetched_at)
  return slice
end

local function write_browser_slice(ctx, reference, descriptor, items)
  local spec = slice_spec(ctx, reference, descriptor)
  local payload = {
    schema = BROWSER_SLICE_SCHEMA,
    org = ctx.org,
    kind = spec.kind,
    type = reference.type,
    folder = reference.folder,
    fetched_at = os.time(),
    items = items or {},
  }
  local ok, err = atomic_write_json(spec.path, payload)
  if not ok then
    return nil, tostring(err)
  end
  payload.stale = false
  return payload
end

local function descriptor_map(index)
  local result = {}
  for _, descriptor in ipairs(index.types or {}) do
    if descriptor.xmlName then
      result[descriptor.xmlName] = descriptor
    end
  end
  return result
end

local function metadata_descriptor(index, metadata_type)
  return descriptor_map(index)[metadata_type]
end

local function list_metadata_args(ctx, metadata_type, folder)
  local args = {
    "sf",
    "org",
    "list",
    "metadata",
    "--metadata-type",
    metadata_type,
    "--target-org",
    ctx.org,
    "--json",
  }
  if folder and folder ~= "" then
    vim.list_extend(args, { "--folder", folder })
  end
  return with_api_version(args, ctx.api_version)
end

local function list_metadata(ctx, metadata_type, folder, callback)
  run_json(list_metadata_args(ctx, metadata_type, folder), { cwd = ctx.root }, callback)
end

local function run_queue(items, worker, done, limit)
  if #items == 0 then
    done()
    return
  end
  limit = limit or CONCURRENCY

  local cursor = 1
  local active = 0
  local completed = 0

  local pump
  pump = function()
    while active < limit and cursor <= #items do
      local item = items[cursor]
      cursor = cursor + 1
      active = active + 1
      worker(item, function()
        active = active - 1
        completed = completed + 1
        if completed == #items then
          done()
        else
          pump()
        end
      end)
    end
  end
  pump()
end

local function fetch_foldered_type(ctx, metadata_type, callback)
  local folder_type = FOLDER_TYPES[metadata_type]
  if not folder_type then
    list_metadata(ctx, metadata_type, nil, callback)
    return
  end

  list_metadata(ctx, folder_type, nil, function(folder_err, folders)
    if folder_err then
      callback(folder_err)
      return
    end

    local members = {}
    local folder_errors = {}
    run_queue(folders or {}, function(folder, next_folder)
      list_metadata(ctx, metadata_type, folder.fullName, function(member_err, folder_members)
        if member_err then
          folder_errors[#folder_errors + 1] = string.format("%s: %s", folder.fullName, member_err)
        else
          vim.list_extend(members, folder_members or {})
        end
        next_folder()
      end)
    end, function()
      if #folder_errors > 0 then
        callback(table.concat(folder_errors, " | "))
      else
        callback(nil, members)
      end
    end, 1)
  end)
end

local function fetch_type(ctx, metadata_type, descriptor, callback)
  if descriptor and descriptor.inFolder then
    fetch_foldered_type(ctx, metadata_type, callback)
  else
    list_metadata(ctx, metadata_type, nil, callback)
  end
end

local function normalize_types(types)
  local seen = {}
  local normalized = {}
  for _, metadata_type in ipairs(types or {}) do
    if type(metadata_type) == "string" and metadata_type ~= "" and not seen[metadata_type] then
      seen[metadata_type] = true
      normalized[#normalized + 1] = metadata_type
    end
  end
  table.sort(normalized)
  return normalized
end

local function refresh_types(ctx, types, index, callback)
  types = normalize_types(types)
  local descriptors = descriptor_map(index)
  local total = #types
  local finished = 0
  local had_error = false

  if total == 0 then
    refreshing = false
    callback(true, index)
    return
  end

  run_queue(types, function(metadata_type, next_type)
    fetch_type(ctx, metadata_type, descriptors[metadata_type], function(err, members)
      finished = finished + 1
      if err then
        had_error = true
        index.errors[metadata_type] = err
      else
        index.errors[metadata_type] = nil
        index.fetched[metadata_type] = {
          at = os.time(),
          count = #(members or {}),
        }
        local write_ok, write_err = atomic_write_json(ctx.paths.member(metadata_type), members or {})
        if not write_ok then
          had_error = true
          index.errors[metadata_type] = tostring(write_err)
        end
      end
      save_index(ctx, index)

      if total >= 20 and (finished % 20 == 0 or finished == total) then
        notify(string.format("Metadata inventory: %d/%d types", finished, total))
      end
      next_type()
    end)
  end, function()
    refreshing = false
    save_index(ctx, index)
    callback(not had_error, index)
  end)
end

local function begin_refresh(ctx)
  if refreshing then
    notify("A metadata inventory update is already running.", vim.log.levels.WARN)
    return false
  end
  refreshing = true
  vim.fn.mkdir(ctx.paths.browser, "p")
  return true
end

function M.refresh_common(callback)
  local ctx = context()
  if not ctx or not begin_refresh(ctx) then
    return
  end

  local types = vim.deepcopy((vim.g.sf or {}).types_to_retrieve or {})
  local index = read_index(ctx)
  local known = descriptor_map(index)
  for _, metadata_type in ipairs(types) do
    if not known[metadata_type] then
      index.types[#index.types + 1] = { xmlName = metadata_type, inFolder = false }
    end
  end

  notify(string.format("Refreshing %d common metadata types for %s…", #types, ctx.org))
  refresh_types(ctx, types, index, function(ok, updated)
    if ok then
      notify("Common metadata inventory updated for " .. ctx.org)
    else
      notify("Common inventory finished with errors; previous good files were preserved.", vim.log.levels.WARN)
    end
    if callback then
      callback(ok, updated)
    end
  end)
end

function M.refresh_all(callback)
  local ctx = context()
  if not ctx or not begin_refresh(ctx) then
    return
  end

  notify("Fetching enabled metadata types for " .. ctx.org .. "…")
  local args = {
    "sf",
    "org",
    "list",
    "metadata-types",
    "--target-org",
    ctx.org,
    "--json",
  }
  run_json(with_api_version(args, ctx.api_version), { cwd = ctx.root }, function(err, result)
    if err or type(result) ~= "table" then
      refreshing = false
      notify("Metadata type refresh failed: " .. (err or "invalid CLI response"), vim.log.levels.ERROR)
      if callback then
        callback(false)
      end
      return
    end

    local index = read_index(ctx)
    index.types = result.metadataObjects or {}
    index.catalog_fetched_at = os.time()
    index.catalog_error = nil
    atomic_write_json(ctx.paths.metadata_types, result)

    local types = {}
    for _, descriptor in ipairs(index.types) do
      if descriptor.xmlName then
        types[#types + 1] = descriptor.xmlName
      end
    end
    notify(string.format("Refreshing all %d enabled metadata types…", #types))
    refresh_types(ctx, types, index, function(ok, updated)
      if ok then
        notify("Full metadata inventory updated for " .. ctx.org)
      else
        notify("Full inventory finished with partial errors; inspect the browser index.", vim.log.levels.WARN)
      end
      if callback then
        callback(ok, updated)
      end
    end)
  end)
end

function M.refresh_type(metadata_type, callback)
  local ctx = context()
  if not ctx or not begin_refresh(ctx) then
    return
  end
  local index = read_index(ctx)
  refresh_types(ctx, { metadata_type }, index, function(ok, updated)
    if callback then
      callback(ok, updated)
    end
  end)
end

local function browser_catalog_snapshot(ctx, index)
  return {
    context = ctx,
    descriptors = index.types or {},
    fetched_at = index.catalog_fetched_at,
    stale = is_stale(index.catalog_fetched_at),
    error = index.catalog_error,
  }
end

local function browser_operation(reference)
  if not reference then
    return "catalog"
  end
  return table.concat({ "children", reference.type or "", reference.folder or "" }, ":")
end

local function browser_operation_key(ctx, reference)
  return table.concat({ browser_context_id(ctx), browser_operation(reference) }, "\0")
end

function M.load_browser_catalog()
  local ctx = context()
  if not ctx then
    return nil
  end
  return browser_catalog_snapshot(ctx, read_index(ctx))
end

function M.is_browser_loading(reference)
  local ctx = context()
  return ctx ~= nil and browser_inflight[browser_operation_key(ctx, reference)] ~= nil
end

function M.refresh_browser_catalog(callback)
  local ctx = context()
  if not ctx then
    return nil
  end
  local token = generation
  local args = {
    "sf",
    "org",
    "list",
    "metadata-types",
    "--target-org",
    ctx.org,
    "--json",
  }
  with_api_version(args, ctx.api_version)

  return begin_browser_request(ctx, browser_operation(), callback, function(done)
    return process.run_sf_json(args, { cwd = ctx.root }, function(err, result)
      if not browser_context_is_current(ctx, token) then
        done(false, nil, "Target org or Salesforce project changed.")
        return
      end

      local index = read_index(ctx)
      if err or type(result) ~= "table" then
        index.catalog_error = err or "Invalid metadata type response."
        save_index(ctx, index)
        done(false, browser_catalog_snapshot(ctx, index), index.catalog_error)
        return
      end

      local descriptors = result.metadataObjects or result
      if type(descriptors) ~= "table" then
        index.catalog_error = "Metadata type response did not contain metadataObjects."
        save_index(ctx, index)
        done(false, browser_catalog_snapshot(ctx, index), index.catalog_error)
        return
      end

      index.types = descriptors
      index.catalog_fetched_at = os.time()
      index.catalog_error = nil
      atomic_write_json(ctx.paths.metadata_types, { metadataObjects = descriptors })
      save_index(ctx, index)
      done(true, browser_catalog_snapshot(ctx, index))
    end)
  end)
end

function M.ensure_browser_catalog(opts, callback)
  opts = opts or {}
  local snapshot = M.load_browser_catalog()
  if not snapshot then
    return nil
  end
  if not opts.force and #snapshot.descriptors > 0 and not snapshot.stale then
    if callback then
      callback(true, snapshot)
    end
    return nil
  end
  return M.refresh_browser_catalog(callback)
end

local function legacy_browser_slice(ctx, index, reference, descriptor)
  local members = read_json(ctx.paths.member(reference.type))
  if type(members) ~= "table" then
    return nil
  end

  local fetched = index.fetched[reference.type]
  local items = members
  local kind = "components"
  if descriptor and descriptor.inFolder == true then
    if reference.folder then
      local prefix = reference.folder .. "/"
      items = vim.tbl_filter(function(member)
        return member.fullName == reference.folder or vim.startswith(tostring(member.fullName or ""), prefix)
      end, members)
    else
      kind = "folders"
      items = {}
      local seen = {}
      for _, member in ipairs(members) do
        local folder = tostring(member.fullName or ""):match("^(.*)/[^/]+$")
        if folder and not seen[folder] then
          seen[folder] = true
          items[#items + 1] = {
            type = FOLDER_TYPES[reference.type] or (reference.type .. "Folder"),
            fullName = folder,
          }
        end
      end
    end
  end

  return {
    schema = BROWSER_SLICE_SCHEMA,
    org = ctx.org,
    kind = kind,
    type = reference.type,
    folder = reference.folder,
    fetched_at = fetched and fetched.at,
    items = items,
    stale = is_stale(fetched and fetched.at),
    legacy = true,
  }
end

function M.load_browser_children(reference)
  if type(reference) ~= "table" or not reference.type then
    return nil
  end
  local ctx = context()
  if not ctx then
    return nil
  end
  local index = read_index(ctx)
  local descriptor = metadata_descriptor(index, reference.type)
  if not descriptor then
    return {
      context = ctx,
      reference = vim.deepcopy(reference),
      kind = "components",
      items = {},
      stale = true,
      error = "Metadata type is not present in the current catalog.",
    }
  end

  local slice = read_browser_slice(ctx, reference, descriptor)
    or legacy_browser_slice(ctx, index, reference, descriptor)
  if not slice then
    slice = {
      kind = descriptor.inFolder == true and not reference.folder and "folders" or "components",
      items = {},
      stale = true,
    }
  end
  slice.context = ctx
  slice.reference = vim.deepcopy(reference)
  slice.descriptor = descriptor
  slice.error = index.browser_errors[browser_operation(reference)]
  return slice
end

function M.refresh_browser_children(reference, callback)
  if type(reference) ~= "table" or not reference.type then
    if callback then
      callback(false, nil, "Metadata type is required.")
    end
    return nil
  end

  local ctx = context()
  if not ctx then
    return nil
  end
  local token = generation
  local index = read_index(ctx)
  local descriptor = metadata_descriptor(index, reference.type)
  if not descriptor then
    if callback then
      callback(false, nil, "Metadata type is not present in the current catalog.")
    end
    return nil
  end

  local listed_type = reference.type
  if descriptor.inFolder == true and not reference.folder then
    listed_type = FOLDER_TYPES[reference.type] or (reference.type .. "Folder")
  end
  local args = list_metadata_args(ctx, listed_type, reference.folder)

  return begin_browser_request(ctx, browser_operation(reference), callback, function(done)
    return process.run_sf_json(args, { cwd = ctx.root }, function(err, result)
      if not browser_context_is_current(ctx, token) then
        done(false, nil, "Target org or Salesforce project changed.")
        return
      end

      local current_index = read_index(ctx)
      local operation = browser_operation(reference)
      if err or type(result) ~= "table" then
        current_index.browser_errors[operation] = err or "Invalid metadata member response."
        save_index(ctx, current_index)
        local previous = M.load_browser_children(reference)
        done(false, previous, current_index.browser_errors[operation])
        return
      end

      local slice, write_err = write_browser_slice(ctx, reference, descriptor, result)
      if not slice then
        current_index.browser_errors[operation] = write_err
        save_index(ctx, current_index)
        done(false, M.load_browser_children(reference), write_err)
        return
      end

      current_index.browser_errors[operation] = nil
      if descriptor.inFolder ~= true and not reference.folder then
        atomic_write_json(ctx.paths.member(reference.type), result)
        current_index.fetched[reference.type] = {
          at = slice.fetched_at,
          count = #result,
        }
      end
      save_index(ctx, current_index)
      slice.context = ctx
      slice.reference = vim.deepcopy(reference)
      slice.descriptor = descriptor
      done(true, slice)
    end)
  end)
end

function M.ensure_browser_children(reference, opts, callback)
  opts = opts or {}
  local slice = M.load_browser_children(reference)
  if not slice then
    return nil
  end
  if not opts.force and slice.fetched_at and not slice.stale then
    if callback then
      callback(true, slice)
    end
    return nil
  end
  return M.refresh_browser_children(reference, callback)
end

function M.refresh_browser_type_members(metadata_type, callback)
  callback = callback or function() end
  M.refresh_browser_children({ type = metadata_type }, function(ok, root_slice, err)
    if not ok or not root_slice then
      callback(false, root_slice and root_slice.items or {}, err)
      return
    end
    if root_slice.kind ~= "folders" then
      callback(true, root_slice.items)
      return
    end

    local members = {}
    local folders = root_slice.items
    local function refresh_folder(index_number)
      if index_number > #folders then
        local ctx = root_slice.context
        local index = read_index(ctx)
        atomic_write_json(ctx.paths.member(metadata_type), members)
        index.fetched[metadata_type] = {
          at = os.time(),
          count = #members,
        }
        index.errors[metadata_type] = nil
        save_index(ctx, index)
        callback(true, members)
        return
      end

      local folder = folders[index_number]
      M.refresh_browser_children({
        type = metadata_type,
        folder = folder.fullName,
      }, function(folder_ok, folder_slice, folder_err)
        if not folder_ok or not folder_slice then
          callback(false, members, string.format("%s: %s", folder.fullName or "?", folder_err or "refresh failed"))
          return
        end
        vim.list_extend(members, folder_slice.items)
        refresh_folder(index_number + 1)
      end)
    end
    refresh_folder(1)
  end)
end

function M.prompt_refresh()
  vim.ui.select({
    { id = "common", label = "Common metadata (configured types)" },
    { id = "all", label = "All enabled metadata (can take several minutes)" },
  }, {
    prompt = "Update Salesforce metadata inventory:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    if choice.id == "all" then
      M.refresh_all()
    else
      M.refresh_common()
    end
  end)
end

local function normalize_orgs(result)
  local list = {}
  for _, item in ipairs({ result.nonScratchOrgs or {}, result.scratchOrgs or {} }) do
    for _, org in ipairs(item) do
      local value = org.alias or org.username
      if value then
        list[#list + 1] = {
          value = value,
          username = org.username,
          org_id = org.orgId,
          instance_url = org.instanceUrl,
          connected_status = org.connectedStatus,
          is_default = org.isDefaultUsername == true,
          is_scratch = org.isScratch == true,
        }
      end
    end
  end
  table.sort(list, function(a, b)
    return a.value:lower() < b.value:lower()
  end)
  return list
end

local function fetch_orgs(callback)
  local root = project_root()
  if not root then
    return
  end
  run_json(
    { "sf", "org", "list", "--json", "--skip-connection-status" },
    { cwd = root },
    function(err, result)
      if err then
        notify("Org list failed: " .. err, vim.log.levels.ERROR)
        callback(err)
        return
      end
      orgs = normalize_orgs(result or {})
      orgs_root = root
      callback(nil, orgs, root)
    end
  )
end

local function sync_target(choice)
  sf_util().target_org = choice.value
  current_identity = {
    alias = choice.value,
    username = choice.username,
    org_id = choice.org_id,
    instance_url = choice.instance_url,
    connected_status = choice.connected_status,
  }
end

local function choose_org(prompt, callback)
  local root = project_root()
  if not root then
    return
  end

  local function present(items)
    vim.ui.select(items, {
      prompt = prompt,
      format_item = function(item)
        return (item.is_scratch and "[S] " or "") .. item.value
      end,
    }, function(choice)
      callback(choice, root)
    end)
  end

  if #orgs > 0 and orgs_root == root then
    present(orgs)
  else
    fetch_orgs(function(err, items)
      if not err then
        present(items)
      end
    end)
  end
end

local start_target_selection
start_target_selection = function(request)
  target_selection_running = true
  process.run_sf_json(request.args, { cwd = request.root }, function(err)
    local is_latest = request.token == target_selection_generation
    if is_latest and err then
      notify("Could not set target org: " .. err, vim.log.levels.ERROR)
    elseif is_latest then
      sync_target(request.choice)
      invalidate_browser_requests("Target org or Salesforce project changed.")
      notify(string.format("%s target org set: %s", request.global and "Global" or "Local", request.choice.value))
      if request.callback then
        request.callback(request.choice)
      end
      local local_actions = package.loaded["config.local_actions"]
      if local_actions then
        local_actions.refresh_all()
      end
    end

    target_selection_running = false
    local next_request = pending_target_selection
    pending_target_selection = nil
    if next_request then
      start_target_selection(next_request)
    end
  end)
end

local function set_org(choice, global, callback, selected_root)
  if not choice then
    return
  end
  local root = selected_root or project_root()
  if not root then
    return
  end

  local args = { "sf", "config", "set" }
  if global then
    args[#args + 1] = "--global"
  end
  vim.list_extend(args, { "target-org", choice.value, "--json" })

  target_selection_generation = target_selection_generation + 1
  local request = {
    args = args,
    callback = callback,
    choice = choice,
    global = global,
    root = root,
    token = target_selection_generation,
  }
  if target_selection_running then
    pending_target_selection = request
  else
    start_target_selection(request)
  end
end

function M.select_target(callback)
  choose_org("Local target org:", function(choice, root)
    set_org(choice, false, callback, root)
  end)
end

function M.select_global_target(callback)
  choose_org("Global target org:", function(choice, root)
    set_org(choice, true, callback, root)
  end)
end

function M.load_inventory()
  local ctx = context()
  if not ctx then
    return nil
  end
  local index = read_index(ctx)
  if not ctx.identity and index.identity then
    ctx.identity = index.identity
  end
  local inventory = {}

  for _, descriptor in ipairs(index.types or {}) do
    if descriptor.xmlName then
      inventory[descriptor.xmlName] = {
        descriptor = descriptor,
        members = read_json(ctx.paths.member(descriptor.xmlName)),
        fetched = index.fetched[descriptor.xmlName],
        error = index.errors[descriptor.xmlName],
      }
    end
  end

  return {
    context = ctx,
    index = index,
    types = inventory,
  }
end

local function unique_types(items)
  local seen = {}
  local types = {}
  for _, item in ipairs(items or {}) do
    if item.type and not seen[item.type] then
      seen[item.type] = true
      types[#types + 1] = item.type
    end
  end
  table.sort(types)
  return types
end

local function xml_escape(value)
  local escaped = tostring(value)
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
    :gsub('"', "&quot;")
    :gsub("'", "&apos;")
  return escaped
end

local function manifest_lines(items, api_version)
  local grouped = {}
  for _, item in ipairs(items or {}) do
    if item.type and item.fullName then
      grouped[item.type] = grouped[item.type] or {}
      grouped[item.type][#grouped[item.type] + 1] = item.fullName
    end
  end

  local lines = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<Package xmlns="http://soap.sforce.com/2006/04/metadata">',
  }
  local types = vim.tbl_keys(grouped)
  table.sort(types)
  for _, metadata_type in ipairs(types) do
    table.sort(grouped[metadata_type])
    lines[#lines + 1] = "  <types>"
    for _, member in ipairs(grouped[metadata_type]) do
      lines[#lines + 1] = "    <members>" .. xml_escape(member) .. "</members>"
    end
    lines[#lines + 1] = "    <name>" .. xml_escape(metadata_type) .. "</name>"
    lines[#lines + 1] = "  </types>"
  end
  lines[#lines + 1] = "  <version>" .. xml_escape(api_version) .. "</version>"
  lines[#lines + 1] = "</Package>"
  return lines
end

local function manifest_base_name(value)
  local name = vim.trim(tostring(value or ""))
  name = name:gsub("%.[xX][mM][lL]$", "")
  if name == "" then
    return nil, "Manifest filename cannot be empty."
  end
  if name:find("[/\\]") or name:find("..", 1, true) or name:find("[%c]") then
    return nil, "Use a filename only (no path separators, '..', or control characters)."
  end
  return name
end

function M.write_package_manifest(items, filename, opts)
  opts = opts or {}
  if not items or #items == 0 then
    return nil, "Select at least one metadata member."
  end

  local name, name_err = manifest_base_name(filename)
  if not name then
    return nil, name_err
  end

  local ctx = context()
  if not ctx then
    return nil, "Salesforce project/target org unavailable."
  end

  local timestamp = opts.timestamp or os.date("%Y%m%d_%H%M%S")
  local dir = vim.fs.joinpath(ctx.root, "manifest", "shard")
  local path = vim.fs.joinpath(dir, string.format("%s_%s.xml", name, timestamp))
  if (vim.uv or vim.loop).fs_stat(path) then
    return nil, "Manifest already exists: " .. path
  end

  local api_version = ctx.api_version or FALLBACK_API_VERSION
  local ok, write_err = atomic_write_lines(path, manifest_lines(items, api_version))
  if not ok then
    return nil, tostring(write_err)
  end
  return path
end

local function write_manifest_files(ctx, items)
  local api_version = ctx.api_version or FALLBACK_API_VERSION
  if not ctx.api_version then
    notify("sourceApiVersion missing; using manifest API " .. FALLBACK_API_VERSION, vim.log.levels.WARN)
  end

  local operation = string.format("%d-%s", os.time(), (vim.uv or vim.loop).hrtime())
  local dir = vim.fs.joinpath(ctx.paths.manifests, operation)
  vim.fn.mkdir(dir, "p")

  local package_path = vim.fs.joinpath(dir, "package.xml")
  local destructive_path = vim.fs.joinpath(dir, "destructiveChangesPost.xml")
  local empty_package = manifest_lines({}, api_version)
  local selected_package = manifest_lines(items, api_version)

  vim.fn.writefile(selected_package, package_path)
  vim.fn.writefile(empty_package, vim.fs.joinpath(dir, "empty-package.xml"))
  vim.fn.writefile(selected_package, destructive_path)

  return {
    dir = dir,
    api_version = api_version,
    selected_package = package_path,
    empty_package = vim.fs.joinpath(dir, "empty-package.xml"),
    destructive = destructive_path,
  }
end

local run_in_term = process.run_in_term

local function manifest_context()
  local ctx = context()
  if not ctx then
    return nil
  end
  return vim.fs.joinpath(ctx.root, "manifest"), ctx
end

local function validate_manifest_path(path)
  local dir, ctx = manifest_context()
  if not dir then
    return nil, nil, "Salesforce project/target org unavailable."
  end

  local real_dir = (vim.uv or vim.loop).fs_realpath(dir)
  local real_path = path and (vim.uv or vim.loop).fs_realpath(path) or nil
  if not real_dir or not real_path then
    return nil, ctx, "Manifest file does not exist."
  end
  if real_path:sub(-4):lower() ~= ".xml" then
    return nil, ctx, "Select an XML manifest."
  end

  local relative = vim.fs.relpath(real_dir, real_path)
  if not relative or relative == ".." or relative:match("^%.%.[/\\]") then
    return nil, ctx, "Manifest must be inside the project manifest/ directory."
  end
  return real_path, ctx
end

function M.manifest_dir()
  return manifest_context()
end

function M.retrieve_manifest(path, callback)
  local manifest, ctx, err = validate_manifest_path(path)
  if not manifest then
    notify(err, vim.log.levels.ERROR)
    return false
  end
  run_in_term({
    "sf",
    "project",
    "retrieve",
    "start",
    "--target-org",
    ctx.org,
    "--manifest",
    manifest,
  }, callback)
  return true
end

function M.deploy_manifest(path, callback)
  local manifest, ctx, err = validate_manifest_path(path)
  if not manifest then
    notify(err, vim.log.levels.ERROR)
    return false
  end
  run_in_term({
    "sf",
    "project",
    "deploy",
    "start",
    "--target-org",
    ctx.org,
    "--manifest",
    manifest,
  }, callback)
  return true
end

local function action_context(items)
  if not items or #items == 0 then
    notify("Select at least one metadata member.", vim.log.levels.WARN)
    return nil
  end
  local ctx = context()
  if not ctx then
    return nil
  end
  return ctx, write_manifest_files(ctx, items)
end

function M.retrieve(items, callback)
  local ctx, manifests = action_context(items)
  if not ctx then
    return
  end
  run_in_term({
    "sf",
    "project",
    "retrieve",
    "start",
    "--target-org",
    ctx.org,
    "--manifest",
    manifests.selected_package,
  }, callback)
end

local function retrieve_file_paths(ctx, result)
  local paths = {}
  local seen = {}
  local files = type(result) == "table" and result.files or nil
  files = type(files) == "table" and files or {}
  for _, file in ipairs(files) do
    local path = file.filePath or file.path
    if path and file.state ~= "Failed" then
      if vim.startswith(path, "\\") and not vim.startswith(path, "\\\\") then
        path = "/" .. path:sub(2)
      end
      path = vim.fs.normalize(path)
      local absolute = vim.startswith(path, "/") or path:match("^%a:[/\\]") ~= nil or vim.startswith(path, "\\\\")
      if not absolute then
        path = vim.fs.joinpath(ctx.root, path)
      end
      if not seen[path] then
        seen[path] = true
        paths[#paths + 1] = path
      end
    end
  end
  table.sort(paths)
  return paths
end

function M.retrieve_browser(items, opts, callback)
  opts = opts or {}
  if browser_retrieving then
    if callback then
      callback(false, nil, "Another Org Browser retrieve is already running.")
    end
    return nil
  end

  local ctx, manifests = action_context(items)
  if not ctx then
    if callback then
      callback(false, nil, "Salesforce project or target org is unavailable.")
    end
    return nil
  end

  local token = generation
  local args = {
    "sf",
    "project",
    "retrieve",
    "start",
    "--target-org",
    ctx.org,
    "--manifest",
    manifests.selected_package,
    "--json",
  }
  if opts.ignore_conflicts then
    args[#args + 1] = "--ignore-conflicts"
  end

  browser_retrieving = true
  browser_retrieve_callback = callback
  browser_retrieve_generation = browser_retrieve_generation + 1
  local retrieve_token = browser_retrieve_generation
  return process.run_sf_json(args, { cwd = ctx.root }, function(err, result)
    if retrieve_token ~= browser_retrieve_generation then
      return
    end
    if retrieve_token == browser_retrieve_generation and browser_retrieve_callback == callback then
      browser_retrieve_callback = nil
      browser_retrieving = false
    end
    if not browser_context_is_current(ctx, token) then
      if callback then
        callback(false, nil, "Target org or Salesforce project changed.")
      end
      return
    end
    if err then
      if callback then
        callback(false, nil, err)
      end
      return
    end

    local payload = {
      context = ctx,
      files = retrieve_file_paths(ctx, result),
      result = result,
    }
    if callback then
      callback(true, payload)
    end
  end)
end

function M.is_browser_retrieving()
  return browser_retrieving
end

function M.is_conflict_error(err)
  local message = tostring(err or ""):lower()
  return message:find("conflict", 1, true) ~= nil
    or message:find("overwrite", 1, true) ~= nil
    or message:find("local changes", 1, true) ~= nil
end

function M.deploy(items, callback)
  local ctx, manifests = action_context(items)
  if not ctx then
    return
  end
  run_in_term({
    "sf",
    "project",
    "deploy",
    "start",
    "--target-org",
    ctx.org,
    "--manifest",
    manifests.selected_package,
  }, callback)
end

function M.delete_dry_run(items, callback)
  local ctx, manifests = action_context(items)
  if not ctx then
    return
  end
  run_in_term({
    "sf",
    "project",
    "deploy",
    "start",
    "--target-org",
    ctx.org,
    "--manifest",
    manifests.empty_package,
    "--post-destructive-changes",
    manifests.destructive,
    "--dry-run",
  }, function(ok, exit_code)
    callback(ok, exit_code, ctx, manifests)
  end)
end

function M.delete_apply(ctx, manifests, callback)
  run_in_term({
    "sf",
    "project",
    "deploy",
    "start",
    "--target-org",
    ctx.org,
    "--manifest",
    manifests.empty_package,
    "--post-destructive-changes",
    manifests.destructive,
  }, callback)
end

function M.refresh_items(items, callback)
  local ctx = context()
  if not ctx or not begin_refresh(ctx) then
    return
  end
  refresh_types(ctx, unique_types(items), read_index(ctx), callback or function() end)
end

function M.get_context()
  return context()
end

function M.cancel_background()
  invalidate_browser_requests("Salesforce operation cancelled.")
  return process.cancel_background()
end

function M.is_refreshing()
  return refreshing
end

M._test = {
  atomic_write_lines = atomic_write_lines,
  atomic_write_json = atomic_write_json,
  cache_name = cache_name,
  is_stale = is_stale,
  manifest_base_name = manifest_base_name,
  manifest_lines = manifest_lines,
  normalize_orgs = normalize_orgs,
  retrieve_file_paths = retrieve_file_paths,
  safe_name = safe_name,
  set_org = set_org,
  shell_join = process.shell_join,
  validate_manifest_path = validate_manifest_path,
}

return M
