--------------------------------------------------------------------------------
-- 1. Entry point
-- Runs first. Keep this thin: leaders + require the real config modules.
--------------------------------------------------------------------------------

-- Faster Lua module loading (Neovim built-in; safe to keep).
vim.loader.enable()

-- Must be set BEFORE any plugin that creates <leader> maps.
vim.g.mapleader = " " -- Space (LazyVim / Craftzdog / CodeOSS default)
-- vim.g.mapleader = "," -- classic Vim leader
-- vim.g.mapleader = "\\" -- awkward on many keyboards; often used as localleader instead

-- Buffer-local leader; keeps local maps out of the Space namespace.
vim.g.maplocalleader = "\\" -- common pair with Space leader
-- vim.g.maplocalleader = " " -- same as leader (simpler, fewer namespaces)
-- vim.g.maplocalleader = "," -- classic localleader if Space is taken

-- Tell UI plugins whether Nerd Font glyphs are available.
vim.g.have_nerd_font = true -- terminal uses a Nerd Font
-- vim.g.have_nerd_font = false -- ASCII / plain icons only

-- Loads lua/config/options.lua
require("config.options")
-- Loads lua/config/lazy.lua (bootstraps the plugin manager)
require("config.lazy")
