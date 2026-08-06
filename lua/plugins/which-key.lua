--------------------------------------------------------------------------------
-- which-key: discover pending keybinds after a prefix (e.g. <leader>)
-- Refs: Kickstart (delay 0 + spec groups); CodeOSS ui.lua (delay 300 + groups).
-- LazyVim ships which-key in the distro; starter repo often has no local spec.
-- Alt: skip and use docs/keymaps/ only · or mini.clue (lighter).
--------------------------------------------------------------------------------

--- Make the popup readable on Noctis Bordo (classic is borderless + NormalFloat).
local function apply_which_key_hl()
  -- Slightly lifted panel vs editor bg0 (#312A2D); border tint for edge.
  vim.api.nvim_set_hl(0, "WhichKeyNormal", { fg = "#C9BEC2", bg = "#3C2F34" })
  -- vim.api.nvim_set_hl(0, "WhichKeyNormal", { link = "NormalFloat" }) -- blend with floats
  -- vim.api.nvim_set_hl(0, "WhichKeyNormal", { fg = "#C9BEC2", bg = "#2B2528" }) -- darker panel
  vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#D17B9A", bg = "#3C2F34" })
  -- vim.api.nvim_set_hl(0, "WhichKeyBorder", { link = "FloatBorder" })
  -- vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#7BE6AB", bg = "#3C2F34" }) -- green edge
  vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = "#F6C38A", bg = "#3C2F34", bold = true })
  -- vim.api.nvim_set_hl(0, "WhichKeyTitle", { link = "FloatTitle" })
end

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
      preset = "classic", -- full-width bottom strip
      -- preset = "modern", -- centered floating panel + rounded border
      -- preset = "helix", -- Helix-inspired side panel

      -- Classic defaults to border=none + short max; override for contrast + fewer scrolls.
      win = {
        no_overlap = false, -- don't shrink when near cursor (was cutting height)
        -- no_overlap = true, -- stock: keep clear of cursor line
        border = "rounded", -- edge so the strip isn't camouflaged
        -- border = "single",
        -- border = "double",
        -- border = "none", -- classic stock (hard to see on Bordo)
        title = true,
        title_pos = "center",
        -- title = false,
        height = { min = 6, max = 0.45 }, -- up to ~45% of screen; less ^D/^U
        -- height = { min = 4, max = 25 }, -- classic stock (line cap)
        -- height = { min = 8, max = math.huge }, -- grow to fit when possible
        -- height = { min = 4, max = 0.75 }, -- helix-style tall panel
        padding = { 1, 2 },
        -- padding = { 0, 1 }, -- tighter
        wo = {
          winblend = 0, -- opaque panel (readable over code)
          -- winblend = 10, -- slight see-through
        },
      },

      layout = {
        width = { min = 20 }, -- column min width
        -- width = { min = 12 }, -- denser columns → shorter popup, more scroll
        spacing = 3,
        -- spacing = 2,
      },

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
        { "<leader>g", group = "Git" }, -- ge neo-tree · gg/gf lazygit
        { "<leader>s", group = "Search", mode = { "n", "v" } }, -- telescope <leader>s…
        { "<leader>S", group = "Salesforce", mode = { "n", "x" } }, -- sf.nvim <leader>S… (capital S)
        { "<leader>c", group = "Code" }, -- <leader>cf format, <leader>cl lint, <leader>ca action
        { "<leader>d", group = "Delete (black hole)", mode = { "n", "v" } }, -- "_d / "_D
        { "<leader>t", group = "Toggle" }, -- tf FoS · tl autolint · th inlays · tb blame
        { "<leader>q", group = "Session" }, -- persistence qs/qS/ql/qd
        { "<leader>x", group = "Trouble" }, -- diagnostics / lists panel
        { "<leader>u", group = "Undotree" }, -- undotree toggle
        { "gc", group = "Comment line", mode = { "n", "v" } }, -- Comment.nvim
        { "gb", group = "Comment block", mode = { "n", "v" } }, -- Comment.nvim
        { "gs", group = "Flash jump" }, -- flash.nvim (gS = treesitter)
        { "s", group = "Split / window" }, -- ss/sv splits · sh/sj/sk/sl focus
        -- { "gr", group = "LSP", mode = { "n" } },
      },
    },

    config = function(_, opts)
      require("which-key").setup(opts)
      apply_which_key_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("which_key_hl", { clear = true }),
        callback = apply_which_key_hl,
      })
    end,

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
