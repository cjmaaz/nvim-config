--------------------------------------------------------------------------------
-- Optional Yazi file manager — full-screen transient workflow beside Neo-tree.
-- Loads only when the host `yazi` executable exists; Neo-tree remains fallback.
-- Refs: none of the four local references use Yazi; upstream yazi.nvim v14.
--------------------------------------------------------------------------------

return {
  {
    "mikavilpas/yazi.nvim",
    version = "14.*", -- stable v14 API (requires current stable Yazi)
    -- version = "*", -- follow future stable major releases
    event = "VeryLazy",
    cond = function()
      return vim.fn.executable("yazi") == 1
    end,
    -- cond = nil, -- install/load the integration even when the binary is absent
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>fy",
        "<cmd>Yazi<CR>",
        mode = { "n", "v" },
        desc = "Yazi: current file",
      },
      {
        "<leader>fY",
        "<cmd>Yazi cwd<CR>",
        desc = "Yazi: working directory",
      },
    },
    opts = {
      -- Keep explicit directory ownership and the sidebar with Neo-tree.
      open_for_directories = false,
      -- open_for_directories = true, -- make Yazi replace directory buffers
      open_multiple_tabs = false,
      -- open_multiple_tabs = true, -- mirror visible splits as Yazi tabs
      change_neovim_cwd_on_close = false,
      -- change_neovim_cwd_on_close = true, -- follow Yazi's final directory

      -- Match the existing rounded floating-window chrome.
      floating_window_scaling_factor = 0.9,
      -- floating_window_scaling_factor = 1.0, -- full-screen terminal manager
      yazi_floating_window_winblend = 0,
      -- yazi_floating_window_winblend = 10, -- translucent alternate
      yazi_floating_window_border = "rounded",
      -- yazi_floating_window_border = "none", -- borderless full-screen look

      keymaps = {
        show_help = "<f1>",
        -- No grug-far in this config, so leave replacement unbound.
        replace_in_directory = false,
        -- Keep Ctrl-\ available for Neovim's native terminal escape prefix.
        change_working_directory = false,
        -- Avoid grealpath/coreutils as an otherwise optional macOS dependency.
        copy_relative_path_to_selected_files = false,
        -- copy_relative_path_to_selected_files = "<c-y>", -- requires realpath/grealpath
        -- No snacks.picker in this config, so keep window picking unbound.
        open_and_pick_window = false,
        -- open_and_pick_window = "<c-o>", -- restore after adding snacks.picker
      },
      integrations = {
        grep_in_directory = "telescope",
        -- grep_in_directory = "fzf-lua", -- use the Salesforce picker stack instead
      },
      log_level = vim.log.levels.OFF,
      -- log_level = vim.log.levels.DEBUG, -- diagnose via :checkhealth yazi
    },
  },
}
