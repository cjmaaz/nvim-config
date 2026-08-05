-- ============================================================
-- SECTION 7: COLORSCHEME
-- Muted Kanagawa Dragon palette for comfortable long sessions
-- ============================================================

return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      compile = false,
      undercurl = true,
      transparent = false,
      dimInactive = true,
      terminalColors = true,
      commentStyle = { italic = true },
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      theme = "dragon",
      background = {
        dark = "dragon",
        light = "lotus",
      },
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa-dragon")
    end,
  },
}
