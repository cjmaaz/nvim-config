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
    -- omit --filter for a full clone if you need complete history
    "--branch=stable", -- lazy's stable branch
    -- "--branch=main", -- bleeding edge (more breakage risk)
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
    -- { import = "plugins.lang" }, -- optional second import tree later
  },

  defaults = {
    -- Plugins load on events/keys unless a spec sets lazy = false.
    lazy = true, -- defer until needed (faster startup)
    -- lazy = false, -- load everything at startup (simpler debugging, slower open)

    -- Which plugin versions to track by default.
    version = false, -- latest git commits (good while learning / iterating)
    -- version = "*", -- newest semver release tag when the plugin publishes one
  },

  -- When you edit a plugin file, lazy can reload configs.
  change_detection = {
    notify = false, -- silent reload (less noise while tuning)
    -- notify = true, -- popup each time a plugin file changes
  },
})
