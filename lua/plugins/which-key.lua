--------------------------------------------------------------------------------
-- which-key: discover pending keybinds after a prefix (e.g. <leader>)
-- Refs: Kickstart (delay 0 + spec groups); CodeOSS ui.lua (delay 300 + icons).
-- LazyVim ships which-key in the distro; starter repo often has no local spec.
-- Alt: skip and use docs/keymaps/ only · or mini.clue (lighter).
--------------------------------------------------------------------------------

--- Distinct panel vs editor; classic preset is otherwise NormalFloat-camouflaged.
local function apply_which_key_hl()
  local chrome = require("config.ui_chrome")
  local bg, fg = chrome.panel_bg, chrome.panel_fg
  vim.api.nvim_set_hl(0, "WhichKeyNormal", { fg = fg, bg = bg })
  -- vim.api.nvim_set_hl(0, "WhichKeyNormal", { link = "NormalFloat" }) -- blend with floats
  vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = chrome.border_fg, bg = bg })
  -- vim.api.nvim_set_hl(0, "WhichKeyBorder", { link = "FloatBorder" })
  vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = chrome.title_fg, bg = bg, bold = true })
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

        -- Color families (paired opposites share a color; glyphs differ per action):
        --   orange  Git (LazyGit, hunks, blame, diff)
        --   blue    Salesforce
        --   green   Search / find / Telescope / TODO
        --   cyan    Buffer + window / split / focus
        --   azure   File explorer + sessions
        --   purple  Code / LSP / format / lint / yank / undotree
        --   yellow  Toggle + dial + flash
        --   red     Delete / Trouble / diagnostics jumps
        --   grey    Comment
        -- Avoid catch-all `plugin = "…"` for multi-key plugins — that paints every
        -- key the same before desc patterns run. Specific patterns first.
        rules = {
          ------------------------------------------------------------------ Git (orange)
          { pattern = "lazygit %(current file%)", icon = "󰈙", color = "orange" },
          { pattern = "lazygit", icon = "", color = "orange" },
          { pattern = "toggle git status explorer", icon = "󰊢", color = "orange" },
          { pattern = "next git hunk", icon = "󰁔", color = "orange" },
          { pattern = "previous git hunk", icon = "󰁍", color = "orange" },
          { pattern = "stage selected hunk", icon = "󰐕", color = "orange" },
          { pattern = "reset selected hunk", icon = "󰜺", color = "orange" },
          { pattern = "stage hunk", icon = "󰐕", color = "orange" },
          { pattern = "reset hunk", icon = "󰛧", color = "orange" },
          { pattern = "stage buffer", icon = "󰐖", color = "orange" },
          { pattern = "reset buffer", icon = "󰕍", color = "orange" },
          { pattern = "preview hunk", icon = "󰈈", color = "orange" },
          { pattern = "blame line", icon = "󰍕", color = "orange" },
          { pattern = "diff against index", icon = "󰦓", color = "orange" },
          { pattern = "select git hunk", icon = "󰒉", color = "orange" },
          { pattern = "toggle line blame", icon = "󰍕", color = "orange" },
          { pattern = "%f[%a]git", icon = "", color = "orange" },

          ---------------------------------------------------------- Salesforce (blue)
          { pattern = "sf: fetch org", icon = "󰄨", color = "blue" },
          { pattern = "sf: set target org", icon = "󰷏", color = "blue" },
          { pattern = "sf: set global org", icon = "󰖟", color = "blue" },
          { pattern = "sf: open org in browser", icon = "󰖟", color = "blue" },
          { pattern = "sf: open current metadata", icon = "󰈙", color = "blue" },
          { pattern = "sf: retrieve", icon = "󰇚", color = "blue" },
          { pattern = "sf: diff", icon = "󰦓", color = "blue" },
          { pattern = "sf: pull debug log", icon = "󰌱", color = "blue" },
          { pattern = "sf: toggle terminal", icon = "", color = "blue" },
          { pattern = "sf: hide terminal", icon = "󰖐", color = "blue" },
          { pattern = "sf: cancel", icon = "󰜺", color = "blue" },
          { pattern = "sf: save and deploy", icon = "󰅧", color = "blue" },
          { pattern = "sf: test under cursor %+ coverage", icon = "󰝖", color = "blue" },
          { pattern = "sf: test under cursor", icon = "󰙨", color = "blue" },
          { pattern = "sf: all tests in file %+ coverage", icon = "󰝖", color = "blue" },
          { pattern = "sf: all tests in file", icon = "󰙨", color = "blue" },
          { pattern = "sf: repeat last tests", icon = "󰑖", color = "blue" },
          { pattern = "sf: toggle coverage signs", icon = "󰍕", color = "blue" },
          { pattern = "sf: previous uncovered", icon = "󰁍", color = "blue" },
          { pattern = "sf: next uncovered", icon = "󰁔", color = "blue" },
          { pattern = "sf: run selected soql", icon = "󰆼", color = "blue" },
          { pattern = "sf: pull metadata inventory", icon = "󰉓", color = "blue" },
          { pattern = "sf: list metadata to retrieve", icon = "󰉓", color = "blue" },
          { pattern = "sf: pull metadata types", icon = "󰀫", color = "blue" },
          { pattern = "sf: list metadata types", icon = "󰀫", color = "blue" },
          { pattern = "sf: refresh sobject", icon = "󰓅", color = "blue" },
          { pattern = "sf: create apex ctags", icon = "󰓻", color = "blue" },
          { pattern = "^sf:", icon = "󰢎", color = "blue" },
          { pattern = "salesforce", icon = "󰢎", color = "blue" },

          ------------------------------------------------------------- Search (green)
          { pattern = "search help", icon = "󰋖", color = "green" },
          { pattern = "search keymaps", icon = "󰌌", color = "green" },
          { pattern = "search files", icon = "󰈞", color = "green" },
          { pattern = "search select telescope", icon = "", color = "green" },
          { pattern = "search current word", icon = "󰓡", color = "green" },
          { pattern = "search by grep", icon = "󰈲", color = "green" },
          { pattern = "search diagnostics", icon = "󱖫", color = "green" },
          { pattern = "search resume", icon = "󰐊", color = "green" },
          { pattern = "search commands", icon = "󰘳", color = "green" },
          { pattern = "search recent files", icon = "󰋚", color = "green" },
          { pattern = "search in open files", icon = "󰈙", color = "green" },
          { pattern = "search neovim config", icon = "", color = "green" },
          { pattern = "search todo", icon = "󱅊", color = "green" },
          { pattern = "fuzzy search current buffer", icon = "󰈔", color = "green" },
          { pattern = "find buffers", icon = "󰓩", color = "green" },
          { pattern = "next todo", icon = "󰒭", color = "green" },
          { pattern = "previous todo", icon = "󰒮", color = "green" },
          { pattern = "next search result", icon = "󰒭", color = "green" },
          { pattern = "previous search result", icon = "󰒮", color = "green" },
          { pattern = "clear search highlight", icon = "󰛑", color = "green" },
          { pattern = "todo", icon = "󱅊", color = "green" },
          { pattern = "search", icon = "", color = "green" },
          { pattern = "find", icon = "", color = "green" },
          { pattern = "telescope", icon = "", color = "green" },

          --------------------------------------------------------------- Toggle (yellow)
          -- Before generic format/lint/flash so toggle maps stay in this family.
          { pattern = "toggle format on save", icon = "", color = "yellow" },
          { pattern = "toggle auto%-lint", icon = "󱉶", color = "yellow" },
          { pattern = "toggle inlay", icon = "󰔢", color = "yellow" },
          { pattern = "toggle flash search", icon = "⚡", color = "yellow" },
          { pattern = "toggle file explorer", icon = "󰙅", color = "azure" }, -- explorer family
          { pattern = "dial additive increment", icon = "󰐖", color = "yellow" },
          { pattern = "dial additive decrement", icon = "󰍴", color = "yellow" },
          { pattern = "dial increment", icon = "󰐖", color = "yellow" },
          { pattern = "dial decrement", icon = "󰍴", color = "yellow" },
          { pattern = "flash treesitter", icon = "󰌪", color = "yellow" },
          { pattern = "remote flash", icon = "󰑮", color = "yellow" },
          { pattern = "treesitter search", icon = "󰔱", color = "yellow" },
          { pattern = "flash jump", icon = "⚡", color = "yellow" },
          { pattern = "flash", icon = "⚡", color = "yellow" },
          { pattern = "dial", icon = "󰐖", color = "yellow" },
          { pattern = "increment", icon = "󰐖", color = "yellow" },
          { pattern = "decrement", icon = "󰍴", color = "yellow" },
          { pattern = "toggle", icon = "", color = "yellow" },

          ------------------------------------------------ File explorer + sessions (azure)
          { pattern = "reveal current file in explorer", icon = "󰈙", color = "azure" },
          { pattern = "session restore %(cwd%)", icon = "󰦛", color = "azure" },
          { pattern = "session restore %(last%)", icon = "󰋚", color = "azure" },
          { pattern = "session select", icon = "󰒓", color = "azure" },
          { pattern = "session don't save", icon = "󰩺", color = "azure" },
          { pattern = "explorer", icon = "󰙅", color = "azure" },
          { pattern = "session", icon = "", color = "azure" },

          ------------------------------------------- Code / LSP / yank / undo (purple)
          { pattern = "format buffer", icon = "", color = "purple" },
          { pattern = "lint current buffer", icon = "󱉶", color = "purple" },
          { pattern = "lsp: hover", icon = "󰋽", color = "purple" },
          { pattern = "lsp: go to declaration", icon = "󰳽", color = "purple" },
          { pattern = "lsp: go to definition", icon = "󰳽", color = "purple" },
          { pattern = "lsp: go to implementation", icon = "󰡕", color = "purple" },
          { pattern = "lsp: type definition", icon = "󰊕", color = "purple" },
          { pattern = "lsp: rename", icon = "󰑕", color = "purple" },
          { pattern = "lsp: code action", icon = "󰌵", color = "purple" },
          { pattern = "lsp: references", icon = "󰈇", color = "purple" },
          { pattern = "lsp: document symbols", icon = "󰈙", color = "purple" },
          { pattern = "lsp: workspace symbols", icon = "󰒓", color = "purple" },
          { pattern = "lsp:", icon = "", color = "purple" },
          { pattern = "code action", icon = "󰌵", color = "purple" },
          { pattern = "yanky yank", icon = "󰆏", color = "purple" },
          { pattern = "yanky put after", icon = "󰆒", color = "purple" },
          { pattern = "yanky put before", icon = "󰆑", color = "purple" },
          { pattern = "yanky gput after", icon = "󰆒", color = "purple" },
          { pattern = "yanky gput before", icon = "󰆑", color = "purple" },
          { pattern = "yanky previous entry", icon = "󰒮", color = "purple" },
          { pattern = "yanky next entry", icon = "󰒭", color = "purple" },
          { pattern = "yanky", icon = "󰅇", color = "purple" },
          { pattern = "undotree", icon = "󰕌", color = "purple" },
          { pattern = "format", icon = "", color = "purple" },
          { pattern = "lint", icon = "󱉶", color = "purple" },
          { pattern = "rename", icon = "󰑕", color = "purple" },
          { pattern = "hover", icon = "󰋽", color = "purple" },
          { pattern = "definition", icon = "󰳽", color = "purple" },
          { pattern = "declaration", icon = "󰳽", color = "purple" },
          { pattern = "implementation", icon = "󰡕", color = "purple" },
          { pattern = "references", icon = "󰈇", color = "purple" },
          { pattern = "symbol", icon = "", color = "purple" },
          { pattern = "code", icon = "", color = "purple" },

          ------------------------------------ Delete / Trouble / diagnostics (red)
          { pattern = "delete to eol", icon = "󰆴", color = "red" },
          { pattern = "delete char", icon = "󰛌", color = "red" },
          { pattern = "delete buffer", icon = "󰅖", color = "red" },
          { pattern = "black hole", icon = "󰩹", color = "red" },
          { pattern = "delete", icon = "󰩹", color = "red" },
          { pattern = "buffer diagnostics %(trouble%)", icon = "󰈔", color = "red" },
          { pattern = "diagnostics %(trouble%)", icon = "󱖫", color = "red" },
          { pattern = "symbols %(trouble%)", icon = "", color = "red" },
          { pattern = "location list %(trouble%)", icon = "󰍉", color = "red" },
          { pattern = "quickfix %(trouble%)", icon = "󰁨", color = "red" },
          { pattern = "next diagnostic", icon = "󰁔", color = "red" },
          { pattern = "previous diagnostic", icon = "󰁍", color = "red" },
          { pattern = "show diagnostic", icon = "󰋽", color = "red" },
          { pattern = "trouble", icon = "󰔫", color = "red" },
          { pattern = "diagnostic", icon = "󱖫", color = "red" },
          { pattern = "quickfix", icon = "󱖫", color = "red" },
          { pattern = "location list", icon = "󱖫", color = "red" },

          -------------------------------------- Buffer + window / split (cyan)
          { pattern = "previous buffer", icon = "󰒮", color = "cyan" },
          { pattern = "next buffer", icon = "󰒭", color = "cyan" },
          { pattern = "split horizontal", icon = "󰤻", color = "cyan" },
          { pattern = "split vertical", icon = "󰤼", color = "cyan" },
          { pattern = "focus left window", icon = "󰁍", color = "cyan" },
          { pattern = "focus right window", icon = "󰁔", color = "cyan" },
          { pattern = "focus lower window", icon = "󰁅", color = "cyan" },
          { pattern = "focus upper window", icon = "󰁝", color = "cyan" },
          { pattern = "half page down", icon = "󰁅", color = "cyan" },
          { pattern = "half page up", icon = "󰁝", color = "cyan" },
          { pattern = "move selection down", icon = "󰁅", color = "cyan" },
          { pattern = "move selection up", icon = "󰁝", color = "cyan" },
          { pattern = "buffer", icon = "󰈔", color = "cyan" },
          { pattern = "split", icon = "", color = "cyan" },
          { pattern = "window", icon = "", color = "cyan" },
          { pattern = "focus", icon = "", color = "cyan" },

          ---------------------------------------------------------- Comment (grey)
          { pattern = "comment line", icon = "󰆈", color = "grey" },
          { pattern = "comment block", icon = "󰅺", color = "grey" },
          { pattern = "comment", icon = "󰅺", color = "grey" },

          -------------------------------------------------------------- Misc
          { pattern = "exit terminal mode", icon = "", color = "red" },
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
