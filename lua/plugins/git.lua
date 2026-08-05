--------------------------------------------------------------------------------
-- Git signs in the gutter (feeds lualine "diff" / branch context)
-- Hunk keymaps intentionally omitted — add in a later slice (on_attach).
--
-- Alternatives / related tools (don't enable overlapping UIs blindly):
--   - lualine "branch"/"diff" alone (no gutter) — thinner setup
--   - tpope/vim-fugitive — commands (:Git), not a statusline by itself
--   - Neogit / lazygit.nvim — full TUI clients (later topic)
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
      current_line_blame = false, -- off for now (add later if you like inline blame)
      -- current_line_blame = true, -- show author/date at EOL (or see opts below)
      -- current_line_blame_opts = {
      --   delay = 500, -- ms before blame appears
      --   -- delay = 1000, -- slower / less distracting
      --   virt_text_pos = "eol", -- strongest default: end of line
      --   -- virt_text_pos = "overlay", -- over the buffer text
      --   -- virt_text_pos = "right_align", -- right edge of the window
      -- },

      -- Follow renames inside the repo when watching .git.
      -- watch_gitdir = { follow_files = true }, -- default-ish; enable if you rename often
      -- max_file_length = 40000, -- skip signs on huge files (perf)
      -- max_file_length = 10000, -- stricter cutoff on slow machines

      -- Preview / blame floating windows.
      -- preview_config = { border = "rounded", style = "minimal" }, -- rounded float
      -- preview_config = { border = "single", style = "minimal" }, -- simpler border

      -- Next slice: buffer-local hunk maps, e.g.
      -- on_attach = function(bufnr)
      --   local gs = require("gitsigns")
      --   local function map(mode, lhs, rhs, desc)
      --     vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      --   end
      --   -- Motion style A (Vim diff muscle memory) — strongest default later:
      --   map("n", "]c", function() gs.nav_hunk("next") end, "Next hunk")
      --   map("n", "[c", function() gs.nav_hunk("prev") end, "Prev hunk")
      --   -- Motion style B (hunk-oriented):
      --   -- map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
      --   -- map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
      --   -- Leader prefix: <leader>h (hunk) vs <leader>g (git) — pick one family later.
      --   -- map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
      --   -- map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
      --   -- map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
      -- end,
    },
  },
}
