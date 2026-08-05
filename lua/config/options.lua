--------------------------------------------------------------------------------
-- Core options (statusline slice only — expand later)
--------------------------------------------------------------------------------

local opt = vim.opt

-- Hide "-- INSERT --" in the cmdline; the statusline will show mode instead.
opt.showmode = false

-- 3 = one global statusline; 2 = one statusline per window.
opt.laststatus = 3

-- Always show the sign column so git signs don't shift text when they appear.
opt.signcolumn = "yes"
