--------------------------------------------------------------------------------
-- Breadcrumbs — LSP document symbols in the statusline (nvim-navic)
-- Refs: common LazyVim-era pattern; none of our four refs ship this today.
-- Needs: an LSP that supports textDocument/documentSymbol (lua_ls, ts_ls, …).
-- Alts: Bekaboo/dropbar.nvim (clickable winbar) · winbar-only navic · skip.
--------------------------------------------------------------------------------

return {
  {
    "SmiteshP/nvim-navic",
    lazy = true, -- pulled in when an LSP attaches (or via lualine require)
    opts = {
      lsp = {
        auto_attach = true, -- attach to clients that support documentSymbol
        -- preference = { "clangd", "tsserver" }, -- prefer these when several attach
      },
      highlight = true, -- colored icons/text when the colorscheme defines Navic*
      separator = " › ",
      depth_limit = 5, -- truncate deep nests
      -- depth_limit = 0, -- unlimited
      click = false, -- navic click-to-jump needs newer APIs; leave off
    },
  },
}
