--------------------------------------------------------------------------------
-- Autocommands — buffer lifecycle + light filetype aliases
-- Refs: CodeOSS lua/core/autocommands.lua; Kickstart TextYankPost;
--       VS Code files.trimTrailingWhitespace / insertFinalNewline / associations.
--------------------------------------------------------------------------------

local api = vim.api
local group = api.nvim_create_augroup("user_config", { clear = true })
-- local group = api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }) -- Kickstart-style name

-- Flash the yanked region briefly (visual feedback for y / yy / …).
api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ timeout = 180 }) -- CodeOSS timing
    -- vim.hl.on_yank() -- Kickstart default timeout
  end,
})

-- Dim listchars space/trail dots so they stay visible but quiet (Kickstart-ish list).
-- Whitespace = space/trail listchars; NonText often used for eol/extends.
local function apply_listchar_highlights()
  local chrome = require("config.ui_chrome")
  vim.api.nvim_set_hl(0, "Whitespace", { fg = chrome.highlight_med, nocombine = true })
  -- vim.api.nvim_set_hl(0, "Whitespace", { fg = chrome.highlight_low, nocombine = true }) -- dimmer dots
  -- vim.api.nvim_set_hl(0, "Whitespace", { fg = chrome.muted, nocombine = true }) -- stronger dots
  -- vim.api.nvim_set_hl(0, "Whitespace", { link = "Comment" }) -- follow theme comments
end
apply_listchar_highlights()
api.nvim_create_autocmd("ColorScheme", {
  group = group,
  desc = "Keep listchars space dots dim after colorscheme load",
  callback = apply_listchar_highlights,
})

-- If a file changed on disk (git checkout, formatter outside nvim), reload it.
api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  desc = "Reload files changed outside Neovim",
  command = "checktime",
  -- command = "checktime!", -- force reload even if buffer is modified (riskier)
})

-- Reopen a file at the last cursor line (Vim mark ").
api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Restore last cursor position",
  callback = function(event)
    local mark = api.nvim_buf_get_mark(event.buf, '"')
    local line_count = api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Trim trailing whitespace on save (VS Code files.trimTrailingWhitespace).
api.nvim_create_autocmd("BufWritePre", {
  group = group,
  desc = "Trim trailing whitespace",
  callback = function(event)
    local excluded = {
      diff = true,
      gitcommit = true,
      gitrebase = true,
      markdown = true, -- keep markdown hard breaks / two-space line breaks
      -- markdown = nil, -- uncomment intent: also trim markdown (delete the line above)
    }
    if excluded[vim.bo[event.buf].filetype] or not vim.bo[event.buf].modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! keepjumps keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Ensure a single final newline on save (VS Code insertFinalNewline / trimFinalNewlines).
-- Apex: OFF — matches CodeOSS [apex] files.insertFinalNewline = false (SF often trims EOL).
api.nvim_create_autocmd("BufWritePre", {
  group = group,
  desc = "Ensure final newline (skip Apex)",
  callback = function(event)
    if not vim.bo[event.buf].modifiable then
      return
    end
    local ft = vim.bo[event.buf].filetype
    local no_final_newline = {
      apex = true,
      apexcode = true, -- some servers use this ft name
    }
    if no_final_newline[ft] then
      vim.bo[event.buf].fixendofline = false
      vim.bo[event.buf].endofline = false
      return
    end
    -- Prefer Neovim’s built-in end-of-line fix when available.
    vim.bo[event.buf].fixendofline = true
    vim.bo[event.buf].endofline = true
  end,
})

-- When opening Apex, keep the “no forced final newline” buffer flags (same as [apex] in VS Code).
api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "apex", "apexcode" },
  desc = "Apex: do not force final newline on write",
  callback = function()
    vim.opt_local.fixendofline = false
    -- vim.opt_local.fixendofline = true -- match other filetypes if SF policy changes
  end,
})

-- Markdown: soft-wrap for prose (VS Code [markdown] wordWrap on). Code stays wrap=false in options.
api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "markdown", "markdown.mdx", "gitcommit" },
  desc = "Soft wrap for prose filetypes",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    -- vim.opt_local.wrap = false -- keep prose unwrapped like code
  end,
})

-- Light filetype aliases (VS Code files.associations + CodeOSS/Craftzdog filetype.add).
vim.filetype.add({
  extension = {
    cmp = "html", -- Salesforce Aura markup-ish
    gs = "javascript", -- Google Apps Script
    mdc = "markdown", -- Cursor rule files
    -- Apex (needed so final-newline skip + later LSP/treesitter apply):
    cls = "apex",
    trigger = "apex",
    apex = "apex",
    soql = "soql", -- standalone query drafts: treesitter + cached org completion
    -- sosl = "sosl", -- enable when a SOSL builder/completion source is added
  },
})
