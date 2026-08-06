--------------------------------------------------------------------------------
-- which-key: discover pending keybinds after a prefix (e.g. <leader>)
-- Refs: Kickstart (delay 0 + spec groups); CodeOSS ui.lua (delay 300 + groups).
-- LazyVim ships which-key in the distro; starter repo often has no local spec.
-- Alt: skip and use docs/keymaps/ only · or mini.clue (lighter).
--------------------------------------------------------------------------------

--- Distinct panel vs editor; classic preset is otherwise NormalFloat-camouflaged.
local function apply_which_key_hl()
  local bg = "#000000" -- solid black panel
  -- local bg = "#0a0a0a" -- near-black
  -- local bg = "#3C2F34" -- Bordo float (bg1) — previous lifted panel
  -- local bg = "#2B2528" -- darker Bordo (bg2)
  vim.api.nvim_set_hl(0, "WhichKeyNormal", { fg = "#C9BEC2", bg = bg })
  -- vim.api.nvim_set_hl(0, "WhichKeyNormal", { link = "NormalFloat" }) -- blend with floats
  vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#D17B9A", bg = bg })
  -- vim.api.nvim_set_hl(0, "WhichKeyBorder", { link = "FloatBorder" })
  -- vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#7BE6AB", bg = bg }) -- green edge
  vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = "#F6C38A", bg = bg, bold = true })
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
        -- colors = false, -- monochrome icons

        -- Color families (same action + its reverse share a color):
        --   orange  Git brand (logo, hunks, LazyGit, blame) — exception
        --   blue    Salesforce brand — exception
        --   green   Search / find / Telescope / TODO search
        --   cyan    Buffer + window / split / focus (nav chrome)
        --   azure   File explorer + sessions (workspace)
        --   purple  Code / LSP / format / lint / yank / undotree
        --   yellow  Toggle + dial (inc/dec) + flash jump
        --   red     Delete / Trouble / diagnostics lists
        --   grey    Comment
        -- Checked before which-key’s built-in rules. Children inherit the group
        -- icon/color when nothing more specific matches.
        rules = {
          -- Brand / plugin (keep logo colors).
          { plugin = "sf.nvim", icon = "󰢎", color = "blue" },
          { plugin = "lazygit.nvim", icon = "", color = "orange" },
          { pattern = "^sf:", icon = "󰢎", color = "blue" },
          { pattern = "salesforce", icon = "󰢎", color = "blue" },
          { pattern = "lazygit", icon = "", color = "orange" },
          { pattern = "hunk", icon = "󰊢", color = "orange" },
          { pattern = "blame", icon = "󰊢", color = "orange" },
          { pattern = "%f[%a]git", icon = "", color = "orange" },

          -- Search / find (next/prev search, Telescope, TODOs).
          { plugin = "telescope.nvim", icon = "", color = "green" },
          { plugin = "todo-comments.nvim", icon = "󱅊", color = "green" },
          { pattern = "search", icon = "", color = "green" },
          { pattern = "find", icon = "", color = "green" },
          { pattern = "todo", icon = "󱅊", color = "green" },
          { pattern = "telescope", icon = "", color = "green" },

          -- Buffer + window / split / focus (pairs share cyan).
          { pattern = "buffer", icon = "󰈔", color = "cyan" },
          { pattern = "split", icon = "", color = "cyan" },
          { pattern = "window", icon = "", color = "cyan" },
          { pattern = "focus", icon = "", color = "cyan" },

          -- Explorer + sessions (workspace).
          { plugin = "neo-tree.nvim", icon = "󰙅", color = "azure" },
          { plugin = "persistence.nvim", icon = "", color = "azure" },
          { pattern = "explorer", icon = "󰙅", color = "azure" },
          { pattern = "session", icon = "", color = "azure" },

          -- Code / LSP / format / lint / yank / undo (edit tools).
          { plugin = "conform.nvim", icon = "", color = "purple" },
          { plugin = "nvim-lint", icon = "󱉶", color = "purple" },
          { plugin = "yanky.nvim", icon = "󰅇", color = "purple" },
          { plugin = "undotree", icon = "󰕌", color = "purple" },
          { pattern = "format", icon = "", color = "purple" },
          { pattern = "lint", icon = "󱉶", color = "purple" },
          { pattern = "lsp:", icon = "", color = "purple" },
          { pattern = "code", icon = "", color = "purple" },
          { pattern = "rename", icon = "󰑕", color = "purple" },
          { pattern = "hover", icon = "󰋽", color = "purple" },
          { pattern = "definition", icon = "󰳽", color = "purple" },
          { pattern = "declaration", icon = "󰳽", color = "purple" },
          { pattern = "implementation", icon = "󰡕", color = "purple" },
          { pattern = "references", icon = "󰈇", color = "purple" },
          { pattern = "symbol", icon = "", color = "purple" },
          { pattern = "yanky", icon = "󰅇", color = "purple" },
          { pattern = "undotree", icon = "󰕌", color = "purple" },

          -- Toggle + dial (inc/dec) + flash (jump variants) — yellow family.
          { plugin = "flash.nvim", icon = "⚡", color = "yellow" },
          { plugin = "dial.nvim", icon = "󰐖", color = "yellow" },
          { pattern = "toggle", icon = "", color = "yellow" },
          { pattern = "flash", icon = "⚡", color = "yellow" },
          { pattern = "dial", icon = "󰐖", color = "yellow" },
          { pattern = "inlay", icon = "󰔢", color = "yellow" },
          { pattern = "increment", icon = "󰐖", color = "yellow" },
          { pattern = "decrement", icon = "󰍴", color = "yellow" },

          -- Delete / Trouble / diagnostics (problem lists).
          { plugin = "trouble.nvim", icon = "󰔫", color = "red" },
          { pattern = "trouble", icon = "󰔫", color = "red" },
          { pattern = "black hole", icon = "󰩹", color = "red" },
          { pattern = "delete", icon = "󰩹", color = "red" },
          { pattern = "diagnostic", icon = "󱖫", color = "red" },
          { pattern = "quickfix", icon = "󱖫", color = "red" },
          { pattern = "location list", icon = "󱖫", color = "red" },

          -- Comment line / block (same grey).
          { pattern = "comment", icon = "󰅺", color = "grey" },
        },
      },

      -- Group labels for prefixes (does not create maps — only names the folder).
      -- Actual maps stay in keymaps.lua / gitsigns on_attach with desc = "...".
      -- `icon` on a group paints the folder and is inherited by children with no
      -- more-specific plugin/pattern match (see icons.rules above).
      spec = {
        { "<leader>b", group = "Buffer", icon = { icon = "󰈔", color = "cyan" } }, -- <leader>bd
        { "<leader>h", group = "Git hunk", mode = { "n", "v" }, icon = { icon = "󰊢", color = "orange" } }, -- gitsigns
        { "<leader>f", group = "File/Find", icon = { icon = "󰙅", color = "azure" } }, -- neo-tree fe / fE
        { "<leader>g", group = "Git", icon = { icon = "", color = "orange" } }, -- ge · gg/gf lazygit
        { "<leader>s", group = "Search", mode = { "n", "v" }, icon = { icon = "", color = "green" } }, -- telescope
        { "<leader>S", group = "Salesforce", mode = { "n", "x" }, icon = { icon = "󰢎", color = "blue" } }, -- sf.nvim
        { "<leader>c", group = "Code", icon = { icon = "", color = "purple" } }, -- cf / cl / ca
        { "<leader>d", group = "Delete (black hole)", mode = { "n", "v" }, icon = { icon = "󰩹", color = "red" } }, -- "_d
        { "<leader>t", group = "Toggle", icon = { icon = "", color = "yellow" } }, -- tf · tl · th · tb
        { "<leader>q", group = "Session", icon = { icon = "", color = "azure" } }, -- persistence
        { "<leader>x", group = "Trouble", icon = { icon = "󰔫", color = "red" } }, -- diagnostics panel
        { "<leader>u", group = "Undotree", icon = { icon = "󰕌", color = "purple" } }, -- undotree toggle
        { "gc", group = "Comment line", mode = { "n", "v" }, icon = { icon = "󰅺", color = "grey" } }, -- Comment.nvim
        { "gb", group = "Comment block", mode = { "n", "v" }, icon = { icon = "󰅺", color = "grey" } }, -- Comment.nvim
        { "gs", group = "Flash jump", icon = { icon = "⚡", color = "yellow" } }, -- flash (gS = treesitter)
        { "s", group = "Split / window", icon = { icon = "", color = "cyan" } }, -- ss/sv · sh/sj/sk/sl
        -- { "gr", group = "LSP", mode = { "n" }, icon = { icon = "", color = "purple" } },
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
