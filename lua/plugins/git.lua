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
    -- Attach when editing a file. Alternatives:
    --   event = "VeryLazy"
    --   lazy = false
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Characters in the signcolumn (requires vim.opt.signcolumn = "yes"|auto).
      -- Nerd Font style example (uncomment and delete the ASCII set if you prefer):
      -- signs = {
      --   add = { text = "▎" },
      --   change = { text = "▎" },
      --   delete = { text = "" },
      --   topdelete = { text = "" },
      --   changedelete = { text = "▎" },
      --   untracked = { text = "▎" },
      -- },
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },

      -- signcolumn = true, -- false = no gutter signs (statusline diff can still work)
      -- numhl = false, -- true = color the line number for changed lines
      -- linehl = false, -- true = highlight the whole changed line (noisy)
      -- word_diff = false, -- true = highlight changed words inside the line
      -- attach_to_untracked = true, -- show signs for new untracked files

      -- current_line_blame = false, -- true = virtual text blame on the cursor line
      -- current_line_blame_opts = {
      --   delay = 500, -- ms before blame appears
      --   virt_text_pos = "eol", -- "eol" | "overlay" | "right_align"
      -- },

      -- watch_gitdir = { follow_files = true }, -- track renames inside the repo
      -- max_file_length = 40000, -- skip signs on huge files (perf)

      -- Preview / blame floating windows:
      -- preview_config = { border = "rounded", style = "minimal" },

      -- Next slice: buffer-local hunk maps, e.g.
      -- on_attach = function(bufnr)
      --   local gs = require("gitsigns")
      --   local function map(mode, lhs, rhs, desc)
      --     vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      --   end
      --   -- Motion style A (Vim diff muscle memory):
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
