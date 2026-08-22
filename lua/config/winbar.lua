local M = {}

local winbar_expression = "%{%v:lua.require'config.winbar'.render()%}"
local navic_opts = {
  -- Preserve Catppuccin colors for each LSP symbol kind.
  highlight = true,
  -- highlight = false, -- render the whole symbol chain in WinBar text color
  -- Use the same compact separator as the reference.
  separator = " > ",
  -- separator = " › ", -- softer single-glyph alternate
  -- Keep deep symbol chains from consuming the whole row.
  depth_limit = 3,
  -- depth_limit = 0, -- show every parent symbol
  -- Recompute context only when Navic data changes.
  lazy_update_context = true,
  -- lazy_update_context = false, -- recompute on every winbar evaluation
}

local function supports_winbar(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.api.nvim_buf_is_loaded(bufnr)
    and vim.bo[bufnr].buftype == ""
    and vim.bo[bufnr].filetype ~= "neo-tree"
end

local function apply_highlights()
  local chrome = require("config.ui_chrome")
  vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinbarFileIcon", { fg = chrome.foam, bg = "NONE", bold = true })
  vim.api.nvim_set_hl(0, "WinbarFileName", { fg = chrome.text, bg = "NONE", bold = true })
  vim.api.nvim_set_hl(0, "WinbarFileNameNC", { fg = chrome.muted_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinbarModified", { fg = chrome.rose, bg = "NONE" })
  vim.api.nvim_set_hl(0, "NavicSeparator", { fg = chrome.rose, bg = "NONE" })
  vim.api.nvim_set_hl(0, "NavicText", { fg = chrome.text, bg = "NONE" })
end

local function apply_to_window(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  vim.wo[winid].winbar = supports_winbar(bufnr) and winbar_expression or ""
end

local function apply_to_buffer(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    apply_to_window(winid)
  end
end

local function apply_to_all_windows()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    apply_to_window(winid)
  end
end

local function attach(client, bufnr)
  local navic = require("nvim-navic")
  if client.server_capabilities.documentSymbolProvider and not navic.is_available(bufnr) then
    pcall(navic.attach, client, bufnr)
  end
end

local function escape_statusline(text)
  return text:gsub("%%", "%%%%")
end

function M.render()
  local winid = tonumber(vim.g.statusline_winid)
  if not winid or winid == 0 then
    winid = vim.api.nvim_get_current_win()
  end
  if not vim.api.nvim_win_is_valid(winid) then
    return ""
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  if not supports_winbar(bufnr) then
    return ""
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]"
  local icon = ""
  if vim.g.have_nerd_font then
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
      icon = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true }) or ""
    end
  end

  local focused = winid == vim.api.nvim_get_current_win()
  local name_group = focused and "WinbarFileName" or "WinbarFileNameNC"
  local result = " "
  if icon ~= "" then
    result = result .. "%#WinbarFileIcon#" .. icon .. "%* "
  end
  result = result .. "%#" .. name_group .. "#" .. escape_statusline(name) .. "%*"
  if vim.bo[bufnr].modified then
    result = result .. "%#WinbarModified# ●%*"
  end

  local navic = require("nvim-navic")
  if focused and navic.is_available(bufnr) then
    local location = navic.get_location(navic_opts, bufnr)
    if location ~= "" then
      result = result .. "%#NavicSeparator# > %*" .. location
    end
  end
  return result .. " "
end

function M.setup()
  local navic = require("nvim-navic")
  navic.setup(navic_opts)

  apply_highlights()
  local group = vim.api.nvim_create_augroup("native_context_winbar", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = apply_highlights,
  })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "TermOpen" }, {
    group = group,
    callback = function(event)
      apply_to_buffer(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("WinNew", {
    group = group,
    callback = function()
      vim.schedule(apply_to_all_windows)
    end,
  })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client then
        attach(client, event.buf)
      end
    end,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        attach(client, bufnr)
      end
    end
  end
  apply_to_all_windows()
end

return M
