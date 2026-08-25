--------------------------------------------------------------------------------
-- Git signs in the gutter (feeds lualine "diff" / branch context)
-- Hunk navigation + actions live in on_attach (see docs/keymaps/git.md).
--
-- Alternatives / related tools (don't enable overlapping UIs blindly):
--   - lualine "branch"/"diff" alone (no gutter) — thinner setup
--   - tpope/vim-fugitive — commands (:Git), not a statusline by itself
--   - lazygit.nvim — full TUI (`lua/plugins/lazygit.lua`, <leader>gg)
--   - Neogit / fugitive — other full clients (not wired)
--------------------------------------------------------------------------------

return {
  {
    "lewis6991/gitsigns.nvim",
    -- When to attach gitsigns to buffers.
    event = { "BufReadPre", "BufNewFile" }, -- as soon as a file buffer opens
    -- event = "VeryLazy", -- defer until after startup UI settles
    -- lazy = false, -- load at startup (signs ready immediately; slightly slower open)

    opts = {
      -- Characters in the signcolumn (needs vim.opt.signcolumn = "yes"|auto).
      -- Active: Nerd Font glyphs (needs vim.g.have_nerd_font / a Nerd Font terminal).
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      -- ASCII fallback (use if the terminal font is not a Nerd Font):
      -- signs = {
      --   add = { text = "+" },
      --   change = { text = "~" },
      --   delete = { text = "_" },
      --   topdelete = { text = "‾" },
      --   changedelete = { text = "~" },
      --   untracked = { text = "┆" },
      -- },

      -- Show signs in the gutter.
      signcolumn = true, -- gutter signs on (default)
      -- signcolumn = false, -- no gutter signs (lualine diff can still work)

      -- Color the line number for changed lines.
      numhl = false, -- off (less visual noise)
      -- numhl = true, -- tint line numbers on hunks

      -- Highlight the whole changed line.
      linehl = false, -- off (noisy in busy diffs)
      -- linehl = true, -- full-line highlight for hunks

      -- Highlight changed words inside the line.
      word_diff = false, -- off until you want inline word highlights
      -- word_diff = true, -- show word-level diffs in the buffer

      -- Signs for brand-new untracked files.
      attach_to_untracked = true, -- show untracked markers
      -- attach_to_untracked = false, -- skip untracked files

      -- Virtual-text blame on the cursor line.
      current_line_blame = false, -- off by default; toggle with <leader>tb when you need it
      -- current_line_blame = true, -- always-on EOL blame (noisy in busy files)
      -- current_line_blame_opts = {
      --   delay = 500, -- ms before blame appears
      --   -- delay = 1000, -- slower / less distracting
      --   -- delay = 0, -- immediate
      --   virt_text_pos = "eol", -- strongest default: end of line
      --   -- virt_text_pos = "overlay", -- over the buffer text
      --   -- virt_text_pos = "right_align", -- right edge of the window
      --   -- virt_text_priority = 100,
      -- },
      -- current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
      -- current_line_blame_formatter = "<author> · <summary>", -- shorter

      -- Follow renames inside the repo when watching .git.
      -- watch_gitdir = { follow_files = true }, -- default-ish; enable if you rename often
      -- max_file_length = 40000, -- skip signs on huge files (perf)
      -- max_file_length = 10000, -- stricter cutoff on slow machines

      -- Preview / blame floating windows.
      -- preview_config = { border = "rounded", style = "minimal" }, -- rounded float
      -- preview_config = { border = "single", style = "minimal" }, -- simpler border

      -- Buffer-local hunk maps (only in git-backed buffers gitsigns attaches to).
      -- Cheatsheet: docs/keymaps/git.md
      on_attach = function(bufnr)
        local gs = require("gitsigns")

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Next / previous hunk.
        -- Style A: ]c/[c — Vim diff keys; in a :diff window, keep builtin ]c/[c.
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next git hunk")
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Previous git hunk")
        -- Style B: ]h/[h — hunk-only; leaves ]c/[c alone for :diff
        -- map("n", "]h", function() gs.nav_hunk("next") end, "Next git hunk")
        -- map("n", "[h", function() gs.nav_hunk("prev") end, "Previous git hunk")

        -- Hunk actions — <leader>h… (hunk). Swap h→g if you prefer <leader>g….
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        -- map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        -- map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")

        -- Same actions on a visual selection (stage/reset only those lines).
        map("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected hunk")
        map("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected hunk")

        -- Whole-buffer stage/reset (capital letter = “bigger”).
        map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")

        -- Preview
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk") -- float
        -- map("n", "<leader>hi", gs.preview_hunk_inline, "Preview hunk inline")

        -- Blame / diff
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
        map("n", "<leader>hd", gs.diffthis, "Diff against index")
        -- map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff against previous commit")

        -- Toggle extras (live under <leader>t… with FoS/lint/inlays).
        map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle line blame")
        -- map("n", "<leader>tb", function() gs.toggle_current_line_blame() end, "…") -- same
        -- map("n", "<leader>tW", gs.toggle_word_diff, "Toggle word diff") -- tw is word wrap
        -- map("n", "<leader>td", gs.toggle_deleted, "Toggle deleted lines") -- show removed lines as virtual text

        -- Optional quickfix exports:
        -- map("n", "<leader>hq", gs.setqflist, "Quickfix current-file changes")
        -- map("n", "<leader>hQ", function() gs.setqflist("all") end, "Quickfix all repo changes")

        -- Text object: operator/visual around the hunk under the cursor (e.g. cih, vah).
        map({ "o", "x" }, "ih", gs.select_hunk, "Select git hunk")
        -- map({ "o", "x" }, "ah", gs.select_hunk, "Select git hunk") -- same target; "a" vs "i" is taste
      end,
    },
  },
}
