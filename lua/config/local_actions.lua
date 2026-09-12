--------------------------------------------------------------------------------
-- Context-aware localleader actions — native provider registry + buffer maps.
--------------------------------------------------------------------------------

local M = {}

local api = vim.api
local project_context = require("config.project_context")
local providers = {}
local owned = {}
local pending_reconcile = {}
local setup_done = false
local OWNER_PREFIX = "Local: "
local MENU_LHS = "<localleader>p"
local SLOT_LHS = {
  run = "<localleader>r",
  build = "<localleader>b",
  test = "<localleader>t",
}
local SLOT_LABEL = {
  run = "Run",
  build = "Build",
  test = "Test",
}

local function expanded_lhs(lhs)
  return lhs:gsub("<localleader>", vim.g.maplocalleader or "\\")
end

local function eligible(bufnr)
  return api.nvim_buf_is_valid(bufnr)
    and api.nvim_buf_is_loaded(bufnr)
    and api.nvim_buf_get_name(bufnr) ~= ""
    and vim.bo[bufnr].buftype == ""
    and vim.bo[bufnr].filetype ~= "neo-tree"
end

local function buffer_context(bufnr)
  local name = api.nvim_buf_get_name(bufnr)
  return {
    bufnr = bufnr,
    buftype = vim.bo[bufnr].buftype,
    filetype = vim.bo[bufnr].filetype,
    name = name,
    path = name ~= "" and vim.fs.normalize(name) or nil,
    start_path = project_context.start_path(bufnr),
  }
end

local function sorted_providers()
  local list = vim.tbl_values(providers)
  table.sort(list, function(a, b)
    if a.priority == b.priority then
      return a.id < b.id
    end
    return a.priority > b.priority
  end)
  return list
end

local function normalize_action(provider, resolved, action, index)
  local id = action.id or action.label or tostring(index)
  local label = action.label or action.desc or id
  local lhs = action.lhs or SLOT_LHS[action.slot]
  local action_context = action.context or resolved.label or provider.label or provider.id
  local root = resolved.root and vim.fs.normalize(resolved.root) or ""
  return {
    id = id,
    key = table.concat({ provider.id, id, root, action_context }, "\0"),
    label = label,
    desc = action.desc or label,
    lhs = lhs,
    slot = action.slot,
    run = assert(action.run, string.format("Local action %s:%s has no run function", provider.id, id)),
    priority = action.priority or provider.priority,
    provider = provider.id,
    context = action_context,
    root = root ~= "" and root or nil,
  }
end

function M.collect(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not eligible(bufnr) then
    return {
      actions = {},
      context = nil,
      direct = {},
    }
  end

  local context = buffer_context(bufnr)
  local actions = {}
  local labels = {}
  local label_seen = {}
  local action_seen = {}

  for _, provider in ipairs(sorted_providers()) do
    local ok, resolved = pcall(provider.resolve, context)
    if not ok then
      vim.notify_once(
        string.format("Local action provider %s failed: %s", provider.id, resolved),
        vim.log.levels.ERROR,
        { title = "Local actions" }
      )
    elseif resolved and type(resolved.actions) == "table" and #resolved.actions > 0 then
      local label = resolved.label or provider.label or provider.id
      if not label_seen[label] then
        label_seen[label] = true
        labels[#labels + 1] = label
      end
      for index, action in ipairs(resolved.actions) do
        local normalized = normalize_action(provider, resolved, action, index)
        if not action_seen[normalized.key] then
          action_seen[normalized.key] = true
          actions[#actions + 1] = normalized
        end
      end
    end
  end

  table.sort(actions, function(a, b)
    if a.priority == b.priority then
      if a.context == b.context then
        return a.label < b.label
      end
      return a.context < b.context
    end
    return a.priority > b.priority
  end)

  local claims = {}
  for _, action in ipairs(actions) do
    if action.lhs then
      local lhs = expanded_lhs(action.lhs)
      claims[lhs] = claims[lhs] or {}
      claims[lhs][#claims[lhs] + 1] = action
    end
  end

  local direct = {}
  for lhs, candidates in pairs(claims) do
    local winning_priority = candidates[1].priority
    direct[lhs] = vim.tbl_filter(function(action)
      return action.priority == winning_priority
    end, candidates)
  end

  return {
    actions = actions,
    context = #labels > 0 and table.concat(labels, " + ") or nil,
    direct = direct,
  }
end

local function find_buffer_map(bufnr, lhs)
  for _, mapping in ipairs(api.nvim_buf_get_keymap(bufnr, "n")) do
    if mapping.lhs == lhs then
      return mapping
    end
  end
end

local function is_owned_mapping(mapping, item)
  return mapping and item and mapping.callback == item.callback
end

local function run_action(bufnr, selected)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end
  local fresh = M.collect(bufnr)
  local action = nil
  for _, candidate in ipairs(fresh.actions) do
    if candidate.key == selected.key then
      action = candidate
      break
    end
  end
  if not action then
    M.reconcile(bufnr)
    vim.notify("That local action is no longer available in this buffer.", vim.log.levels.WARN, {
      title = "Local actions",
    })
    return
  end
  local ok, err = pcall(action.run, {
    bufnr = bufnr,
    root = action.root,
  })
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Local actions" })
  end
end

local function select_action(bufnr, actions, prompt)
  if #actions == 0 then
    return
  elseif #actions == 1 then
    run_action(bufnr, actions[1])
    return
  end
  vim.ui.select(actions, {
    prompt = prompt,
    format_item = function(action)
      return string.format("[%s] %s", action.context, action.label)
    end,
  }, function(action)
    if action then
      run_action(bufnr, action)
    end
  end)
end

function M.invoke(bufnr, lhs)
  bufnr = bufnr or api.nvim_get_current_buf()
  local collected = M.collect(bufnr)
  local expanded = expanded_lhs(lhs)
  local actions = expanded == expanded_lhs(MENU_LHS) and collected.actions or collected.direct[expanded] or {}
  if #actions == 0 then
    M.reconcile(bufnr)
    return
  end
  select_action(bufnr, actions, string.format("%s actions:", collected.context or "Local"))
end

local function clear_owned(bufnr)
  for _, item in pairs(owned[bufnr] or {}) do
    local mapping = find_buffer_map(bufnr, item.expanded)
    if is_owned_mapping(mapping, item) then
      pcall(vim.keymap.del, "n", item.lhs, { buffer = bufnr })
    end
  end
  owned[bufnr] = nil
  if api.nvim_buf_is_valid(bufnr) then
    vim.b[bufnr].local_actions_context = nil
  end
end

function M.reconcile(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not eligible(bufnr) then
    if api.nvim_buf_is_valid(bufnr) then
      clear_owned(bufnr)
    end
    return
  end

  local collected = M.collect(bufnr)
  local desired = {}
  if #collected.actions > 0 then
    desired[expanded_lhs(MENU_LHS)] = {
      lhs = MENU_LHS,
      desc = OWNER_PREFIX .. (collected.context or "context") .. " actions",
    }
  end
  for expanded, actions in pairs(collected.direct) do
    local slot = actions[1] and actions[1].slot
    local desc = #actions == 1 and actions[1].desc or ((SLOT_LABEL[slot] or "Context") .. " actions")
    desired[expanded] = {
      lhs = actions[1].lhs,
      desc = OWNER_PREFIX .. desc,
    }
  end

  for expanded, item in pairs(owned[bufnr] or {}) do
    if not desired[expanded] then
      local mapping = find_buffer_map(bufnr, expanded)
      if is_owned_mapping(mapping, item) then
        pcall(vim.keymap.del, "n", item.lhs, { buffer = bufnr })
      end
    end
  end

  local next_owned = {}
  for expanded, item in pairs(desired) do
    local lhs = item.lhs
    local existing = find_buffer_map(bufnr, expanded)
    local current_owned = owned[bufnr] and owned[bufnr][expanded]
    if not existing or is_owned_mapping(existing, current_owned) then
      local callback = function()
        M.invoke(bufnr, lhs)
      end
      vim.keymap.set("n", lhs, callback, {
        buffer = bufnr,
        desc = item.desc,
        silent = true,
      })
      next_owned[expanded] = {
        expanded = expanded,
        lhs = lhs,
        callback = callback,
      }
    else
      vim.notify_once(
        string.format("Keeping existing buffer mapping for %s in %s.", expanded, api.nvim_buf_get_name(bufnr)),
        vim.log.levels.WARN,
        { title = "Local actions" }
      )
    end
  end
  owned[bufnr] = next_owned
  vim.b[bufnr].local_actions_context = collected.context
end

function M.refresh_all()
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) then
      M.reconcile(bufnr)
    end
  end
end

local function schedule_reconcile(bufnr)
  if pending_reconcile[bufnr] then
    return
  end
  pending_reconcile[bufnr] = true
  vim.schedule(function()
    pending_reconcile[bufnr] = nil
    M.reconcile(bufnr)
  end)
end

function M.register(provider)
  assert(type(provider) == "table" and type(provider.id) == "string", "Local action provider needs an id")
  assert(type(provider.resolve) == "function", "Local action provider needs resolve(context)")
  provider.priority = provider.priority or 0
  providers[provider.id] = provider
  if setup_done then
    vim.schedule(M.refresh_all)
  end
end

function M.unregister(id)
  providers[id] = nil
  if setup_done then
    vim.schedule(M.refresh_all)
  end
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true
  M.register(require("config.local_actions.project"))

  local group = api.nvim_create_augroup("contextual_local_actions", { clear = true })
  api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = group,
    callback = function(event)
      schedule_reconcile(event.buf)
    end,
  })
  api.nvim_create_autocmd({ "BufFilePost", "BufWritePost" }, {
    group = group,
    callback = function(event)
      project_context.invalidate()
      schedule_reconcile(event.buf)
    end,
  })
  api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      project_context.invalidate()
      vim.schedule(M.refresh_all)
    end,
  })
  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(event)
      owned[event.buf] = nil
      pending_reconcile[event.buf] = nil
    end,
  })
  vim.schedule(M.refresh_all)
end

M._test = {
  clear_owned = clear_owned,
  eligible = eligible,
  expanded_lhs = expanded_lhs,
  owned = owned,
  pending_reconcile = pending_reconcile,
  providers = providers,
}

return M
