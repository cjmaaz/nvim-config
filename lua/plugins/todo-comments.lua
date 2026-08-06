--------------------------------------------------------------------------------
-- todo-comments — highlight + jump TODO / FIXME / …
-- Refs: CodeOSS ui.lua; Kickstart (signs = false).
-- Needs: plenary (pulled in). Telescope optional for <leader>st.
-- Alts: signs = false (Kickstart quieter gutter) · skip Telescope map.
--------------------------------------------------------------------------------

return {
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = true, -- gutter icons (CodeOSS); set false for Kickstart quieter gutter
      -- signs = false,
    },
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next TODO comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous TODO comment",
      },
      { "<leader>st", "<cmd>TodoTelescope<CR>", desc = "Search TODO comments" },
      -- { "<leader>st", "<cmd>TodoQuickFix<CR>", desc = "TODO quickfix" }, -- no Telescope
    },
  },
}
