--------------------------------------------------------------------------------
-- Core options — everyday editing defaults.
-- Refs: codeoss lua/core/options.lua; LazyVim / Craftzdog under config/options.
--------------------------------------------------------------------------------

local opt = vim.opt

-- --- UI / statusline ---

-- Hide "-- INSERT --" in the command line; lualine already shows the mode.
opt.showmode = false
-- opt.showmode = true -- also show mode in the cmdline (redundant with lualine)

-- How many statuslines to draw.
opt.laststatus = 3 -- one global statusline (best with lualine)
-- opt.laststatus = 2 -- one statusline per window (busier with splits)
-- opt.laststatus = 0 -- hide statusline entirely

-- Default frame for floating windows that do not choose their own border.
opt.winborder = "rounded" -- consistent soft boxes for diagnostics, menus, and prompts
-- opt.winborder = "single" -- square corners with the same one-cell outline
-- opt.winborder = "none" -- let floats blend into the editor background

-- Always reserve the gutter for signs (gitsigns, diagnostics) so text does not jump.
opt.signcolumn = "yes"
-- opt.signcolumn = "auto" -- only show the column when a sign is present
-- opt.signcolumn = "no" -- never reserve space (signs can shift text)

-- --- Line numbers ---

-- Absolute number on the current line.
opt.number = true
-- opt.number = false -- hide absolute line numbers

-- Other lines show distance from the cursor (so 8j / 5k are easy to count).
opt.relativenumber = true
-- opt.relativenumber = false -- absolute numbers on every line (Kickstart-ish)

-- --- Input / system ---

-- Mouse support (click, scroll, visual select).
opt.mouse = "a" -- all modes
-- opt.mouse = "" -- keyboard-only
-- opt.mouse = "nvi" -- normal/visual/insert only (no cmdline)

-- Sync y/p with the OS clipboard (Cmd/Ctrl+C/V). Deferred so clipboard
-- detection does not slow startup.
vim.schedule(function()
  opt.clipboard = "unnamedplus"
  -- opt.clipboard = "" -- keep Neovim registers separate from the OS clipboard
end)

-- --- Editing comfort ---

-- When a long line wraps, continuation lines keep the same indent as the start.
opt.breakindent = true
-- opt.breakindent = false -- wrapped continuation starts at column 0

-- Save undo history to disk so u / Ctrl-r survive quitting and reopening a file.
opt.undofile = true
-- opt.undofile = false -- undo only lasts for the current session

-- Highlight the line the cursor is on (easier to track in tall files).
opt.cursorline = true
-- opt.cursorline = false -- no current-line highlight

-- On :q / :bd with unsaved changes, ask to save instead of failing with an error.
opt.confirm = true
-- opt.confirm = false -- refuse the command until you :w or :q!

-- --- Search ---

-- / and ? ignore case by default (e.g. /foo matches Foo).
opt.ignorecase = true
-- opt.ignorecase = false -- always case-sensitive

-- If the pattern has any uppercase letter, search becomes case-sensitive
-- (e.g. /Foo matches Foo only). Needs ignorecase = true to matter.
opt.smartcase = true
-- opt.smartcase = false -- ignorecase alone controls case (no uppercase exception)

-- Matches stay highlighted after search. Clear with :nohlsearch.
opt.hlsearch = true -- Neovim default; kept explicit so you can flip it
-- opt.hlsearch = false -- clear highlights as soon as you move the cursor

-- --- Timing ---

-- Idle wait before CursorHold (gitsigns refresh, etc.). Default is 4000 ms.
opt.updatetime = 250 -- snappy for plugins that hook CursorHold
-- opt.updatetime = 4000 -- Neovim default (feels sluggish with modern plugins)

-- How long to wait for the next key in a mapped chord (e.g. <leader>…).
opt.timeoutlen = 300 -- faster which-key later; still usable for short chords
-- opt.timeoutlen = 500 -- more forgiving if you mistype leader sequences
-- opt.timeoutlen = 1000 -- very slow chords; rare unless you want maximum leeway

-- --- Splits / scroll ---

-- Where :vsplit places the new window.
opt.splitright = true -- open to the right
-- opt.splitright = false -- open to the left

-- Where :split places the new window.
opt.splitbelow = true -- open below
-- opt.splitbelow = false -- open above

-- Lines of context kept above/below the cursor when scrolling vertically.
opt.scrolloff = 8 -- balanced context vs usable height
-- opt.scrolloff = 10 -- Kickstart-ish: more context, less buffer space
-- opt.scrolloff = 0 -- cursor can sit on the first/last visible line

-- Same idea for horizontal scroll when wrap is off and lines are long.
opt.sidescrolloff = 8
-- opt.sidescrolloff = 0 -- cursor can sit on the leftmost/rightmost column

-- --- Indent ---
-- shiftwidth / tabstop / softtabstop work as a set — change them together.

-- Insert spaces when you press Tab (instead of a real tab character).
opt.expandtab = true
-- opt.expandtab = false -- insert real <Tab> characters

-- Size of an indent step for >>, <<, and autoindent.
opt.shiftwidth = 2 -- 2-space indent (common for Lua / JS / web)
-- opt.shiftwidth = 4 -- 4-space indent (common for Python / many codebases)

-- How wide a real <Tab> character displays when one is already in the file.
opt.tabstop = 2
-- opt.tabstop = 4 -- match 4-space indent if you switch the set above

-- How many spaces a Tab keypress inserts/deletes in insert mode.
opt.softtabstop = 2
-- opt.softtabstop = 4 -- match 4-space indent if you switch the set above

-- Rough C-like autoindent (new line after {, etc.). Language plugins may override.
opt.smartindent = true
-- opt.smartindent = false -- rely only on filetype / treesitter indent

-- --- Wrap / invisible characters ---

-- Soft-wrap long lines in the window (does not change the file).
opt.wrap = false -- scroll horizontally instead (typical for code)
-- opt.wrap = true -- wrap for prose / markdown

-- If wrap is on, break at word boundaries rather than mid-word.
opt.linebreak = true
-- opt.linebreak = false -- may break in the middle of a word when wrap is on

-- Show otherwise-invisible characters using listchars below.
opt.list = true
-- opt.list = false -- hide tabs / trailing spaces / nbsp / space markers

-- Glyphs used when list is on (Kickstart-style tab/trail/nbsp).
-- Plain-space dots are optional below; Whitespace stays dim in autocmds.lua.
opt.listchars = {
  tab = "» ", -- tabs (should be rare with expandtab)
  trail = "·", -- trailing spaces on a line
  nbsp = "␣", -- non-breaking space
  -- space = "·", -- show every ordinary space as a dim dot
  -- extends = "…", -- char when line continues past the window (wrap off)
  -- precedes = "…", -- char when line starts left of the window
  -- eol = "¬", -- end-of-line mark (noisy for code)
}
-- opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Kickstart: no per-space dots
-- opt.listchars = { tab = "> ", trail = "-", nbsp = "+", space = "." } -- ASCII-only fallback
-- opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", space = "⋅" } -- lighter middot variant

-- --- Command-line / completion UI (before a dedicated completion plugin) ---

-- Live preview while typing :s/…/…/.
opt.inccommand = "split" -- preview replacements in a split
-- opt.inccommand = "nosplit" -- preview only in-buffer (quieter on small screens)
-- opt.inccommand = "" -- no live substitute preview

-- Builtin completion popup behavior (omni / keyword complete, etc.).
-- menu = show popup; menuone = even for one match; noselect = you pick explicitly.
opt.completeopt = { "menu", "menuone", "noselect" }
-- opt.completeopt = { "menu", "menuone" } -- auto-select the first item

-- Max height of the completion popup.
opt.pumheight = 12
-- opt.pumheight = 0 -- unlimited (can cover the whole screen)
-- opt.pumheight = 8 -- shorter menu on small terminals

-- Smoother scrolling for wrapped lines / mouse wheel (Neovim 0.10+ only).
if vim.fn.has("nvim-0.10") == 1 then
  opt.smoothscroll = true
  -- opt.smoothscroll = false -- classic line-by-line scroll
end
