--------------------------------------------------------------------------------
-- Rainbow brackets — depth-colored (), [], {}, <> via treesitter
-- Refs: none of our four require it; common treesitter QoL add-on.
-- Pick: HiPhish/rainbow-delimiters.nvim with a 10-color high-contrast palette.
-- Alts: indent-blankline scope only · nvim-ts-rainbow2 (older) · skip.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

-- 10 hues spaced for easy nesting discrimination (not ROYGBIV order — adjacent
-- levels stay high-contrast). Tweak hexes if your terminal/theme washes them out.
local palette = {
  { "RainbowDelimiterCustom1", "#FF5555" }, -- vivid red
  { "RainbowDelimiterCustom2", "#F1FA8C" }, -- bright yellow
  { "RainbowDelimiterCustom3", "#8BE9FD" }, -- cyan
  { "RainbowDelimiterCustom4", "#FF79C6" }, -- pink / magenta
  { "RainbowDelimiterCustom5", "#50FA7B" }, -- green
  { "RainbowDelimiterCustom6", "#BD93F9" }, -- purple
  { "RainbowDelimiterCustom7", "#FFB86C" }, -- orange
  { "RainbowDelimiterCustom8", "#61AFEF" }, -- blue
  { "RainbowDelimiterCustom9", "#FF6E6E" }, -- coral
  { "RainbowDelimiterCustom10", "#E2E2A0" }, -- pale gold / khaki
  -- Swap any pair if two levels still look too close on your display.
}

local function apply_rainbow_colors()
  for _, item in ipairs(palette) do
    vim.api.nvim_set_hl(0, item[1], { fg = item[2], bold = true })
    -- vim.api.nvim_set_hl(0, item[1], { fg = item[2], bold = false }) -- quieter
  end
end

return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    -- event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- needs parsers for the language
    },
    config = function()
      apply_rainbow_colors()
      -- Re-apply after colorscheme changes (themes wipe unknown groups).
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_rainbow_delimiters", { clear = true }),
        callback = apply_rainbow_colors,
      })

      local highlight = {}
      for _, item in ipairs(palette) do
        highlight[#highlight + 1] = item[1]
      end

      require("rainbow-delimiters.setup").setup({
        strategy = {
          [""] = "rainbow-delimiters.strategy.global", -- whole buffer
          -- [""] = "rainbow-delimiters.strategy.local", -- visible window only (faster on huge files)
          -- vim = "rainbow-delimiters.strategy.local",
        },
        query = {
          [""] = "rainbow-delimiters", -- default delimiters
          -- lua = "rainbow-blocks", -- also color Lua do/end / function blocks
          -- tsx = "rainbow-parens", -- parens only (skip JSX tags) if tags feel noisy
          -- javascript = "rainbow-parens",
        },
        highlight = highlight,
        -- highlight = { -- stock 7-group fallback:
        --   "RainbowDelimiterRed",
        --   "RainbowDelimiterYellow",
        --   "RainbowDelimiterBlue",
        --   "RainbowDelimiterOrange",
        --   "RainbowDelimiterGreen",
        --   "RainbowDelimiterViolet",
        --   "RainbowDelimiterCyan",
        -- },
      })
    end,
  },
}
