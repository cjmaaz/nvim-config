--------------------------------------------------------------------------------
-- Plugin manager: lazy.nvim
-- 1) Ensure lazy.nvim is installed under Neovim's data dir
-- 2) Put it on the runtime path
-- 3) Tell it which plugin specs to load from lua/plugins/
--------------------------------------------------------------------------------

-- Data dir is NOT your config repo. Example: ~/.local/share/nvim/lazy/lazy.nvim
-- (path varies by OS / NVIM_APPNAME)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- First launch only: clone lazy.nvim if missing.
if not vim.uv.fs_stat(lazypath) then
  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none", -- shallow-ish clone (less history to download)
    "--branch=stable", -- use lazy's stable branch, not random HEAD
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    error("Failed to bootstrap lazy.nvim:\n" .. output)
  end
end

-- So `require("lazy")` resolves to the cloned plugin.
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- What to install/configure.
  -- `{ import = "plugins" }` means: load every module under lua/plugins/
  -- (e.g. lua/plugins/init.lua, lua/plugins/statusline.lua, ...).
  spec = {
    { import = "plugins" },
  },

  defaults = {
    -- Plugins load on events/keys unless a spec sets lazy = false.
    lazy = true,
    -- false = track latest git commits of plugins (good while learning).
    -- "*" would pin to release tags when plugins publish them.
    version = false,
  },

  -- When you edit a plugin file, lazy can reload; skip the noisy popup.
  change_detection = {
    notify = false,
  },
})
