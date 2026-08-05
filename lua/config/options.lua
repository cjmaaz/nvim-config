--------------------------------------------------------------------------------
-- Core options — everyday editing defaults.
-- Refs: codeoss lua/core/options.lua; LazyVim / Craftzdog under config/options.
--------------------------------------------------------------------------------

local opt = vim.opt

-- --- UI / statusline ---

-- Hide "-- INSERT --" in the command line; lualine already shows the mode.
opt.showmode = false

-- 3 = one statusline for the whole screen (works with laststatus + lualine).
-- 2 = a separate statusline in every window (busier with splits).
opt.laststatus = 3

-- Always reserve the gutter for signs (gitsigns, diagnostics).
-- "yes" avoids text jumping when a sign appears; "auto" only shows when needed.
opt.signcolumn = "yes"

-- --- Line numbers ---

-- Absolute number on the current line.
opt.number = true

-- Other lines show distance from the cursor (so 8j / 5k are easy to count).
-- Set false if you prefer absolute numbers on every line.
opt.relativenumber = true

-- --- Input / system ---

-- Enable the mouse in all modes (click, scroll, visual select).
-- Set to "" if you want keyboard-only.
opt.mouse = "a"

-- Sync the unnamedplus register with the OS clipboard (y/p ↔ Cmd/Ctrl+C/V).
-- Deferred until after UI start so clipboard detection does not slow boot.
-- Omit this block to keep Neovim registers separate from the system clipboard.
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

-- --- Editing comfort ---

-- When a long line wraps, continuation lines keep the same indent as the start.
opt.breakindent = true

-- Save undo history to disk so u / Ctrl-r survive quitting and reopening a file.
opt.undofile = true

-- Highlight the line the cursor is on (easier to track in tall files).
opt.cursorline = true

-- On :q / :bd with unsaved changes, ask to save instead of failing with an error.
opt.confirm = true

-- --- Search ---

-- / and ? ignore case by default (e.g. /foo matches Foo).
opt.ignorecase = true

-- If the pattern contains any uppercase letter, search becomes case-sensitive
-- (e.g. /Foo matches Foo only). Needs ignorecase = true to matter.
opt.smartcase = true

-- Matches stay highlighted after search (Neovim default). Clear with :nohlsearch.
-- opt.hlsearch = true

-- --- Timing ---

-- How long Neovim waits idle before firing CursorHold (gitsigns refresh, etc.).
-- Default is 4000 ms; 250 feels snappier for plugins that hook that event.
opt.updatetime = 250

-- How long to wait for the next key in a mapped chord (e.g. <leader>…).
-- Lower = faster which-key popup later; raise (500–1000) if you mistype chords.
opt.timeoutlen = 300

-- --- Splits / scroll ---

-- Vertical :vsplit opens to the right of the current window.
opt.splitright = true

-- Horizontal :split opens below the current window.
opt.splitbelow = true

-- Keep this many lines above/below the cursor when scrolling vertically.
-- Higher (e.g. 10) shows more context but wastes vertical space.
opt.scrolloff = 8

-- Same idea for horizontal scroll when wrap is off and lines are long.
opt.sidescrolloff = 8

-- --- Indent ---
-- These four work as a set: change all together if you prefer 4-space indent.

-- Insert spaces when you press Tab (instead of a real tab character).
opt.expandtab = true

-- Size of an indent step for >>, <<, and autoindent (spaces when expandtab).
opt.shiftwidth = 2

-- How wide a real <Tab> character displays when one is already in the file.
opt.tabstop = 2

-- How many spaces a Tab keypress inserts/deletes in insert mode.
opt.softtabstop = 2

-- Rough C-like autoindent (new line after {, etc.). Language plugins may override.
opt.smartindent = true

-- Prefer 4 spaces instead? Uncomment and set the three widths above to 4.
-- opt.shiftwidth = 4
-- opt.tabstop = 4
-- opt.softtabstop = 4

-- --- Wrap / invisible characters ---

-- Do not soft-wrap long lines (scroll horizontally instead). Set true for prose.
opt.wrap = false

-- If wrap is on, break at word boundaries rather than mid-word.
opt.linebreak = true

-- Show otherwise-invisible characters using listchars below.
opt.list = true

-- What those invisibles look like: tabs, trailing spaces, non-breaking spaces.
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- --- Command-line / completion UI (before a dedicated completion plugin) ---

-- While typing :s/…/…/, show a live preview of replacements in a split.
-- Use "nosplit" to preview only in-buffer (quieter on small screens).
opt.inccommand = "split"

-- Builtin completion popup behavior (omni / keyword complete, etc.):
--   menu     = show the popup
--   menuone  = show even for a single match
--   noselect = do not auto-select the first item (you choose explicitly)
opt.completeopt = { "menu", "menuone", "noselect" }

-- Cap how tall the completion popup can grow.
opt.pumheight = 12

-- Smoother scrolling for wrapped lines / mouse wheel (Neovim 0.10+ only).
if vim.fn.has("nvim-0.10") == 1 then
  opt.smoothscroll = true
end
