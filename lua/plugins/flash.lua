--------------------------------------------------------------------------------
-- Flash — label-jump to word / treesitter node
-- Refs: Craftzdog ships flash (often disabled); LazyVim enables with `s`/`S`.
-- Pick: folke/flash.nvim on gs/gS (keeps stock `s` substitute; neo-tree `s` = vsplit).
-- Alts: leap.nvim · hop.nvim · EasyMotion · Telescope only.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

return {
  {
    "folke/flash.nvim",

    -- When to load.
    event = "VeryLazy", -- after UI start (usual)
    -- event = { "BufReadPost", "BufNewFile" }, -- earlier if you jump constantly
    -- lazy = false,

    opts = {
      -- Characters used as jump labels (first matches are preferred).
      -- labels = "asdfghjklqwertyuiopzxcvbnm", -- default-ish home-row heavy
      -- labels = "asdfghjkl;", -- fewer labels, less clutter

      -- search = {
      --   multi_window = true, -- default: jump across visible windows
      --   multi_window = false, -- current window only (Craftzdog-style tighter)
      --   forward = true, -- direction hints for incremental modes
      --   wrap = true, -- wrap around the buffer
      --   wrap = false,
      --   incremental = false, -- type pattern then labels
      --   incremental = true, -- refine as you type (Craftzdog enables this)
      -- },

      -- jump = {
      --   autojump = false, -- always show labels even for a single match
      --   autojump = true, -- jump immediately when only one match
      -- },

      -- label = {
      --   uppercase = true, -- also use A–Z as labels
      --   rainbow = { enabled = false }, -- colorful labels (fun / noisy)
      --   rainbow = { enabled = true, shade = 5 },
      -- },

      modes = {
        -- Enhance f / t / F / T with labels after the first hit.
        -- char = { enabled = true }, -- default: flash enhances f/t
        -- char = { enabled = false }, -- keep stock one-shot f/t (if flash feels noisy)
        -- char = { jump_labels = true }, -- show labels for multi-match f/t
        -- search = { enabled = true }, -- integrate with / ? search
        -- treesitter = { … }, -- defaults for gS / treesitter mode
      },
    },

    keys = {
      -- Primary jump: type a search char, then the label under the target.
      -- We use `gs` (not LazyVim `s`) so substitute `s` and neo-tree `s` stay free.
      {
        "gs",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
      -- LazyVim-style (steals `s` — only if you accept that tradeoff):
      -- { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },

      -- Jump by treesitter node (functions, blocks, …).
      {
        "gS",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
      },
      -- { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "…" }, -- LazyVim letter

      -- Operator-pending: e.g. `yr` then flash to remote-yank a range.
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      -- { "r", mode = "o", false }, -- disable if it fights another operator map

      -- Treesitter search from operator / visual.
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter search",
      },

      -- While typing `/` or `?`, toggle Flash labels in the search UI.
      {
        "<C-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash search",
      },
      -- { "<C-s>", mode = { "c" }, false }, -- leave command-line search alone
    },
  },
}
