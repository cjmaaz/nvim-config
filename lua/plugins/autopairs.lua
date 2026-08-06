--------------------------------------------------------------------------------
-- Autopairs — insert (), {}, [], quotes, …
-- Refs: CodeOSS editor.lua; Kickstart plugins/autopairs.lua.
-- Alts: mini.pairs (LazyVim-ish) · built-in nothing.
--------------------------------------------------------------------------------

return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true, -- smarter pairing with Treesitter when available
      -- check_ts = false,
      fast_wrap = {}, -- <M-e> wrap selection (plugin default map)
      -- fast_wrap = false,
    },
  },
}
