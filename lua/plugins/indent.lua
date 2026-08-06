--------------------------------------------------------------------------------
-- Indent guides (indent-blankline / ibl)
-- Refs: CodeOSS ui.lua; Kickstart plugins/indent_line.lua (empty opts).
-- Alts: mini.indentscope · snacks indent · none (use treesitter indent only).
--------------------------------------------------------------------------------

return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      -- indent = { char = "┊" },
      scope = {
        enabled = true, -- highlight current indent scope
        show_start = false,
        show_end = false,
        -- show_start = true,
      },
      exclude = {
        filetypes = { "help", "lazy", "mason", "neo-tree", "notify", "TelescopePrompt" },
      },
    },
  },
}
