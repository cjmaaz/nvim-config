--------------------------------------------------------------------------------
---                      1. Init - Starting Point                            ---
--------------------------------------------------------------------------------

  -- Replace Neovim's normal Lua module-loading path with faster one.
  -- overrides `loadfile()`
  vim.loader.enable()


  -- <" " (Space)> is your leader for future maps (<leader>...). 
  vim.g.mapleader = " "


  -- Separate leader for buffer-local maps it doesn't fight <leader> (<Space>).
  vim.g.maplocalleader = "\\"


  -- Flag to use nerd font, if nerd font not available make it false.
  vim.g.have_nerd_font = true


  -- Loads lua/config/options.lua
  require("config.options")

  -- Loads lua/config/lazy.lua (plugin manager)
  require("config.lazy")

