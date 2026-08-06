--------------------------------------------------------------------------------
-- Dial — smarter <C-a> / <C-x> (dates, bools, enums, …)
-- Refs: none required in our four; common LazyVim optional / Craftzdog uses +/-.
-- Pick: monaqa/dial.nvim. Alts: stock <C-a>/<C-x> (numbers only) · Craftzdog +/-.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

return {
  {
    "monaqa/dial.nvim",
    keys = {
      -- Normal: increment / decrement under cursor.
      {
        "<C-a>",
        function()
          require("dial.map").manipulate("increment", "normal")
        end,
        desc = "Dial increment",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manipulate("decrement", "normal")
        end,
        desc = "Dial decrement",
      },
      -- Visual: apply to each line / selection.
      {
        "<C-a>",
        function()
          require("dial.map").manipulate("increment", "visual")
        end,
        mode = "v",
        desc = "Dial increment",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manipulate("decrement", "visual")
        end,
        mode = "v",
        desc = "Dial decrement",
      },
      -- g<C-a> / g<C-x>: additive across a visual block (1,2,3…).
      {
        "g<C-a>",
        function()
          require("dial.map").manipulate("increment", "gvisual")
        end,
        mode = "v",
        desc = "Dial additive increment",
      },
      {
        "g<C-x>",
        function()
          require("dial.map").manipulate("decrement", "gvisual")
        end,
        mode = "v",
        desc = "Dial additive decrement",
      },
      -- Craftzdog-style +/- instead of (or besides) Ctrl:
      -- { "+", function() require("dial.map").manipulate("increment", "normal") end, desc = "…" },
      -- { "-", function() require("dial.map").manipulate("decrement", "normal") end, desc = "…" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        -- Default group used by <C-a> / <C-x>.
        default = {
          augend.integer.alias.decimal, -- 0, 1, 2, …
          -- augend.integer.alias.decimal_int, -- includes negatives more aggressively
          augend.integer.alias.hex, -- 0xFF
          augend.date.alias["%Y-%m-%d"], -- 2026-08-06
          -- augend.date.alias["%m/%d/%Y"], -- US dates
          -- augend.date.alias["%d.%m.%Y"], -- EU-ish
          augend.constant.alias.bool, -- true ↔ false
          -- augend.constant.new({ elements = { "True", "False" }, word = true, cyclic = true }), -- Python
          augend.constant.new({
            elements = { "and", "or" },
            word = true, -- whole-word only
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "&&", "||" },
            word = false,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "let", "const" },
            word = true,
            cyclic = true,
          }),
          -- augend.semver.alias.semver, -- 1.2.3 patch bumps
          -- augend.hexcolor.new({ case = "lower" }), -- #aabbcc (overlaps highlight-colors)
        },
        -- Extra groups: require("dial.map").manipulate("increment", "normal", "mygroup")
        -- mygroup = { … },
      })
    end,
  },
}
