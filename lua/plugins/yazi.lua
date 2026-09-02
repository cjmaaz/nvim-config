--------------------------------------------------------------------------------
-- Optional Yazi file manager — full-screen transient workflow beside Neo-tree.
-- Loads only when the host `yazi` executable exists; Neo-tree remains fallback.
-- Refs: none of the four local references use Yazi; upstream yazi.nvim v14.
--------------------------------------------------------------------------------

local function yazi_command(argument)
  return function()
    -- Opening a terminal float from q: / q/ raises E11 and can strand input.
    if vim.fn.getcmdwintype() ~= "" then
      vim.notify("Close the command-line window before opening Yazi.", vim.log.levels.WARN, { title = "Yazi" })
      return
    end

    vim.cmd("Yazi" .. (argument and (" " .. argument) or ""))
  end
end

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
        yazi_command(),
        mode = { "n", "v" },
        desc = "Yazi: current file",
      },
      {
        "<leader>fY",
        yazi_command("cwd"),
        desc = "Yazi: working directory",
      },
      {
        "<leader>fr",
        yazi_command("toggle"),
        desc = "Yazi: resume session",
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

      -- Keep built-in terminal actions, then add a Normal-mode escape hatch.
      set_keymappings_function = function(yazi_buffer, config, context)
        require("yazi.config").set_keymappings(yazi_buffer, config, context)
        vim.keymap.set("n", "q", function()
          local ok = pcall(context.api.emit_to_yazi, context.api, { "quit" })
          if not ok and vim.api.nvim_buf_is_valid(yazi_buffer) then
            pcall(vim.api.nvim_buf_delete, yazi_buffer, { force = true })
          end
        end, {
          buffer = yazi_buffer,
          silent = true,
          desc = "Yazi: quit after leaving terminal mode",
        })
      end,
      -- set_keymappings_function = nil, -- stock terminal-mode mappings only

      keymaps = {
        show_help = "<f1>",
        -- Send the current directory or selected paths to Grug Far.
        replace_in_directory = "<c-g>",
        -- replace_in_directory = false, -- keep search-and-replace outside Yazi
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
