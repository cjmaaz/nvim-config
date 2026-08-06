--------------------------------------------------------------------------------
-- Color highlighter — paint #hex / rgb() / hsl() / CSS names in-buffer
-- Refs: Craftzdog editor.lua (nvim-highlight-colors); Kickstart/CodeOSS skip.
-- Pick: brenoprata10/nvim-highlight-colors. Alts: NvChad colorizer · nvim-colorizer.lua.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

return {
  {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPre", "BufNewFile" },
    -- event = "VeryLazy",
    opts = {
      render = "background", -- fill the color span’s background
      -- render = "foreground", -- tint the text instead
      -- render = "virtual", -- virtual-text swatch (less layout shift)
      enable_hex = true, -- #RRGGBB / #RGB
      -- enable_hex = false,
      enable_short_hex = true, -- #RGB
      -- enable_short_hex = false,
      enable_rgb = true, -- rgb(…) / rgba(…)
      enable_hsl = true, -- hsl(…)
      enable_hsl_without_function = true, -- bare “210 40% 50%”-ish forms
      -- enable_hsl_without_function = false,
      enable_ansi = true, -- ANSI color codes
      -- enable_ansi = false,
      enable_var_usage = true, -- CSS var(--token) when resolvable
      -- enable_var_usage = false,
      enable_tailwind = true, -- bg-red-500-style classes
      -- enable_tailwind = false, -- quieter in non-Tailwind projects
      -- exclude_filetypes = { "lazy", "mason" },
      -- exclude_buftypes = { "nofile" },
    },
  },
}
