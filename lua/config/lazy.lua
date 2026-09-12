--------------------------------------------------------------------------------
-- Plugin manager: lazy.nvim
-- 1) Ensure lazy.nvim is installed under Neovim's data dir
-- 2) Put it on the runtime path
-- 3) Tell it which plugin specs to load from lua/plugins/
--------------------------------------------------------------------------------

-- Data dir is NOT your config repo. Example: ~/.local/share/nvim/lazy/lazy.nvim
-- (path varies by OS / NVIM_APPNAME)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local fallback_commit = "306a05526ada86a7b30af95c5cc81ffba93fef97"

local source = debug.getinfo(1, "S").source:gsub("^@", "")
if source:sub(1, 1) ~= "/" and not source:match("^%a:[/\\]") then
  source = vim.fs.joinpath(vim.fn.getcwd(), source)
end
local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(source))))
local lock_path = vim.fs.joinpath(config_root, "lazy-lock.json")
local lock_ok, lock_lines = pcall(vim.fn.readfile, lock_path, "b")
local decoded_ok, lock = pcall(vim.json.decode, lock_ok and table.concat(lock_lines, "\n") or "")
local locked_commit = decoded_ok
    and type(lock) == "table"
    and type(lock["lazy.nvim"]) == "table"
    and lock["lazy.nvim"].commit
  or fallback_commit
if type(locked_commit) ~= "string" or not locked_commit:match("^[0-9a-f]+$") or #locked_commit ~= 40 then
  locked_commit = fallback_commit
end

local function git(args)
  local command = { "git" }
  vim.list_extend(command, args)
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or result.stdout or "git failed")
  end
  return vim.trim(result.stdout or "")
end

-- First launch only: fetch exactly the lockfile commit if lazy.nvim is missing.
if not vim.uv.fs_stat(lazypath) then
  local parent = vim.fs.dirname(lazypath)
  local temporary = string.format("%s.tmp.%d", lazypath, (vim.uv or vim.loop).os_getpid())
  vim.fn.mkdir(parent, "p")
  if vim.uv.fs_stat(temporary) then
    vim.fn.delete(temporary, "rf")
  end

  local bootstrap_error
  local _, step_error = git({ "init", temporary })
  bootstrap_error = step_error
  if not bootstrap_error then
    _, bootstrap_error = git({
      "-C",
      temporary,
      "remote",
      "add",
      "origin",
      "https://github.com/folke/lazy.nvim.git",
    })
  end
  if not bootstrap_error then
    _, bootstrap_error = git({
      "-C",
      temporary,
      "fetch",
      "--filter=blob:none",
      "--depth=1",
      "origin",
      locked_commit,
    })
  end
  if not bootstrap_error then
    _, bootstrap_error = git({ "-C", temporary, "checkout", "--detach", "FETCH_HEAD" })
  end
  local actual
  if not bootstrap_error then
    actual, bootstrap_error = git({ "-C", temporary, "rev-parse", "HEAD" })
  end
  if actual and actual ~= locked_commit then
    bootstrap_error = string.format("expected %s, fetched %s", locked_commit, actual)
  end
  if not bootstrap_error then
    local renamed, rename_error = vim.uv.fs_rename(temporary, lazypath)
    bootstrap_error = not renamed and rename_error or nil
  end
  if bootstrap_error then
    vim.fn.delete(temporary, "rf")
    error("Failed to bootstrap locked lazy.nvim:\n" .. tostring(bootstrap_error))
  end
end

-- So `require("lazy")` resolves to the cloned plugin.
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Keep installs and restores tied to this config checkout's lockfile.
  lockfile = lock_path,

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
