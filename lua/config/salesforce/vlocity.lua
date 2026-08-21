--------------------------------------------------------------------------------
-- Managed-package Vlocity DataPack retrieval via the npm Vlocity Build Tool.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local metadata = require("config.salesforce.metadata")
local process = require("config.salesforce.process")

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Vlocity retrieve" })
end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path, "b")
  if not ok or #lines == 0 then
    return nil
  end
  local decoded, value = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded and value or nil
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

local function executable(root)
  local local_cli = vim.fs.joinpath(root, "node_modules", ".bin", "vlocity")
  if vim.fn.executable(local_cli) == 1 then
    return local_cli
  end
  if vim.fn.executable("vlocity") == 1 then
    return "vlocity"
  end
end

local function node_supported()
  if vim.fn.executable("node") ~= 1 then
    return false, "Node.js is required by the Vlocity Build Tool."
  end
  local result = vim.system({ "node", "--version" }, { text = true }):wait(1500)
  local major = result and result.stdout and tonumber(result.stdout:match("v(%d+)")) or nil
  if not major or major < 18 then
    return false, "Vlocity Build requires Node.js 18 or newer."
  end
  return true
end

local function collect_jobs(root)
  local base = vim.fs.joinpath(root, "vlocity")
  if not uv.fs_stat(base) then
    return {}
  end

  local jobs = {}
  local function walk(path, depth)
    if depth > 3 then
      return
    end
    local handle = uv.fs_scandir(path)
    if not handle then
      return
    end
    while true do
      local name, kind = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      local child = vim.fs.joinpath(path, name)
      if kind == "directory" then
        walk(child, depth + 1)
      elseif name:lower():match("%.ya?ml$") then
        jobs[#jobs + 1] = child
      end
    end
  end
  walk(base, 0)
  table.sort(jobs, function(a, b)
    local a_default = vim.fs.basename(a):lower() == "exportomni.yaml"
    local b_default = vim.fs.basename(b):lower() == "exportomni.yaml"
    if a_default ~= b_default then
      return a_default
    end
    return a:lower() < b:lower()
  end)
  return jobs
end

local function local_keys(root)
  local base = vim.fs.joinpath(root, "vlocity")
  local keys = {}
  local type_handle = uv.fs_scandir(base)
  if not type_handle then
    return keys
  end

  while true do
    local data_type, type_kind = uv.fs_scandir_next(type_handle)
    if not data_type then
      break
    end
    if type_kind == "directory" and not data_type:match("^%.") then
      local item_handle = uv.fs_scandir(vim.fs.joinpath(base, data_type))
      if item_handle then
        while true do
          local item, item_kind = uv.fs_scandir_next(item_handle)
          if not item then
            break
          end
          if item_kind == "directory" then
            keys[#keys + 1] = {
              key = data_type .. "/" .. item,
              type = data_type,
              label = item,
              source = "local",
            }
          end
        end
      end
    end
  end
  table.sort(keys, function(a, b)
    return a.key:lower() < b.key:lower()
  end)
  return keys
end

local function sanitize_records(decoded)
  local records = decoded and (decoded.records or (decoded.result and decoded.result.records)) or {}
  local sanitized, seen = {}, {}
  for _, record in ipairs(type(records) == "table" and records or {}) do
    local key = record.VlocityDataPackKey or record.vlocityDataPackKey or record.key
    if type(key) == "string" and key ~= "" and not seen[key] then
      seen[key] = true
      sanitized[#sanitized + 1] = {
        key = key,
        type = record.VlocityDataPackType or record.vlocityDataPackType or key:match("^([^/]+)"),
        label = record.VlocityDataPackDisplayLabel or record.vlocityDataPackDisplayLabel or key,
        status = record.VlocityDataPackStatus or record.vlocityDataPackStatus,
        source = "remote",
      }
    end
  end
  table.sort(sanitized, function(a, b)
    return a.key:lower() < b.key:lower()
  end)
  return sanitized
end

local function cache_path(ctx)
  return vim.fs.joinpath(ctx.paths.browser, "vlocity-available.json")
end

local function cached_keys(ctx)
  local cached = read_json(cache_path(ctx))
  return type(cached) == "table" and type(cached.records) == "table" and cached.records or {}
end

local function validate_key(value)
  local key = vim.trim(tostring(value or ""))
  if
    key == ""
    or key:find("[%c]")
    or key:find("..", 1, true)
    or key:sub(1, 1) == "-"
    or not key:match("^[^/]+/.+$")
  then
    return nil, "Use a DataPack key in `Type/Key` form without control characters or `..`."
  end
  return key
end

local function choose_job(ctx, callback)
  local jobs = collect_jobs(ctx.root)
  if #jobs == 0 then
    notify("No Vlocity job YAML found below the project vlocity/ directory.", vim.log.levels.ERROR)
    return
  end
  if #jobs == 1 then
    callback(jobs[1])
    return
  end
  vim.ui.select(jobs, {
    prompt = "Vlocity job:",
    format_item = function(path)
      return vim.fs.relpath(ctx.root, path) or path
    end,
  }, callback)
end

local function refresh_available(ctx, cli, job, callback)
  notify("Refreshing available Vlocity DataPack keys…")
  process.run_json({
    cli,
    "-sfdx.username",
    ctx.org,
    "-job",
    job,
    "packGetAllAvailableExports",
    "--json",
  }, { cwd = ctx.root }, function(err, decoded)
    if err then
      notify("Could not list Vlocity DataPacks:\n" .. err, vim.log.levels.ERROR)
      if callback then
        callback(false)
      end
      return
    end
    if type(decoded.status) == "string" and decoded.status:lower() == "error" then
      notify("Vlocity reported an inventory error:\n" .. tostring(decoded.message or "Unknown error"), vim.log.levels.ERROR)
      if callback then
        callback(false)
      end
      return
    end
    local records = sanitize_records(decoded)
    if #records == 0 then
      notify("Vlocity returned no exportable DataPack keys.", vim.log.levels.WARN)
      if callback then
        callback(false)
      end
      return
    end
    local ok, write_error = atomic_write_json(cache_path(ctx), {
      schema = 1,
      updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      records = records,
    })
    if not ok then
      notify("Could not cache Vlocity inventory:\n" .. tostring(write_error), vim.log.levels.ERROR)
    else
      notify(string.format("Cached %d Vlocity DataPack keys.", #records))
    end
    if callback then
      callback(ok, records)
    end
  end)
end

local function build_log_has_errors(root)
  local path = vim.fs.joinpath(root, "VlocityBuildLog.yaml")
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return false
  end
  local text = table.concat(lines, "\n"):lower()
  return text:find("vlocitydatapackstatus:%s*error") ~= nil
    or text:find("status:%s*error") ~= nil
    or text:find("haserror:%s*true") ~= nil
end

local function export_args(ctx, cli, job, key)
  local args = {
    cli,
    "-sfdx.username",
    ctx.org,
    "-job",
    job,
    "packExport",
  }
  if key then
    vim.list_extend(args, { "-key", key })
  end
  return args
end

local function run_export(ctx, cli, job, key)
  local log_path = vim.fs.joinpath(ctx.root, "VlocityBuildLog.yaml")
  local before = uv.fs_stat(log_path)
  local before_mtime = before and before.mtime and before.mtime.sec or nil
  local args = export_args(ctx, cli, job, key)
  process.run_in_term(args, function(ok)
    local after = uv.fs_stat(log_path)
    local after_mtime = after and after.mtime and after.mtime.sec or nil
    local log_changed = after_mtime and (not before_mtime or after_mtime ~= before_mtime)
    if not ok or (log_changed and build_log_has_errors(ctx.root)) then
      notify("Vlocity export finished with errors; inspect SFTerm and VlocityBuildLog.yaml.", vim.log.levels.ERROR)
      return
    end
    notify(key and ("Retrieved " .. key) or "Configured Vlocity export completed.")
  end)
end

local function merged_keys(ctx)
  local by_key = {}
  for _, item in ipairs(local_keys(ctx.root)) do
    by_key[item.key] = item
  end
  for _, item in ipairs(cached_keys(ctx)) do
    by_key[item.key] = item
  end
  local items = vim.tbl_values(by_key)
  table.sort(items, function(a, b)
    return a.key:lower() < b.key:lower()
  end)
  return items
end

local function manual_key(callback)
  vim.ui.input({ prompt = "Vlocity DataPack key (Type/Key): " }, function(value)
    if value == nil then
      return
    end
    local key, err = validate_key(value)
    if not key then
      notify(err, vim.log.levels.ERROR)
      return
    end
    callback(key)
  end)
end

local function scoped_export(ctx, cli, job)
  local items = merged_keys(ctx)
  local choices = {
    { action = "manual", label = "Enter a DataPack key manually…" },
    { action = "refresh", label = "Refresh remote DataPack inventory…" },
  }
  vim.list_extend(choices, items)

  vim.ui.select(choices, {
    prompt = "Retrieve Vlocity DataPack:",
    format_item = function(item)
      if item.action then
        return item.label
      end
      return string.format("%s  [%s]", item.key, item.source or "cache")
    end,
  }, function(choice)
    if not choice then
      return
    end
    if choice.action == "manual" then
      manual_key(function(key)
        run_export(ctx, cli, job, key)
      end)
    elseif choice.action == "refresh" then
      refresh_available(ctx, cli, job, function(ok)
        if ok then
          scoped_export(ctx, cli, job)
        end
      end)
    else
      local key, err = validate_key(choice.key)
      if not key then
        notify(err, vim.log.levels.ERROR)
        return
      end
      run_export(ctx, cli, job, key)
    end
  end)
end

local function confirm_full_export(ctx, callback)
  process.run({ "git", "status", "--porcelain", "--", "vlocity" }, { cwd = ctx.root }, function(result)
    local dirty = result.code == 0 and vim.trim(result.stdout or "") ~= ""
    local warning = dirty
        and "Local vlocity/ changes exist. A full export can overwrite them."
      or "This exports every DataPack configured by the selected job."
    vim.ui.select({ "Export all configured DataPacks", "Cancel" }, {
      prompt = warning,
    }, function(choice)
      callback(choice == "Export all configured DataPacks")
    end)
  end)
end

function M.open()
  local ctx = metadata.get_context()
  if not ctx then
    return
  end
  local cli = executable(ctx.root)
  if not cli then
    notify("Install the npm Vlocity Build Tool: `npm install --global vlocity`.", vim.log.levels.ERROR)
    return
  end
  local supported, node_error = node_supported()
  if not supported then
    notify(node_error, vim.log.levels.ERROR)
    return
  end

  choose_job(ctx, function(job)
    if not job then
      return
    end
    vim.ui.select({
      { id = "scoped", label = "Retrieve one DataPack by key" },
      { id = "full", label = "Run the full configured export" },
      { id = "refresh", label = "Refresh remote DataPack key inventory" },
    }, {
      prompt = "Vlocity retrieval:",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        return
      end
      if choice.id == "scoped" then
        scoped_export(ctx, cli, job)
      elseif choice.id == "refresh" then
        refresh_available(ctx, cli, job)
      else
        confirm_full_export(ctx, function(confirmed)
          if confirmed then
            run_export(ctx, cli, job)
          end
        end)
      end
    end)
  end)
end

M._test = {
  build_log_has_errors = build_log_has_errors,
  collect_jobs = collect_jobs,
  executable = executable,
  export_args = export_args,
  local_keys = local_keys,
  sanitize_records = sanitize_records,
  validate_key = validate_key,
}

return M
