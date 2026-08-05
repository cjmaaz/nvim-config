--------------------------------------------------------------------------------
-- 1. Entry point
-- Runs first. Keep this thin: leaders + require the real config modules.
--------------------------------------------------------------------------------

-- Faster Lua module loading (Neovim built-in; safe to keep).
vim.loader.enable()

-- Must be set BEFORE any plugin that creates <leader> maps.
vim.g.mapleader = " "
-- Buffer-local leader; keeps local maps out of the Space namespace.
vim.g.maplocalleader = "\\"
-- Used later for icons; set false if the terminal font is not a Nerd Font.
vim.g.have_nerd_font = true

-- Loads lua/config/options.lua
require("config.options")
-- Loads lua/config/lazy.lua (bootstraps the plugin manager)
require("config.lazy")
