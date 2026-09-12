--------------------------------------------------------------------------------
-- Salesforce terminal — argv-only execution with the existing SFTerm UX.
--------------------------------------------------------------------------------

local M = {}

local api = vim.api
local state = {
  buf = nil,
  win = nil,
  job = nil,
  running = false,
  last_exit_code = nil,
}

local defaults = {
  ft = "SFTerm",
  blend = 10,
  border = "single",
  hl = "Normal",
  clear_env = false,
  dimensions = {
    height = 0.4,
    width = 0.8,
    x = 0.5,
    y = 0.9,
  },
}

local function config()
  local configured = vim.g.sf and vim.g.sf.term_config or {}
  return vim.tbl_deep_extend("force", vim.deepcopy(defaults), configured or {})
end

local function valid_win(win)
  return win and api.nvim_win_is_valid(win)
end

local function valid_buf(buf)
  return buf and api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf)
end

local function dimensions(opts)
  local width = math.max(20, math.ceil(vim.o.columns * opts.width))
  local height = math.max(3, math.ceil(vim.o.lines * opts.height - 4))
  return {
    width = math.min(width, math.max(1, vim.o.columns - 2)),
    height = math.min(height, math.max(1, vim.o.lines - 4)),
    col = math.max(0, math.ceil((vim.o.columns - width) * opts.x)),
    row = math.max(0, math.ceil((vim.o.lines - height) * opts.y - 1)),
  }
end

local function title(args)
  local pieces = {}
  for index = 1, math.min(#args, 3) do
    pieces[#pieces + 1] = tostring(args[index])
  end
  local value = "SFTerm" .. (#pieces > 0 and (": " .. table.concat(pieces, " ")) or "")
  if vim.fn.strdisplaywidth(value) > 60 then
    value = vim.fn.strcharpart(value, 0, 57) .. "…"
  end
  return value
end

local function open_window(buf, args)
  local cfg = config()
  local dim = dimensions(cfg.dimensions)
  local win = api.nvim_open_win(buf, false, {
    border = cfg.border,
    relative = "editor",
    style = "minimal",
    title = title(args or {}),
    title_pos = "center",
    width = dim.width,
    height = dim.height,
    col = dim.col,
    row = dim.row,
  })
  api.nvim_set_option_value("winhl", ("Normal:%s"):format(cfg.hl), { scope = "local", win = win })
  api.nvim_set_option_value("winblend", cfg.blend, { scope = "local", win = win })
  state.win = win
  return win
end

local function scroll_to_end()
  if not valid_buf(state.buf) then
    return
  end
  local line = math.max(1, api.nvim_buf_line_count(state.buf))
  for _, win in ipairs(vim.fn.win_findbuf(state.buf)) do
    if valid_win(win) then
      pcall(api.nvim_win_set_cursor, win, { line, 0 })
    end
  end
end

local function validate_argv(args)
  if type(args) ~= "table" or not vim.islist(args) or #args == 0 then
    return nil, "Salesforce commands must be a non-empty argv list."
  end
  local normalized = {}
  for index, value in ipairs(args) do
    if type(value) ~= "string" and type(value) ~= "number" then
      return nil, ("Salesforce argv item %d is not a string."):format(index)
    end
    value = tostring(value)
    if value:find("\0", 1, true) then
      return nil, ("Salesforce argv item %d contains NUL."):format(index)
    end
    normalized[index] = value
  end
  return normalized
end

function M.run(args, opts, callback)
  opts = opts or {}
  local argv, argv_error = validate_argv(args)
  if not argv then
    vim.notify(argv_error, vim.log.levels.ERROR, { title = "SFTerm" })
    return nil
  end
  if state.running then
    vim.notify("Wait for the current Salesforce task to finish.", vim.log.levels.WARN, { title = "SFTerm" })
    return nil
  end

  local running_buf = api.nvim_create_buf(false, true)
  vim.bo[running_buf].filetype = config().ft
  if valid_win(state.win) then
    api.nvim_win_set_buf(state.win, running_buf)
    pcall(
      api.nvim_win_set_config,
      state.win,
      vim.tbl_extend("force", api.nvim_win_get_config(state.win), {
        title = title(argv),
        title_pos = "center",
      })
    )
  else
    open_window(running_buf, argv)
  end
  state.buf = running_buf

  local cfg = config()
  local clear_env = opts.clear_env
  if clear_env == nil then
    clear_env = cfg.clear_env
  end
  local job
  local started, start_error = pcall(api.nvim_buf_call, running_buf, function()
    job = vim.fn.termopen(argv, {
      cwd = opts.cwd,
      env = opts.env or cfg.env,
      clear_env = clear_env,
      on_exit = function(_, exit_code)
        vim.schedule(function()
          state.running = false
          state.job = nil
          state.last_exit_code = exit_code
          scroll_to_end()
          if callback then
            callback(exit_code == 0, exit_code, running_buf)
          end
        end)
      end,
    })
  end)
  if not started or not job or job <= 0 then
    state.running = false
    state.job = nil
    local message = not started and tostring(start_error) or ("Could not start command (job %s)."):format(job)
    vim.notify(message, vim.log.levels.ERROR, { title = "SFTerm" })
    if callback then
      vim.schedule(function()
        callback(false, -1, running_buf)
      end)
    end
    return nil
  end

  state.job = job
  state.running = true
  vim.bo[running_buf].filetype = cfg.ft
  return job
end

function M.toggle()
  if valid_win(state.win) then
    api.nvim_win_close(state.win, false)
    state.win = nil
    return
  end
  if not valid_buf(state.buf) then
    vim.notify_once("No previous Salesforce task. Run an action first.", vim.log.levels.WARN, { title = "SFTerm" })
    return
  end
  open_window(state.buf, {})
  scroll_to_end()
end

function M.hide()
  if valid_win(state.win) then
    api.nvim_win_close(state.win, false)
    state.win = nil
    return true
  end
  return false
end

function M.cancel()
  if not state.running or not state.job then
    return 0
  end
  local ok = pcall(api.nvim_chan_send, state.job, "\003")
  return ok and 1 or 0
end

function M.is_running()
  return state.running
end

function M.current_buffer()
  return valid_buf(state.buf) and state.buf or nil
end

function M.get_last_exit_code()
  return state.last_exit_code
end

M._test = {
  state = state,
  validate_argv = validate_argv,
}

return M
