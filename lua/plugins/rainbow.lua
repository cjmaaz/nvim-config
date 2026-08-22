--------------------------------------------------------------------------------
-- Rainbow brackets — depth-colored (), [], {}, <> via treesitter
-- Refs: none of our four require it; common treesitter QoL add-on.
-- Pick: HiPhish/rainbow-delimiters.nvim with shared 10-color palette
--   (lua/config/rainbow_palette.lua — also used by indent-blankline scope).
-- Alts: indent-blankline scope only · nvim-ts-rainbow2 (older) · skip.
-- Cheatsheet: docs/keymaps/qol.md · docs/keymaps/treesitter.md
--------------------------------------------------------------------------------

local palette = require("config.rainbow_palette")

return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    -- event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- needs parsers for the language
    },
    config = function()
      palette.apply({ bold = false }) -- match the non-bold active scope hairline
      -- palette.apply({ bold = true }) -- stronger brackets and scope guide

      -- Re-apply after colorscheme changes (themes wipe unknown groups).
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_rainbow_delimiters", { clear = true }),
        callback = function()
          palette.apply({ bold = false })
        end,
      })

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
        highlight = palette.names(),
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
