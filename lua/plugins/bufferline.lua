--------------------------------------------------------------------------------
-- Bufferline — visual list of *buffers* (not Vim tabpages)
-- Keep <S-h>/<S-l> from keymaps.lua; leave gt/gT alone.
-- Refs: Craftzdog has bufferline but mode="tabs" (tabpages) — we use buffers.
-- Alts: skip · barbar.nvim · mini.tabline
--------------------------------------------------------------------------------

local chrome = require("config.ui_chrome")

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

        -- Thin rose marker reinforces the selected buffer without adding height.
        indicator = { icon = "▏", style = "icon" },
        -- indicator = { style = "underline" }, -- bottom edge instead of a side marker

        diagnostics = false, -- turn on after LSP: "nvim_lsp"
        -- diagnostics = "nvim_lsp",
      },
      -- Same flat Bordo layers as lualine; active buffer gets the bright divider.
      highlights = {
        fill = { fg = chrome.muted_fg, bg = chrome.panel_bg },
        background = { fg = chrome.muted_fg, bg = chrome.panel_bg },
        buffer_visible = { fg = chrome.panel_fg, bg = chrome.panel_bg },
        buffer_selected = {
          fg = chrome.divider_fg,
          bg = chrome.active_bg,
          bold = true,
          italic = false,
        },
        indicator_selected = { fg = chrome.border_fg, bg = chrome.active_bg },
        separator = { fg = chrome.active_bg, bg = chrome.panel_bg },
        separator_visible = { fg = chrome.active_bg, bg = chrome.panel_bg },
        separator_selected = { fg = chrome.divider_fg, bg = chrome.active_bg },
        modified = { fg = chrome.title_fg, bg = chrome.panel_bg },
        modified_visible = { fg = chrome.title_fg, bg = chrome.panel_bg },
        modified_selected = { fg = chrome.title_fg, bg = chrome.active_bg },
        duplicate = { fg = chrome.muted_fg, bg = chrome.panel_bg, italic = true },
        duplicate_visible = { fg = chrome.muted_fg, bg = chrome.panel_bg, italic = true },
        duplicate_selected = { fg = chrome.panel_fg, bg = chrome.active_bg, italic = true },
        tab = { fg = chrome.muted_fg, bg = chrome.panel_bg },
        tab_selected = { fg = chrome.divider_fg, bg = chrome.active_bg, bold = true },
        tab_separator = { fg = chrome.active_bg, bg = chrome.panel_bg },
        tab_separator_selected = { fg = chrome.divider_fg, bg = chrome.active_bg },
      },
      -- highlights = {}, -- let bufferline derive everything from the colorscheme
    },
    -- Optional: click-cycle via bufferline (we already have <S-h/l>).
    -- keys = {
    --   { "<S-l>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    --   { "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev buffer" },
    -- },
    -- Craftzdog uses <Tab>/<S-Tab> instead — avoid if you use Tab for completion later.
  },
}
