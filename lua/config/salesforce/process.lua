--------------------------------------------------------------------------------
-- Shared Salesforce process helpers — safe argv, JSON jobs, SFTerm, cancellation.
--------------------------------------------------------------------------------

local M = {}

local active = {}
local cancelled = {}
local next_id = 0

local function error_message(decoded, result)
  if result and result.cancelled then
    return "Salesforce operation cancelled."
  end
  if type(decoded) == "table" then
    return decoded.message
      or decoded.name
      or (type(decoded.result) == "table" and decoded.result.message)
  end
  local stderr = result and result.stderr or nil
  return stderr and stderr:gsub("%s+$", "") or "Unknown command error"
end

-- Display only. Never pass this formatted value to a process API.
function M.format_argv(args)
  local escaped = {}
  for _, arg in ipairs(args) do
    escaped[#escaped + 1] = vim.fn.shellescape(tostring(arg))
  end
  return table.concat(escaped, " ")
end

function M.run(args, opts, callback)
  opts = opts or {}
  callback = callback or function() end
  next_id = next_id + 1
  local id = next_id

  local started, handle_or_error = pcall(vim.system, args, {
    cwd = opts.cwd,
    env = opts.env,
    text = true,
  }, function(result)
    vim.schedule(function()
      active[id] = nil
      if cancelled[id] then
        cancelled[id] = nil
        result.cancelled = true
      end
      callback(result)
    end)
  end)
  if not started then
    vim.schedule(function()
      callback({ code = -1, stdout = "", stderr = tostring(handle_or_error) })
    end)
    return nil
  end

  active[id] = handle_or_error
  return handle_or_error
end

function M.run_json(args, opts, callback)
  return M.run(args, opts, function(result)
    if result.cancelled then
      callback("Salesforce operation cancelled.", nil, result)
      return
    end
    local ok, decoded = pcall(vim.json.decode, result.stdout or "")
    if result.code ~= 0 or not ok or type(decoded) ~= "table" then
      callback(error_message(ok and decoded or nil, result), nil, result)
      return
    end
    callback(nil, decoded, result)
  end)
end

function M.run_sf_json(args, opts, callback)
  return M.run_json(args, opts, function(err, decoded, result)
    if err then
      callback(err, nil, result)
      return
    end
    if decoded.status ~= 0 then
      callback(error_message(decoded, result), nil, result)
      return
    end
    callback(nil, decoded.result, result)
  end)
end

function M.run_in_term(args, opts, callback)
  if type(opts) == "function" then
    callback = opts
    opts = nil
  end
  return require("config.salesforce.terminal").run(args, opts, callback)
end

function M.cancel_background()
  local count = 0
  for id, handle in pairs(active) do
    active[id] = nil
    cancelled[id] = true
    if handle then
      local ok = pcall(handle.kill, handle, "sigint")
      if not ok then
        pcall(handle.kill, handle, 2)
      end
      count = count + 1
    end
  end
  return count
end

function M.is_running()
  return next(active) ~= nil
end

M._test = {
  error_message = error_message,
}

return M
