--------------------------------------------------------------------------------
-- Git signs in the gutter (feeds lualine "diff" / feels like git status)
-- Hunk keymaps intentionally omitted — add in a later slice.
--------------------------------------------------------------------------------

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- when you open a real file
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
    },
  },
}
