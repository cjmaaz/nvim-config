--------------------------------------------------------------------------------
-- Surround — add / delete / change surrounding pairs
-- Refs: Kickstart + CodeOSS mini.surround; vim-surround muscle memory is common.
-- Pick: kylechui/nvim-surround (ys/ds/cs — familiar) over mini.surround (sa/sd/sr).
-- Alts: mini.surround · tpope/vim-surround · skip (type delimiters by hand).
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

return {
  {
    "kylechui/nvim-surround",

    -- When to load (operators are useless without a buffer).
    event = { "BufReadPost", "BufNewFile" },
    -- event = "VeryLazy", -- defer until after UI settles
    -- lazy = false, -- always load (tiny cost)

    -- version = "*", -- pin to tagged releases only
    -- version = false, -- follow main (what we do by omitting version)

    opts = {
      -- Default operator maps (vim-surround style):
      --   ys{motion}{char}  — add surround (e.g. ysiw" → "word")
      --   yss{char}         — surround current line
      --   ds{char}          — delete surround (e.g. ds")
      --   cs{old}{new}      — change surround (e.g. cs"')
      --   Visual mode: S{char} — surround selection
      --
      -- Remap or disable individual chords if they fight another plugin:
      -- keymaps = {
      --   insert = "<C-g>s", -- insert-mode surround (default)
      --   -- insert = false, -- disable insert-mode maps
      --   insert_line = "<C-g>S",
      --   normal = "ys",
      --   -- normal = "gz", -- LazyVim-ish if `ys` feels awkward
      --   normal_cur = "yss",
      --   normal_line = "yS",
      --   normal_cur_line = "ySS",
      --   visual = "S",
      --   -- visual = "gS", -- free visual S for something else
      --   visual_line = "gS",
      --   delete = "ds",
      --   change = "cs",
      --   change_line = "cS",
      -- },

      -- aliases = { … }, -- e.g. map `b` → `)` for “bracket”
      -- surrounds = { … }, -- custom surround definitions (HTML tags, function calls, …)
      -- move_cursor = "begin", -- where to leave the cursor after surround
      -- move_cursor = false, -- don’t move the cursor
      -- indent_lines = true, -- reindent after surround when sensible
      -- indent_lines = false,
    },

    -- mini.surround alternate (Kickstart/CodeOSS) would look like:
    -- { "echasnovski/mini.surround", opts = { mappings = { add = "sa", delete = "sd", replace = "sr" } } },
  },
}
