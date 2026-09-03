--------------------------------------------------------------------------------
-- Trouble — sticky diagnostics / lists panel (richer than :lopen)
-- Refs: LazyVim ships trouble; Kickstart optional; CodeOSS uses loclist only.
-- Pick: folke/trouble.nvim. Maps under <leader>x… (sessions keep <leader>q…).
-- Alts: stock loclist/qflist · Telescope <leader>sd · snacks.picker diagnostics.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

return {
  {
    "folke/trouble.nvim",

    -- Load when the command or a key below runs (no need at startup).
    cmd = "Trouble",
    -- event = "VeryLazy", -- preload quietly if you open Trouble constantly

    opts = {
      -- Close the list automatically when it becomes empty.
      -- auto_close = false, -- default: leave the window open
      -- auto_close = true, -- tidy after you fix the last item

      -- Whether opening Trouble steals the cursor into the list window.
      -- focus = false, -- default: keep editing the code window
      -- focus = true, -- jump into the list (keyboard-driven triage)

      -- Preview the source location as you move in the list.
      -- auto_preview = true, -- default-ish: show preview
      -- auto_preview = false, -- quieter / faster on huge workspaces

      -- Follow the cursor in the code buffer (highlight matching list row).
      -- follow = true,
      -- follow = false,

      -- Indent guides / folding of file groups in the list.
      -- indent_guides = true,
      -- indent_guides = false,

      -- TODO tree: selecting a row stays a list operation until explicitly opened.
      modes = {
        todo = {
          auto_preview = true, -- show the selected TODO in the main editor window
          -- auto_preview = false, -- keep the editor unchanged while browsing the tree
          preview = {
            type = "main",
            scratch = false, -- preview the real file buffer, never a [No Name] copy
            -- scratch = true, -- faster unloaded-file preview, but it is not an editable file buffer
          },
          keys = {
            ["<cr>"] = "jump_close", -- open the real file, focus it, and close the tree
            ["<2-leftmouse>"] = "jump_close", -- same behavior for double-click
            i = false, -- disable Trouble's internal item-table inspector in TODO mode
          },
        },
        -- diagnostics = { mode = "diagnostics", preview = { type = "split", relative = "win", position = "right", size = 0.3 } },
        -- symbols = { win = { position = "right", size = 0.3 } },
      },

      -- icons = { … }, -- customize severity / fold glyphs (needs Nerd Font for fancy defaults)
      -- warn_no_results = true, -- notify when a mode has nothing to show
      -- open_no_results = false, -- don’t open an empty panel
    },

    keys = {
      -- Workspace (or project) diagnostics — main “what’s broken?” panel.
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      -- { "<leader>xx", "<cmd>Trouble diagnostics<cr>", desc = "…" }, -- open only (no toggle)

      -- Same list, filtered to the **current buffer**.
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer diagnostics (Trouble)",
      },

      -- LSP document symbols (outline-ish). focus=false keeps you in the code.
      {
        "<leader>xs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      -- { "<leader>xs", "<cmd>Trouble symbols toggle focus=true<cr>", desc = "…" }, -- steal focus

      -- Vim **location list** (buffer-scoped) inside Trouble’s UI.
      {
        "<leader>xl",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location list (Trouble)",
      },
      -- Old core map was: vim.diagnostic.setloclist → :lopen (see keymaps.lua comments).

      -- Vim **quickfix** (global) inside Trouble.
      {
        "<leader>xq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix (Trouble)",
      },

      -- Jump next/prev item while the panel is useful (optional; ]t is todo-comments).
      -- {
      --   "]x",
      --   function()
      --     require("trouble").next({ skip_groups = true, jump = true })
      --   end,
      --   desc = "Next Trouble item",
      -- },
      -- {
      --   "[x",
      --   function()
      --     require("trouble").prev({ skip_groups = true, jump = true })
      --   end,
      --   desc = "Prev Trouble item",
      -- },
    },
  },
}
