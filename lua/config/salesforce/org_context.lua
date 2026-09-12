--------------------------------------------------------------------------------
-- Salesforce target-org state — isolated by canonical project root.
--------------------------------------------------------------------------------

local M = {}

local api = vim.api
local uv = vim.uv or vim.loop
local process = require("config.salesforce.process")
local contexts = {}
local generations = {}
local inflight = {}

local function canonical_root(root)
  if type(root) ~= "string" or root == "" then
    return nil
  end
  root = vim.fs.normalize(root)
  return vim.fs.normalize(uv.fs_realpath(root) or root)
end

local function valid_org(org)
  if type(org) ~= "string" then
    return nil
  end
  org = vim.trim(org)
  if
    org == ""
    or #org > 512
    or org == "."
    or org == ".."
    or org:sub(1, 1) == "-"
    or org:find("[/\\]")
    or org:find("[%z\1-\31\127]")
  then
    return nil
  end
  return org
end

local function root_for_buffer(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local tagged = api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].sf_project_root or nil
  if type(tagged) == "string" and tagged ~= "" then
    return canonical_root(tagged)
  end
  return canonical_root(require("config.project_context").salesforce_root(bufnr))
end

local function next_generation(root)
  generations[root] = (generations[root] or 0) + 1
  return generations[root]
end

local function identity_from(choice)
  choice = choice or {}
  return {
    alias = choice.alias or choice.value,
    username = choice.username,
    org_id = choice.org_id or choice.orgId,
    instance_url = choice.instance_url or choice.instanceUrl,
    connected_status = choice.connected_status or choice.connectedStatus,
  }
end

local function store(root, org, source, identity)
  root = canonical_root(root)
  org = valid_org(org)
  if not root or not org then
    return nil
  end
  local ctx = {
    root = root,
    org = org,
    source = source or "unknown",
    identity = identity or {},
    revision = next_generation(root),
  }
  contexts[root] = ctx
  return ctx
end

local function parse_config(result)
  local entry = type(result) == "table" and (result[1] or result) or nil
  if type(entry) ~= "table" or entry.success == false then
    return nil, entry and (entry.message or entry.error) or "No Salesforce target org is configured."
  end
  local org = valid_org(entry.value)
  if not org then
    return nil, "No valid Salesforce target org is configured."
  end
  return org, tostring(entry.location or "unknown"):lower()
end

function M.current(root)
  return contexts[canonical_root(root)]
end

function M.for_buffer(bufnr)
  local root = root_for_buffer(bufnr)
  return root and contexts[root] or nil
end

function M.resolve(root, callback, opts)
  opts = opts or {}
  callback = callback or function() end
  root = canonical_root(root)
  if not root then
    vim.schedule(function()
      callback(nil, "Open this from a Salesforce project first.")
    end)
    return nil
  end
  if contexts[root] and not opts.force then
    vim.schedule(function()
      callback(contexts[root])
    end)
    return contexts[root]
  end
  if inflight[root] then
    inflight[root].callbacks[#inflight[root].callbacks + 1] = callback
    return inflight[root].handle
  end

  local request_generation = next_generation(root)
  local request = { callbacks = { callback }, generation = request_generation }
  inflight[root] = request
  request.handle = process.run_sf_json(
    { "sf", "config", "get", "target-org", "--json" },
    { cwd = root },
    function(err, result)
      local callbacks = request.callbacks
      if inflight[root] == request then
        inflight[root] = nil
      end
      local ctx
      if not err and generations[root] == request_generation then
        local org, source_or_error = parse_config(result)
        if org then
          ctx = store(root, org, source_or_error)
        else
          err = source_or_error
        end
      elseif not err then
        err = "Salesforce project context changed while resolving its target org."
      end
      for _, cb in ipairs(callbacks) do
        vim.schedule(function()
          cb(ctx, err)
        end)
      end
    end
  )
  return request.handle
end

function M.capture(bufnr, callback, opts)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) or not api.nvim_buf_is_loaded(bufnr) then
    callback(nil, "The originating buffer is no longer available.")
    return nil
  end
  local root = root_for_buffer(bufnr)
  local path = api.nvim_buf_get_name(bufnr)
  local win
  for _, candidate in ipairs(vim.fn.win_findbuf(bufnr)) do
    if api.nvim_win_is_valid(candidate) then
      win = candidate
      break
    end
  end
  return M.resolve(root, function(ctx, err)
    if not ctx then
      callback(nil, err)
      return
    end
    callback({
      bufnr = bufnr,
      win = win,
      path = path ~= "" and vim.fs.normalize(path) or nil,
      root = ctx.root,
      org = ctx.org,
      source = ctx.source,
      identity = ctx.identity,
      revision = ctx.revision,
    })
  end, opts)
end

function M.is_current(ctx)
  if type(ctx) ~= "table" then
    return false
  end
  local current = contexts[canonical_root(ctx.root)]
  return current ~= nil and current.revision == ctx.revision and current.org == ctx.org
end

function M.seed(root, choice, source)
  local org = type(choice) == "table" and (choice.value or choice.alias or choice.username) or choice
  return store(root, org, source, type(choice) == "table" and identity_from(choice) or nil)
end

function M.invalidate(root)
  if root then
    root = canonical_root(root)
    if root then
      contexts[root] = nil
      next_generation(root)
    end
    return
  end
  for key in pairs(contexts) do
    contexts[key] = nil
    next_generation(key)
  end
end

function M.activate(ctx, callback)
  if not M.is_current(ctx) then
    return nil, "Salesforce project context is stale."
  end
  local ok, util = pcall(require, "sf.util")
  if not ok then
    return callback()
  end
  local previous = util.target_org
  util.target_org = ctx.org
  local results = table.pack(pcall(callback))
  util.target_org = previous
  if not results[1] then
    error(results[2])
  end
  return unpack(results, 2, results.n)
end

M._test = {
  canonical_root = canonical_root,
  contexts = contexts,
  parse_config = parse_config,
  root_for_buffer = root_for_buffer,
  valid_org = valid_org,
}

return M
