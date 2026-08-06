--------------------------------------------------------------------------------
-- Yank history — keep past yanks / smarter put
-- Refs: LazyVim optional yanky; Craftzdog uses register tricks instead.
-- Pick: gbprod/yanky.nvim. Alts: telescope-yank · registers only · skip.
-- Cheatsheet: docs/keymaps/qol.md
--------------------------------------------------------------------------------

return {
  {
    "gbprod/yanky.nvim",
    event = { "BufReadPost", "BufNewFile" },
    -- event = "VeryLazy",
    opts = {
      ring = {
        history_length = 50, -- how many yanks to remember
        -- history_length = 20, -- shorter ring
        -- history_length = 100, -- longer ring (more memory)
        storage = "shada", -- survive restarts via ShaDa
        -- storage = "memory", -- session-only (no disk)
        sync_with_numbered_registers = true, -- "1–"9 stay useful
        -- sync_with_numbered_registers = false,
      },
      highlight = {
        on_put = true, -- flash the put region briefly
        on_yank = true, -- flash the yanked region (pairs with TextYankPost)
        -- on_put = false,
        -- on_yank = false,
        timer = 150, -- ms highlight duration
        -- timer = 300, -- longer flash
      },
      -- system_clipboard = { sync_with_ring = true }, -- keep OS clipboard in the ring
      -- system_clipboard = { sync_with_ring = false },
    },
    keys = {
      -- Replace stock p/P so puts come from the yank ring.
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yanky yank" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Yanky put after" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Yanky put before" },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Yanky gput after" },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Yanky gput before" },
      -- Cycle through the ring after a put (next / previous entry).
      { "<c-p>", "<Plug>(YankyPreviousEntry)", desc = "Yanky previous entry" },
      { "<c-n>", "<Plug>(YankyNextEntry)", desc = "Yanky next entry" },
      -- { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "…" }, -- indent-aware variants
      -- { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "…" },
      -- Telescope history (needs telescope; optional):
      -- { "<leader>py", function() require("telescope").extensions.yank_history.yank_history({}) end, desc = "Yank history" },
    },
  },
}
