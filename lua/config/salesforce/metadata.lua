--------------------------------------------------------------------------------
-- Salesforce metadata inventory — callback-safe org flow + project sf_cache
-- Reuses sf.nvim's legacy <Type>_<org>.json files so SM/Sm and this browser agree.
-- Browser-only indexes/manifests live below sf_cache/metadata-browser/.
--------------------------------------------------------------------------------

local M = {}

local SCHEMA_VERSION = 1
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

local active_processes = {}
local next_process_id = 0
local generation = 0
local refreshing = false
local orgs = {}
local orgs_root
local current_identity

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

local function project_root()
  local ok, root = pcall(sf_util().get_sf_root)
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
  local cache = vim.fs.normalize(sf_util().get_plugin_folder_path())
  local browser = vim.fs.joinpath(cache, "metadata-browser", safe_name(org))
  return {
    root = cache,
    browser = browser,
    index = vim.fs.joinpath(browser, "index.json"),
    metadata_types = vim.fs.joinpath(cache, "metadata-types.json"),
    member = function(metadata_type)
      return vim.fs.joinpath(cache, string.format("%s_%s.json", safe_name(metadata_type), safe_name(org)))
    end,
    manifests = vim.fs.joinpath(browser, "manifests"),
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

local function error_message(decoded, obj)
  if type(decoded) == "table" then
    return decoded.message
      or decoded.name
      or (type(decoded.result) == "table" and decoded.result.message)
  end
  local stderr = obj and obj.stderr or nil
  return stderr and stderr:gsub("%s+$", "") or "Unknown Salesforce CLI error"
end

local function run_json(args, opts, callback)
  opts = opts or {}
  next_process_id = next_process_id + 1
  local process_id = next_process_id
  local token = opts.generation or generation

  local handle
  local function on_exit(obj)
    vim.schedule(function()
      active_processes[process_id] = nil
      if token ~= generation then
        return
      end

      local decoded_ok, decoded = pcall(vim.json.decode, obj.stdout or "")
      if obj.code ~= 0 or not decoded_ok or type(decoded) ~= "table" or decoded.status ~= 0 then
        callback(error_message(decoded_ok and decoded or nil, obj), nil, obj)
        return
      end
      callback(nil, decoded.result, obj)
    end)
  end

  local started, process_or_error = pcall(vim.system, args, {
    cwd = opts.cwd,
    text = true,
  }, on_exit)
  if not started then
    vim.schedule(function()
      callback(tostring(process_or_error))
    end)
    return nil
  end
  handle = process_or_error

  active_processes[process_id] = handle
  return handle
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
      types = {},
      fetched = {},
      errors = {},
    }
  end
  index.types = index.types or {}
  index.fetched = index.fetched or {}
  index.errors = index.errors or {}
  index.org = ctx.org
  index.api_version = ctx.api_version
  if ctx.identity then
    index.identity = ctx.identity
  end

  -- Hydrate an index from sf.nvim's legacy cache so existing SM/SK data is usable.
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

local function descriptor_map(index)
  local result = {}
  for _, descriptor in ipairs(index.types or {}) do
    if descriptor.xmlName then
      result[descriptor.xmlName] = descriptor
    end
  end
  return result
end

local function list_metadata(ctx, metadata_type, folder, callback)
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
  run_json(with_api_version(args, ctx.api_version), { cwd = ctx.root }, callback)
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

function M.fetch_orgs_and_refresh_common()
  fetch_orgs(function(err, items)
    if err then
      return
    end

    local choice
    for _, item in ipairs(items) do
      if item.is_default then
        choice = item
        break
      end
    end
    if not choice and sf_util().target_org ~= "" then
      for _, item in ipairs(items) do
        if item.value == sf_util().target_org or item.username == sf_util().target_org then
          choice = item
          break
        end
      end
    end

    if not choice then
      notify("Org list refreshed, but no default target org is configured.", vim.log.levels.WARN)
      return
    end
    sync_target(choice)
    M.refresh_common()
  end)
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
    }, callback)
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

local function set_org(choice, global, callback)
  if not choice then
    return
  end
  local root = project_root()
  if not root then
    return
  end

  local args = { "sf", "config", "set" }
  if global then
    args[#args + 1] = "--global"
  end
  vim.list_extend(args, { "target-org", choice.value, "--json" })

  run_json(args, { cwd = root }, function(err)
    if err then
      notify("Could not set target org: " .. err, vim.log.levels.ERROR)
      return
    end
    sync_target(choice)
    notify(string.format("%s target org set: %s", global and "Global" or "Local", choice.value))
    if callback then
      callback(choice)
    end
  end)
end

function M.select_target_and_refresh_common()
  choose_org("Local target org:", function(choice)
    set_org(choice, false, function()
      M.refresh_common()
    end)
  end)
end

function M.select_global_target()
  choose_org("Global target org:", function(choice)
    set_org(choice, true)
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

local function shell_join(args)
  local escaped = {}
  for _, arg in ipairs(args) do
    escaped[#escaped + 1] = vim.fn.shellescape(arg)
  end
  return table.concat(escaped, " ")
end

local function run_in_term(args, callback)
  require("sf").run(shell_join(args), function(_, _, exit_code)
    if callback then
      vim.schedule(function()
        callback(exit_code == 0, exit_code)
      end)
    end
  end)
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
  local count = 0
  generation = generation + 1
  for id, handle in pairs(active_processes) do
    count = count + 1
    pcall(handle.kill, handle, 15)
    active_processes[id] = nil
  end
  refreshing = false
  return count
end

function M.is_refreshing()
  return refreshing
end

M._test = {
  atomic_write_json = atomic_write_json,
  manifest_lines = manifest_lines,
  normalize_orgs = normalize_orgs,
  safe_name = safe_name,
  shell_join = shell_join,
}

return M
