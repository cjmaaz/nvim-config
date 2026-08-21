--------------------------------------------------------------------------------
-- Org-scoped SObject schema cache for SOQL builder and completion.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local metadata = require("config.salesforce.metadata")
local process = require("config.salesforce.process")
local memory = {}
local CACHE_TTL_SECONDS = 24 * 60 * 60

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "SOQL schema" })
end

local function safe_name(value)
  return tostring(value or ""):gsub("[^A-Za-z0-9_.-]", "_")
end

local function cache_dir(ctx)
  return vim.fs.joinpath(ctx.paths.browser, "query-schema")
end

local function object_path(ctx)
  return vim.fs.joinpath(cache_dir(ctx), "objects.json")
end

local function describe_path(ctx, object_name)
  return vim.fs.joinpath(cache_dir(ctx), "describe", safe_name(object_name) .. ".json")
end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path, "b")
  if not ok or #lines == 0 then
    return nil
  end
  local decoded, value = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded and value or nil
end

local function cache_is_fresh(path)
  local stat = uv.fs_stat(path)
  local modified = stat and stat.mtime and stat.mtime.sec or nil
  return modified ~= nil and os.time() - modified <= CACHE_TTL_SECONDS
end

local function atomic_write_json(path, value)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local encoded_ok, encoded = pcall(vim.json.encode, value)
  if not encoded_ok then
    return false, encoded
  end
  local tmp = string.format("%s.tmp.%s", path, uv.hrtime())
  local write_ok, write_error = pcall(vim.fn.writefile, { encoded }, tmp, "b")
  if not write_ok then
    return false, write_error
  end
  local renamed, rename_error = uv.fs_rename(tmp, path)
  if not renamed then
    pcall(uv.fs_unlink, tmp)
    return false, rename_error
  end
  return true
end

local function context()
  return metadata.get_context()
end

function M.context_for_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local root = vim.b[bufnr].soql_root
  local org = vim.b[bufnr].soql_org
  local browser = vim.b[bufnr].soql_cache_browser
  if type(root) == "string" and type(org) == "string" and type(browser) == "string" then
    return {
      root = root,
      org = org,
      paths = { browser = browser },
    }
  end
  return context()
end

local function normalize_objects(result)
  local source = result
  if type(result) == "table" and type(result.sobjects) == "table" then
    source = result.sobjects
  elseif type(result) == "table" and type(result.objects) == "table" then
    source = result.objects
  end

  local objects, seen = {}, {}
  for _, item in ipairs(type(source) == "table" and source or {}) do
    local name = type(item) == "string" and item or item.name
    if type(name) == "string" and name ~= "" and not seen[name] then
      seen[name] = true
      objects[#objects + 1] = {
        name = name,
        label = type(item) == "table" and (item.label or name) or name,
        queryable = type(item) ~= "table" or item.queryable ~= false,
        custom = name:match("__c$") ~= nil,
      }
    end
  end
  table.sort(objects, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  return objects
end

local function normalize_describe(result)
  if type(result) ~= "table" or type(result.name) ~= "string" then
    return nil
  end
  local fields = {}
  for _, field in ipairs(type(result.fields) == "table" and result.fields or {}) do
    if type(field.name) == "string" then
      fields[#fields + 1] = {
        name = field.name,
        label = field.label,
        type = field.type,
        relationship_name = field.relationshipName,
        reference_to = type(field.referenceTo) == "table" and field.referenceTo or {},
        filterable = field.filterable ~= false,
        sortable = field.sortable ~= false,
        groupable = field.groupable == true,
        nillable = field.nillable == true,
        calculated = field.calculated == true,
      }
    end
  end
  table.sort(fields, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  return {
    schema = 1,
    name = result.name,
    label = result.label,
    queryable = result.queryable ~= false,
    fields = fields,
    updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
end

function M.get_context()
  return context()
end

function M.load_objects(ctx)
  ctx = ctx or context()
  if not ctx then
    return {}
  end
  local path = object_path(ctx)
  if memory[path] then
    return memory[path]
  end
  if not cache_is_fresh(path) then
    return {}
  end
  local cached = read_json(path)
  local objects = type(cached) == "table" and cached.objects or {}
  memory[path] = objects
  return objects
end

function M.load_describe(object_name, ctx)
  ctx = ctx or context()
  if not ctx or not object_name then
    return nil
  end
  local path = describe_path(ctx, object_name)
  if memory[path] then
    return memory[path]
  end
  if not cache_is_fresh(path) then
    return nil
  end
  local cached = read_json(path)
  if type(cached) == "table" and cached.name == object_name then
    memory[path] = cached
    return cached
  end
end

function M.refresh_objects(callback)
  local ctx = context()
  if not ctx then
    return
  end
  process.run_sf_json({
    "sf",
    "sobject",
    "list",
    "--sobject",
    "ALL",
    "--target-org",
    ctx.org,
    "--json",
  }, { cwd = ctx.root }, function(err, result)
    if err then
      notify("Could not list SObjects:\n" .. err, vim.log.levels.ERROR)
      if callback then
        callback(false, {})
      end
      return
    end
    local objects = normalize_objects(result)
    local payload = {
      schema = 1,
      updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      objects = objects,
    }
    local ok, write_error = atomic_write_json(object_path(ctx), payload)
    if not ok then
      notify("Could not cache SObjects:\n" .. tostring(write_error), vim.log.levels.ERROR)
    else
      memory[object_path(ctx)] = objects
      notify(string.format("Cached %d SObjects.", #objects))
    end
    if callback then
      callback(ok, objects, ctx)
    end
  end)
end

function M.refresh_describe(object_name, callback, ctx)
  ctx = ctx or context()
  if not ctx then
    return
  end
  process.run_sf_json({
    "sf",
    "sobject",
    "describe",
    "--sobject",
    object_name,
    "--target-org",
    ctx.org,
    "--json",
  }, { cwd = ctx.root }, function(err, result)
    if err then
      notify(string.format("Could not describe %s:\n%s", object_name, err), vim.log.levels.ERROR)
      if callback then
        callback(false)
      end
      return
    end
    local described = normalize_describe(result)
    if not described then
      notify("Unexpected SObject describe response for " .. object_name, vim.log.levels.ERROR)
      if callback then
        callback(false)
      end
      return
    end
    local path = describe_path(ctx, object_name)
    local ok, write_error = atomic_write_json(path, described)
    if not ok then
      notify("Could not cache describe data:\n" .. tostring(write_error), vim.log.levels.ERROR)
    else
      memory[path] = described
    end
    if callback then
      callback(ok, described, ctx)
    end
  end)
end

function M.ensure_objects(callback)
  local ctx = context()
  if not ctx then
    return
  end
  local objects = M.load_objects(ctx)
  if #objects > 0 then
    callback(objects, ctx)
  else
    M.refresh_objects(function(ok, refreshed)
      if ok then
        callback(refreshed, ctx)
      end
    end)
  end
end

function M.ensure_describe(object_name, callback, ctx)
  ctx = ctx or context()
  if not ctx then
    return
  end
  local described = M.load_describe(object_name, ctx)
  if described then
    callback(described, ctx)
  else
    M.refresh_describe(object_name, function(ok, refreshed)
      if ok then
        callback(refreshed, ctx)
      end
    end, ctx)
  end
end

function M.prefetch_relationships(described, ctx)
  if not described or not ctx then
    return
  end
  local targets, seen = {}, {}
  for _, field in ipairs(described.fields or {}) do
    if field.relationship_name then
      for _, target in ipairs(field.reference_to or {}) do
        if not seen[target] and not M.load_describe(target, ctx) then
          seen[target] = true
          targets[#targets + 1] = target
          if #targets >= 12 then
            break
          end
        end
      end
    end
    if #targets >= 12 then
      break
    end
  end

  local function next_target(index)
    local target = targets[index]
    if not target then
      return
    end
    M.refresh_describe(target, function()
      next_target(index + 1)
    end, ctx)
  end
  next_target(1)
end

function M.cache_dir(ctx)
  ctx = ctx or context()
  return ctx and cache_dir(ctx) or nil
end

M._test = {
  normalize_describe = normalize_describe,
  normalize_objects = normalize_objects,
  safe_name = safe_name,
}

return M
