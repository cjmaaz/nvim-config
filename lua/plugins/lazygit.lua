--------------------------------------------------------------------------------
-- Lazygit — float TUI for staging / commit / branch / rebase
-- Refs: none of our four refs ship it in-tree (LazyVim uses snacks.lazygit).
-- Pick: kdheepak/lazygit.nvim (focused wrapper) over snacks.nvim (whole suite)
--   or raw `:terminal lazygit`. Needs host `lazygit` — see docs/TOOLS.md.
-- Alts: folke/snacks.nvim lazygit · Neogit · fugitive · Telescope git pickers.
--------------------------------------------------------------------------------

return {
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim", -- already used by Telescope
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
      { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file)" },
      -- { "<leader>gl", "<cmd>LazyGitFilter<cr>", desc = "LazyGit (project log)" },
    },
  },
}
