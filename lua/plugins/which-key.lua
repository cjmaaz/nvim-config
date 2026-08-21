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
  vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = chrome.divider_fg, bg = bg })
  -- vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = chrome.border_fg, bg = bg }) -- rose border
  vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = chrome.title_fg, bg = bg, bold = true })
  -- vim.api.nvim_set_hl(0, "WhichKeyTitle", { link = "FloatTitle" })
  vim.api.nvim_set_hl(0, "WhichKey", { fg = chrome.divider_fg, bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = chrome.border_fg, bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = chrome.muted_fg, bg = bg })
  vim.api.nvim_set_hl(0, "WhichKeyValue", { fg = chrome.muted_fg, bg = bg })
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    -- lazy = false,

    opts = {
      delay = 300,
      -- delay = 0,

      -- Hide the normal-buffer half-page maps from which-key's tree so its
      -- popup state can consume the same keys for scrolling.
      filter = function(mapping)
        local lhs = (mapping.lhs or ""):upper()
        return lhs ~= "<C-D>" and lhs ~= "<C-U>"
      end,
      -- filter = function() return true end, -- show every mapping (C-d/u then close the popup)

      keys = {
        scroll_down = "<c-d>",
        scroll_up = "<c-u>",
      },
      -- keys = { scroll_down = "<c-f>", scroll_up = "<c-b>" }, -- alternate with no tree filtering

      preset = "classic",
      -- preset = "modern",
      -- preset = "helix",

      win = {
        no_overlap = false,
        -- no_overlap = true,
        border = "rounded",
        -- border = "single",
        -- border = "none",
        title = true,
        title_pos = "center",
        height = { min = 6, max = 0.50 },
        -- height = { min = 6, max = 0.45 }, -- slightly shorter popup
        -- height = { min = 4, max = 25 },
        padding = { 1, 2 },
        wo = {
          winblend = 0,
          -- winblend = 10,
        },
      },

      layout = {
        -- Let columns fit their longest label so descriptions are not ellipsized.
        width = { min = 20 },
        -- width = { min = 20, max = 40 }, -- more columns, but long labels truncate
        -- width = { min = 20, max = 50 }, -- less truncation, fewer columns
        spacing = 3,
        -- spacing = 2,
      },

      icons = {
        mappings = vim.g.have_nerd_font,
        -- mappings = false,
        -- colors = false,

        -- Color = related-action family (NOT whole leader group).
        -- Same/similar/paired-opposite → same color, different glyph.
        -- Unrelated under one prefix (e.g. <leader>c format vs lint vs action)
        -- → different colors.
        -- Specific patterns first; avoid catch-all plugin rules for multi-key plugins.
        rules = {
          ------------------------------------------------------------ SF families
          -- Org / open (So SO Sb SB SF fetch) → blue
          { pattern = "sf: fetch org", icon = "󰄨", color = "blue" },
          { pattern = "sf: set target org", icon = "󰷏", color = "blue" },
          { pattern = "sf: set global org", icon = "󰖟", color = "blue" },
          { pattern = "sf: open org in browser", icon = "󰖟", color = "blue" },
          { pattern = "sf: open current metadata", icon = "󰈙", color = "blue" },

          -- Retrieve / metadata inventory (Sr Sm SM Sk SK Su SU) → azure
          { pattern = "sf: retrieve", icon = "󰇚", color = "azure" },
          { pattern = "sf: pull metadata inventory", icon = "󰉓", color = "azure" },
          { pattern = "sf: list metadata to retrieve", icon = "󰉓", color = "azure" },
          { pattern = "sf: pull metadata types", icon = "󰀫", color = "azure" },
          { pattern = "sf: list metadata types", icon = "󰀫", color = "azure" },
          { pattern = "sf: browse metadata", icon = "󰉓", color = "azure" },
          { pattern = "sf: update metadata browser", icon = "󰓅", color = "azure" },
          { pattern = "sf: browse package manifests", icon = "󰈙", color = "azure" },
          { pattern = "sf: retrieve vlocity datapacks", icon = "󰇚", color = "azure" },

          -- SOQL builder / runner → yellow
          { pattern = "sf: build soql query", icon = "󰆼", color = "yellow" },
          { pattern = "sf: run soql", icon = "󰆼", color = "yellow" },

          -- Tests / coverage (St ST Sa SA SR Sv ]v [v) → green
          { pattern = "sf: test under cursor %+ coverage", icon = "󰝖", color = "green" },
          { pattern = "sf: test under cursor", icon = "󰙨", color = "green" },
          { pattern = "sf: all tests in file %+ coverage", icon = "󰝖", color = "green" },
          { pattern = "sf: all tests in file", icon = "󰙨", color = "green" },
          { pattern = "sf: repeat last tests", icon = "󰑖", color = "green" },
          { pattern = "sf: toggle coverage signs", icon = "󰍕", color = "green" },
          { pattern = "sf: previous uncovered", icon = "󰁍", color = "green" },
          { pattern = "sf: next uncovered", icon = "󰁔", color = "green" },

          -- Deploy → purple · diff → orange · log → yellow · term → cyan · cancel → red
          { pattern = "sf: save and deploy", icon = "󰅧", color = "purple" },
          { pattern = "sf: diff", icon = "󰦓", color = "orange" },
          { pattern = "sf: pull debug log", icon = "󰌱", color = "yellow" },
          { pattern = "sf: toggle terminal", icon = "", color = "cyan" },
          { pattern = "sf: hide terminal", icon = "󰖐", color = "cyan" },
          { pattern = "sf: cancel", icon = "󰜺", color = "red" },
          { pattern = "sf: run selected soql", icon = "󰆼", color = "yellow" },
          { pattern = "sf: refresh sobject", icon = "󰓅", color = "grey" },
          { pattern = "sf: create apex ctags", icon = "󰓻", color = "grey" },
          { pattern = "^sf:", icon = "󰢎", color = "blue" }, -- leftover SF
          { pattern = "salesforce", icon = "󰢎", color = "blue" },

          -------------------------------------------------------- Search families
          -- Files → green · text/grep → azure · meta pickers → cyan · diag → red · todo → yellow
          { pattern = "search files", icon = "󰈞", color = "green" },
          { pattern = "search recent files", icon = "󰋚", color = "green" },
          { pattern = "search neovim config", icon = "", color = "green" },
          { pattern = "search in open files", icon = "󰈙", color = "azure" },
          { pattern = "search by grep", icon = "󰈲", color = "azure" },
          { pattern = "search multi%-grep", icon = "󰛢", color = "azure" },
          { pattern = "search current word", icon = "󰓡", color = "azure" },
          { pattern = "fuzzy search current buffer", icon = "󰈔", color = "azure" },
          { pattern = "search plugin packages", icon = "󰏖", color = "green" },
          { pattern = "search help", icon = "󰋖", color = "cyan" },
          { pattern = "search keymaps", icon = "󰌌", color = "cyan" },
          { pattern = "search commands", icon = "󰘳", color = "cyan" },
          { pattern = "search select telescope", icon = "", color = "cyan" },
          { pattern = "search resume", icon = "󰐊", color = "cyan" },
          { pattern = "find buffers", icon = "󰓩", color = "cyan" },
          { pattern = "search diagnostics", icon = "󱖫", color = "red" },
          { pattern = "search todo", icon = "󱅊", color = "yellow" },
          { pattern = "next todo", icon = "󰒭", color = "yellow" },
          { pattern = "previous todo", icon = "󰒮", color = "yellow" },
          { pattern = "next search result", icon = "󰒭", color = "green" },
          { pattern = "previous search result", icon = "󰒮", color = "green" },
          { pattern = "clear search highlight", icon = "󰛑", color = "green" },
          { pattern = "todo", icon = "󱅊", color = "yellow" },
          { pattern = "search", icon = "", color = "green" },
          { pattern = "find", icon = "", color = "green" },
          { pattern = "telescope", icon = "", color = "cyan" },

          ---------------------------------------------- Code prefix (unrelated → split)
          -- <leader>cf / cl / ca are different jobs → different colors
          { pattern = "format buffer", icon = "", color = "cyan" },
          { pattern = "toggle format on save", icon = "", color = "cyan" },
          { pattern = "lint current buffer", icon = "󱉶", color = "yellow" },
          { pattern = "toggle auto%-lint", icon = "󱉶", color = "yellow" },
          { pattern = "lsp: code action", icon = "󰌵", color = "purple" },
          { pattern = "code action", icon = "󰌵", color = "purple" },

          ----------------------------------------------------------------- LSP nav
          { pattern = "lsp: hover", icon = "󰋽", color = "azure" },
          { pattern = "lsp: go to declaration", icon = "󰳽", color = "blue" },
          { pattern = "lsp: go to definition", icon = "󰳽", color = "blue" },
          { pattern = "lsp: go to implementation", icon = "󰡕", color = "blue" },
          { pattern = "lsp: type definition", icon = "󰊕", color = "blue" },
          { pattern = "lsp: rename", icon = "󰑕", color = "orange" },
          { pattern = "lsp: references", icon = "󰈇", color = "cyan" },
          { pattern = "lsp: document symbols", icon = "󰈙", color = "purple" },
          { pattern = "lsp: workspace symbols", icon = "󰒓", color = "purple" },
          { pattern = "toggle inlay", icon = "󰔢", color = "yellow" },
          { pattern = "lsp:", icon = "", color = "purple" },
          { pattern = "pick symbols in winbar", icon = "󰒓", color = "cyan" },
          { pattern = "go to start of current context", icon = "󰁍", color = "azure" },
          { pattern = "select next context", icon = "󰁔", color = "azure" },

          ------------------------------------------------------------------- Git
          { pattern = "lazygit %(current file%)", icon = "󰈙", color = "orange" },
          { pattern = "lazygit", icon = "", color = "orange" },
          { pattern = "toggle git status explorer", icon = "󰊢", color = "orange" },
          { pattern = "next git hunk", icon = "󰁔", color = "orange" },
          { pattern = "previous git hunk", icon = "󰁍", color = "orange" },
          { pattern = "stage selected hunk", icon = "󰐕", color = "green" },
          { pattern = "stage hunk", icon = "󰐕", color = "green" },
          { pattern = "stage buffer", icon = "󰐖", color = "green" },
          { pattern = "reset selected hunk", icon = "󰜺", color = "red" },
          { pattern = "reset hunk", icon = "󰛧", color = "red" },
          { pattern = "reset buffer", icon = "󰕍", color = "red" },
          { pattern = "preview hunk", icon = "󰈈", color = "azure" },
          { pattern = "blame line", icon = "󰍕", color = "yellow" },
          { pattern = "toggle line blame", icon = "󰍕", color = "yellow" },
          { pattern = "diff against index", icon = "󰦓", color = "cyan" },
          { pattern = "select git hunk", icon = "󰒉", color = "orange" },
          { pattern = "%f[%a]git", icon = "", color = "orange" },

          ------------------------------------------- ]/[ families (a/A · b/B · …)
          -- Buffer family (]b [b ]B [B) → cyan · argument family (]a [a ]A [A) → azure
          { pattern = "next buffer", icon = "󰒭", color = "cyan" },
          { pattern = "previous buffer", icon = "󰒮", color = "cyan" },
          { pattern = "last buffer", icon = "󰒭", color = "cyan" },
          { pattern = "first buffer", icon = "󰒮", color = "cyan" },
          { pattern = "next argument", icon = "󰒭", color = "azure" },
          { pattern = "previous argument", icon = "󰒮", color = "azure" },
          { pattern = "last argument", icon = "󰒭", color = "azure" },
          { pattern = "first argument", icon = "󰒮", color = "azure" },
          { pattern = "next diagnostic", icon = "󰁔", color = "red" },
          { pattern = "previous diagnostic", icon = "󰁍", color = "red" },
          { pattern = "show diagnostic", icon = "󰋽", color = "red" },
          { pattern = "next misspelled", icon = "", color = "yellow" },
          { pattern = "previous misspelled", icon = "", color = "yellow" },
          { pattern = "next method", icon = "󰊕", color = "purple" },
          { pattern = "previous method", icon = "󰊕", color = "purple" },
          { pattern = "next unmatched", icon = "󰅪", color = "grey" },
          { pattern = "previous unmatched", icon = "󰅪", color = "grey" },
          { pattern = "next %(", icon = "󰅲", color = "grey" },
          { pattern = "previous %(", icon = "󰅲", color = "grey" },
          { pattern = "next <", icon = "󰅲", color = "grey" },
          { pattern = "previous <", icon = "󰅲", color = "grey" },
          { pattern = "next {", icon = "󰅲", color = "grey" },
          { pattern = "previous {", icon = "󰅲", color = "grey" },

          ------------------------------------------------------- Motions (presets)
          -- word / WORD pairs share cyan; opposites (b/w, B/W) same family
          { pattern = "prev word", icon = "󰁍", color = "cyan" },
          { pattern = "next word", icon = "󰁔", color = "cyan" },
          { pattern = "prev WORD", icon = "󰁍", color = "azure" },
          { pattern = "next WORD", icon = "󰁔", color = "azure" },
          { pattern = "prev end of word", icon = "󰁍", color = "cyan" },
          { pattern = "next end of word", icon = "󰁔", color = "cyan" },
          { pattern = "prev end of WORD", icon = "󰁍", color = "azure" },
          { pattern = "next end of WORD", icon = "󰁔", color = "azure" },
          { pattern = "prev empty line", icon = "󰒮", color = "grey" },
          { pattern = "next empty line", icon = "󰒭", color = "grey" },
          { pattern = "^left$", icon = "󰁍", color = "cyan" },
          { pattern = "^right$", icon = "󰁔", color = "cyan" },
          { pattern = "^up$", icon = "󰁝", color = "cyan" },
          { pattern = "^down$", icon = "󰁅", color = "cyan" },

          -------------------------------------------------------------- Projects
          { pattern = "project: new scaffold", icon = "󰏗", color = "green" },
          { pattern = "project: run/build/test", icon = "󰐊", color = "green" },
          { pattern = "project", icon = "󰏗", color = "green" },

          -------------------------------------------------------------- Markdown
          { pattern = "markdown: toggle rendering", icon = "󰽛", color = "purple" },
          { pattern = "markdown: toggle side preview", icon = "󰈈", color = "purple" },

          ------------------------------------------------ Explorer / sessions
          { pattern = "toggle file explorer", icon = "󰙅", color = "azure" },
          { pattern = "reveal current file in explorer", icon = "󰈙", color = "azure" },
          { pattern = "session restore %(cwd%)", icon = "󰦛", color = "purple" },
          { pattern = "session restore %(last%)", icon = "󰋚", color = "purple" },
          { pattern = "session select", icon = "󰒓", color = "cyan" },
          { pattern = "session don't save", icon = "󰩺", color = "red" },
          { pattern = "explorer", icon = "󰙅", color = "azure" },
          { pattern = "session", icon = "", color = "purple" },

          ---------------------------------------------------------- Flash / dial
          { pattern = "flash treesitter", icon = "󰌪", color = "yellow" },
          { pattern = "remote flash", icon = "󰑮", color = "orange" },
          { pattern = "treesitter search", icon = "󰔱", color = "yellow" },
          { pattern = "toggle flash search", icon = "⚡", color = "yellow" },
          { pattern = "flash jump", icon = "⚡", color = "yellow" },
          { pattern = "flash", icon = "⚡", color = "yellow" },
          { pattern = "toggle gremlins tracker", icon = "󰀪", color = "orange" },
          { pattern = "gremlins quickfix", icon = "󰁨", color = "orange" },
          { pattern = "dial additive increment", icon = "󰐖", color = "green" },
          { pattern = "dial additive decrement", icon = "󰍴", color = "red" },
          { pattern = "dial increment", icon = "󰐖", color = "green" },
          { pattern = "dial decrement", icon = "󰍴", color = "red" },
          { pattern = "increment", icon = "󰐖", color = "green" },
          { pattern = "decrement", icon = "󰍴", color = "red" },

          --------------------------------------------------- Yank (put pairs)
          { pattern = "yanky yank", icon = "󰆏", color = "purple" },
          { pattern = "yanky put after", icon = "󰆒", color = "cyan" },
          { pattern = "yanky put before", icon = "󰆑", color = "cyan" },
          { pattern = "yanky gput after", icon = "󰆒", color = "azure" },
          { pattern = "yanky gput before", icon = "󰆑", color = "azure" },
          { pattern = "yanky previous entry", icon = "󰒮", color = "yellow" },
          { pattern = "yanky next entry", icon = "󰒭", color = "yellow" },
          { pattern = "yanky", icon = "󰅇", color = "purple" },

          ----------------------------------------------------------- Trouble
          { pattern = "buffer diagnostics %(trouble%)", icon = "󰈔", color = "red" },
          { pattern = "diagnostics %(trouble%)", icon = "󱖫", color = "red" },
          { pattern = "symbols %(trouble%)", icon = "", color = "purple" },
          { pattern = "location list %(trouble%)", icon = "󰍉", color = "azure" },
          { pattern = "quickfix %(trouble%)", icon = "󰁨", color = "yellow" },
          { pattern = "trouble", icon = "󰔫", color = "red" },

          ------------------------------------------------ Delete / black hole
          { pattern = "delete to eol", icon = "󰆴", color = "red" },
          { pattern = "delete char", icon = "󰛌", color = "red" },
          { pattern = "delete buffer", icon = "󰅖", color = "red" },
          { pattern = "black hole", icon = "󰩹", color = "red" },
          { pattern = "delete", icon = "󰩹", color = "red" },

          ---------------------------------------------- Window / split / focus
          { pattern = "split horizontal", icon = "󰤻", color = "cyan" },
          { pattern = "split vertical", icon = "󰤼", color = "cyan" },
          { pattern = "focus left window", icon = "󰁍", color = "azure" },
          { pattern = "focus right window", icon = "󰁔", color = "azure" },
          { pattern = "focus lower window", icon = "󰁅", color = "azure" },
          { pattern = "focus upper window", icon = "󰁝", color = "azure" },
          { pattern = "half page down", icon = "󰁅", color = "grey" },
          { pattern = "half page up", icon = "󰁝", color = "grey" },
          { pattern = "move selection down", icon = "󰁅", color = "orange" },
          { pattern = "move selection up", icon = "󰁝", color = "orange" },
          { pattern = "buffer", icon = "󰈔", color = "cyan" },
          { pattern = "split", icon = "", color = "cyan" },
          { pattern = "window", icon = "", color = "azure" },
          { pattern = "focus", icon = "", color = "azure" },

          ---------------------------------------------------------- Comment
          { pattern = "comment line", icon = "󰆈", color = "grey" },
          { pattern = "comment block", icon = "󰅺", color = "grey" },
          { pattern = "comment", icon = "󰅺", color = "grey" },

          -------------------------------------------------------------- Misc
          { pattern = "undotree", icon = "󰕌", color = "purple" },
          { pattern = "toggle", icon = "", color = "yellow" },
          { pattern = "format", icon = "", color = "cyan" },
          { pattern = "lint", icon = "󱉶", color = "yellow" },
          { pattern = "diagnostic", icon = "󱖫", color = "red" },
          { pattern = "exit terminal mode", icon = "", color = "red" },
        },
      },

      -- Group labels (folder icons only — child colors come from rules above).
      spec = {
        { "]", group = "Next", icon = { icon = "󰒭", color = "cyan" } },
        { "[", group = "Prev", icon = { icon = "󰒮", color = "cyan" } },
        { "<leader>b", group = "Buffer", icon = { icon = "󰈔", color = "cyan" } },
        { "<leader>h", group = "Git hunk", mode = { "n", "v" }, icon = { icon = "󰊢", color = "orange" } },
        { "<leader>f", group = "File/Find", icon = { icon = "󰙅", color = "azure" } },
        { "<leader>g", group = "Git", icon = { icon = "", color = "orange" } },
        { "<leader>m", group = "Markdown", icon = { icon = "󰍔", color = "purple" } },
        { "<leader>s", group = "Search", mode = { "n", "v" }, icon = { icon = "", color = "green" } },
        { "<leader>S", group = "Salesforce", mode = { "n", "x" }, icon = { icon = "󰢎", color = "blue" } },
        { "<leader>c", group = "Code", icon = { icon = "", color = "purple" } },
        { "<leader>d", group = "Delete (black hole)", mode = { "n", "v" }, icon = { icon = "󰩹", color = "red" } },
        { "<leader>p", group = "Project", icon = { icon = "󰏗", color = "green" } },
        { "<leader>t", group = "Toggle", icon = { icon = "", color = "yellow" } },
        { "<leader>q", group = "Session", icon = { icon = "", color = "purple" } },
        { "<leader>x", group = "Trouble", icon = { icon = "󰔫", color = "red" } },
        { "<leader>u", group = "Undotree", icon = { icon = "󰕌", color = "purple" } },
        { "gc", group = "Comment line", mode = { "n", "v" }, icon = { icon = "󰅺", color = "grey" } },
        { "gb", group = "Comment block", mode = { "n", "v" }, icon = { icon = "󰅺", color = "grey" } },
        { "gs", group = "Flash jump", icon = { icon = "⚡", color = "yellow" } },
        { "s", group = "Split / window", icon = { icon = "", color = "cyan" } },
        -- Shorten the two stock `g` presets that alone forced 1-column / truncation.
        { "g,", desc = "Newer change-list pos", icon = { icon = "󰒭", color = "grey" } },
        { "g;", desc = "Older change-list pos", icon = { icon = "󰒮", color = "grey" } },
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
  },
}
