--------------------------------------------------------------------------------
-- which-key: discover pending keybinds after a prefix (e.g. <leader>)
-- Refs: Kickstart (delay 0 + spec groups); CodeOSS ui.lua (delay 300 + groups).
-- LazyVim ships which-key in the distro; starter repo often has no local spec.
-- Alt: skip and use docs/KEYMAPS.md only · or mini.clue (lighter).
--------------------------------------------------------------------------------

return {
  {
    "folke/which-key.nvim",
    -- When to load.
    event = "VeryLazy", -- after UI start (usual)
    -- lazy = false, -- load at startup if you want the popup available immediately

    opts = {
      -- Delay (ms) before the popup appears after a prefix key.
      delay = 300, -- CodeOSS-ish; less flash during known chords
      -- delay = 0, -- Kickstart: show immediately

      -- Popup look (which-key v3 presets).
      preset = "classic", -- default folke layout
      -- preset = "modern", -- denser / newer look
      -- preset = "helix", -- Helix-inspired

      icons = {
        -- Mapping icons in the popup (needs a Nerd Font when true).
        mappings = vim.g.have_nerd_font, -- follow init.lua flag
        -- mappings = false, -- text-only labels
      },

      -- Group labels for prefixes (does not create maps — only names the folder).
      -- Actual maps stay in keymaps.lua / gitsigns on_attach with desc = "...".
      spec = {
        { "<leader>b", group = "Buffer" }, -- <leader>bd
        { "<leader>h", group = "Git hunk", mode = { "n", "v" } }, -- gitsigns <leader>h…
        { "<leader>f", group = "File/Find" }, -- neo-tree <leader>fe / fE
        { "<leader>g", group = "Git" }, -- neo-tree <leader>ge (git_status); expand later
        { "<leader>s", group = "Search", mode = { "n", "v" } }, -- telescope <leader>s…
        -- Future slices (uncomment when those maps exist):
        -- { "<leader>t", group = "Toggle" },
        -- { "gr", group = "LSP", mode = { "n" } },
      },
    },

    -- Optional: show buffer-local maps only (Kickstart-style helper).
    -- keys = {
    --   {
    --     "<leader>?",
    --     function()
    --       require("which-key").show({ global = false })
    --     end,
    --     desc = "Buffer local keymaps (which-key)",
    --   },
    -- },
  },
}
