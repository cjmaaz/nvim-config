--------------------------------------------------------------------------------
-- Comment.nvim — gcc / gc{motion} / gbc / visual gc
-- Refs: CodeOSS editor.lua (Comment without context); upstream + ts-context-commentstring
--   for correct strings inside JSX/TSX/Vue/HTML injections.
-- Alts: Neovim 0.10+ built-in `gc` only · mini.comment · skip context-commentstring.
--------------------------------------------------------------------------------

return {
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = {
          enable_autocmd = false, -- Comment.nvim pre_hook triggers calculation instead
        },
      },
    },
    opts = function()
      return {
        padding = true, -- keep a space after comment markers
        sticky = true, -- cursor stays put after toggling
        -- ignore = "^$", -- uncomment to skip blank lines
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
        -- pre_hook = nil, -- CodeOSS-style: no treesitter context (weaker in JSX)
      }
    end,
  },
}
