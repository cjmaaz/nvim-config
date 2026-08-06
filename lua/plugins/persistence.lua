--------------------------------------------------------------------------------
-- Sessions — restore buffers/cwd across Neovim restarts
-- Refs: LazyVim uses folke/persistence.nvim; Kickstart/CodeOSS/Craftzdog often skip.
-- Pick: persistence.nvim (small) over auto-session / possession (heavier).
-- Alts: auto-session · neovim-session-manager · plain :mksession.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

return {
  {
    "folke/persistence.nvim",

    -- When to start tracking open buffers for a session.
    event = "BufReadPre", -- as soon as a real file opens (usual)
    -- event = "BufReadPost", -- slightly later
    -- lazy = false, -- always load at startup (rarely needed)

    opts = {
      -- Where session files are written (one file per cwd by default).
      -- dir = vim.fn.stdpath("state") .. "/sessions/", -- default state path
      -- dir = vim.fn.stdpath("data") .. "/sessions/", -- older / shared with plugins data

      -- Minimum number of buffers that must be open before a session is saved.
      -- need = 1, -- default: save even a single buffer
      -- need = 2, -- skip “just opened one file” sessions

      -- Split sessions by git branch (same cwd, different branch → different file).
      -- branch = false, -- default: one session per directory
      -- branch = true, -- nicer if you hop branches a lot in one project
    },

    keys = {
      -- Restore the session recorded for the **current working directory**.
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Session restore (cwd)",
      },
      -- { "<leader>qs", function() require("persistence").load({ last = true }) end, desc = "…" }, -- wrong: that is “last”

      -- Interactive picker over saved sessions.
      {
        "<leader>qS",
        function()
          require("persistence").select()
        end,
        desc = "Session select",
      },

      -- Restore whatever was saved most recently (any cwd).
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Session restore (last)",
      },

      -- Stop persistence for **this** Neovim process so quitting won’t overwrite the file.
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Session don't save on exit",
      },
      -- No map: persistence saves automatically on VimLeavePre unless you stop it.
    },
  },
}
