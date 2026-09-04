--------------------------------------------------------------------------------
-- Sessions — restore buffers/cwd across Neovim restarts
-- Refs: LazyVim uses folke/persistence.nvim; Kickstart/CodeOSS/Craftzdog often skip.
-- Pick: persistence.nvim (small) over auto-session / possession (heavier).
-- Alts: auto-session · neovim-session-manager · plain :mksession.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

local function started_bare()
  return vim.fn.argc() == 0 and #vim.v.argv == 1 and not vim.g.started_with_stdin
end

return {
  {
    "folke/persistence.nvim",

    -- Load at UI startup so bare `nvim` can restore before normal interaction.
    event = "VimEnter",
    -- event = "BufReadPre", -- manual restore only; slightly less blank-start work
    -- lazy = false, -- always load at startup (rarely needed)

    opts = {
      -- Where session files are written (one file per cwd by default).
      -- dir = vim.fn.stdpath("state") .. "/sessions/", -- default state path
      -- dir = vim.fn.stdpath("data") .. "/sessions/", -- older / shared with plugins data

      -- Minimum number of buffers that must be open before a session is saved.
      -- need = 1, -- default: save even a single buffer
      -- need = 2, -- skip “just opened one file” sessions

      -- Split sessions by git branch (same cwd, different branch → different file).
      branch = true, -- preserve separate work when hopping non-main branches
      -- branch = false, -- keep one session per directory across every branch
    },

    config = function(_, opts)
      local persistence = require("persistence")
      persistence.setup(opts)

      if started_bare() then
        vim.schedule(function()
          local current = persistence.current()
          local unbranched = persistence.current({ branch = false })
          if vim.fn.filereadable(current) == 1 or vim.fn.filereadable(unbranched) == 1 then
            persistence.load() -- prefer the launch directory (and current branch)
          else
            persistence.load({ last = true }) -- otherwise resume the latest workspace
          end
        end)
      end
    end,

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
