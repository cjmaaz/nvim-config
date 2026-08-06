--------------------------------------------------------------------------------
-- Bufferline — visual list of *buffers* (not Vim tabpages)
-- Keep <S-h>/<S-l> from keymaps.lua; leave gt/gT alone.
-- Refs: Craftzdog has bufferline but mode="tabs" (tabpages) — we use buffers.
-- Alts: skip · barbar.nvim · mini.tabline
--------------------------------------------------------------------------------

return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    version = "*", -- pin to release tags
    -- version = false, -- track latest commits
    dependencies = {
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    opts = {
      options = {
        -- What the bar shows.
        mode = "buffers", -- one entry per buffer (matches <S-h/l>)
        -- mode = "tabs", -- Craftzdog: Vim tabpages only (different concept)

        separator_style = "thin", -- quiet separators
        -- separator_style = "slant", -- needs a Nerd Font / more chrome
        -- separator_style = "slope",
        -- separator_style = "padded_slant",

        always_show_bufferline = true, -- show even with one buffer
        -- always_show_bufferline = false, -- hide until 2+ buffers

        show_buffer_close_icons = false, -- less clutter; close with <leader>bd
        -- show_buffer_close_icons = true,
        show_close_icon = false,
        -- show_close_icon = true,

        diagnostics = false, -- turn on after LSP: "nvim_lsp"
        -- diagnostics = "nvim_lsp",
      },
    },
    -- Optional: click-cycle via bufferline (we already have <S-h/l>).
    -- keys = {
    --   { "<S-l>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    --   { "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev buffer" },
    -- },
    -- Craftzdog uses <Tab>/<S-Tab> instead — avoid if you use Tab for completion later.
  },
}
