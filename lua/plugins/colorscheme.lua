--------------------------------------------------------------------------------
-- Colorscheme
-- Must load early (lazy = false, high priority) or the UI flashes the default
-- theme, then switches — and lualine's theme = "auto" would lag behind.
--
-- Alternatives (enable only one colorscheme plugin at a time):
--   - rebelot/kanagawa.nvim          (Kanagawa dragon — commented below)
--   - folke/tokyonight.nvim          (LazyVim default)
--   - craftzdog/solarized-osaka.nvim (Craftzdog)
--   - catppuccin/nvim
--   - edenEast/nightfox.nvim
--   - Built-in: :colorscheme habamax / desert / … (no plugin)
--------------------------------------------------------------------------------

return {
  -- Active: VS Code Noctis Bordo (warm rose / burgundy). Other variants:
  --   noctis, noctis_azureus, noctis_minimus, noctis_uva, noctis_viola,
  --   noctis_obscuro, noctis_sereno, noctis_lux, noctis_lilac, noctis_hibernus
  --
  -- talha-akram/noctis.nvim has no plugin setup()/opts API (unlike kanagawa).
  -- The `opts` table below mirrors the kanagawa knobs we care about and is
  -- applied with nvim_set_hl after :colorscheme.
  {
    "talha-akram/noctis.nvim",
    lazy = false, -- colorschemes should not wait for an event
    priority = 1000, -- load before other UI plugins paint
    opts = {
      -- Typography aligned with common Neovim theme defaults (Tokyo Night /
      -- Catppuccin): italic for comments (+ keywords); plain functions/types;
      -- strikethrough only for markup/deprecated — not for normal code.
      undercurl = true, -- spell + diagnostic underlines (not the same as strike)
      transparent = false, -- true = clear Normal/SignColumn backgrounds
      -- transparent = true,
      dimInactive = true, -- dim NormalNC when the window is unfocused
      -- dimInactive = false,
      terminalColors = true, -- push a Bordo-ish 16-color palette into :terminal

      -- Italic (soft / secondary meaning)
      commentStyle = { italic = true }, -- almost universal
      keywordStyle = { italic = true }, -- Tokyo Night default; Catppuccin often leaves plain
      -- keywordStyle = {}, -- uncomment for Catppuccin-style plain keywords

      -- Plain by default (color carries meaning; avoid bold-everything)
      statementStyle = {}, -- was bold under Kanagawa; modern themes usually leave plain/italic via Keyword
      functionStyle = {}, -- neither bold nor italic
      typeStyle = {}, -- neither bold nor italic
      -- typeStyle = { bold = true }, -- optional: some themes emphasize types

      -- Markup / LSP only (see config apply below)
      -- strikethrough: @markup.strikethrough, @lsp.mod.deprecated
      -- bold: @markup.strong
      -- italic: @markup.italic
    },
    config = function(_, opts)
      vim.cmd.colorscheme("noctis_bordo")
      -- vim.cmd.colorscheme("noctis")
      -- vim.cmd.colorscheme("noctis_azureus")

      -- Palette snippets from noctis_bordo (for overrides / terminal).
      local pal = {
        bg0 = "#312A2D",
        bg1 = "#3C2F34",
        bg2 = "#2B2528",
        fg = "#C9BEC2",
        red = "#D17B9A",
        orange = "#C5663F",
        yellow = "#F6C38A",
        green = "#7BE6AB",
        cyan = "#4CA1B3",
        blue = "#64AAE4",
        purple = "#7060eb",
        grey = "#5C5457",
        light_grey = "#87757C",
      }

      local hl = vim.api.nvim_set_hl
      local function has(style_tbl, key)
        return style_tbl and style_tbl[key] == true
      end

      -- Comments → italic
      hl(0, "Comment", {
        fg = pal.light_grey,
        italic = has(opts.commentStyle, "italic"),
        bold = has(opts.commentStyle, "bold"),
      })
      hl(0, "@comment", { link = "Comment" })

      -- Keywords → italic (not bold)
      hl(0, "Keyword", {
        fg = pal.red,
        italic = has(opts.keywordStyle, "italic"),
        bold = has(opts.keywordStyle, "bold"),
      })
      hl(0, "@keyword", { link = "Keyword" })

      -- Statements → follow statementStyle (default: plain; don't force bold)
      hl(0, "Statement", {
        fg = pal.red,
        italic = has(opts.statementStyle, "italic"),
        bold = has(opts.statementStyle, "bold"),
      })

      -- Functions / types → plain unless opted in
      hl(0, "Function", {
        fg = pal.green,
        italic = has(opts.functionStyle, "italic"),
        bold = has(opts.functionStyle, "bold"),
      })
      hl(0, "@function", { link = "Function" })

      hl(0, "Type", {
        fg = pal.yellow,
        italic = has(opts.typeStyle, "italic"),
        bold = has(opts.typeStyle, "bold"),
      })
      hl(0, "@type", { link = "Type" })

      -- Markup (Treesitter): bold / italic / strike only where the document asks
      hl(0, "@markup.strong", { bold = true })
      hl(0, "@markup.italic", { italic = true })
      hl(0, "@markup.strikethrough", { strikethrough = true })

      -- Deprecated symbols (LSP) → strikethrough, not normal keywords
      hl(0, "@lsp.mod.deprecated", { strikethrough = true, italic = true })
      hl(0, "DiagnosticDeprecated", { strikethrough = true })

      -- transparent (kanagawa.transparent)
      if opts.transparent then
        for _, group in ipairs({
          "Normal",
          "NormalNC",
          "NormalFloat",
          "SignColumn",
          "LineNr",
          "CursorLineNr",
          "EndOfBuffer",
          "Folded",
          "FoldColumn",
        }) do
          hl(0, group, { bg = "NONE" })
        end
      end

      -- dimInactive (kanagawa.dimInactive)
      if opts.dimInactive then
        hl(0, "NormalNC", {
          fg = pal.light_grey,
          bg = opts.transparent and "NONE" or pal.bg2,
        })
      end

      -- undercurl: re-assert diagnostic/spell undercurls when requested
      if opts.undercurl then
        hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = pal.red })
        hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = pal.orange })
        hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = pal.blue })
        hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = pal.purple })
        hl(0, "SpellBad", { undercurl = true, sp = pal.red })
        hl(0, "SpellCap", { undercurl = true, sp = pal.yellow })
      end

      -- terminalColors (kanagawa.terminalColors) — approximate 16-color map
      if opts.terminalColors then
        vim.g.terminal_color_0 = pal.bg0
        vim.g.terminal_color_1 = pal.red
        vim.g.terminal_color_2 = pal.green
        vim.g.terminal_color_3 = pal.yellow
        vim.g.terminal_color_4 = pal.blue
        vim.g.terminal_color_5 = pal.purple
        vim.g.terminal_color_6 = pal.cyan
        vim.g.terminal_color_7 = pal.fg
        vim.g.terminal_color_8 = pal.grey
        vim.g.terminal_color_9 = pal.red
        vim.g.terminal_color_10 = pal.green
        vim.g.terminal_color_11 = pal.yellow
        vim.g.terminal_color_12 = pal.blue
        vim.g.terminal_color_13 = pal.purple
        vim.g.terminal_color_14 = pal.cyan
        vim.g.terminal_color_15 = pal.fg
      end
    end,
  },

  -- Kanagawa Dragon (disable/remove noctis above if you switch back):
  -- Typography matches the active noctis opts (community defaults).
  -- {
  --   "rebelot/kanagawa.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     compile = false,
  --     undercurl = true,
  --     transparent = false,
  --     -- transparent = true,
  --     dimInactive = true,
  --     -- dimInactive = false,
  --     terminalColors = true,
  --     -- Italic: comments + keywords (Tokyo Night–style)
  --     commentStyle = { italic = true },
  --     keywordStyle = { italic = true },
  --     -- keywordStyle = {}, -- Catppuccin-style plain keywords
  --     -- Plain: statements / functions / types (no bold-everything)
  --     statementStyle = {},
  --     functionStyle = {},
  --     typeStyle = {},
  --     -- typeStyle = { bold = true }, -- optional emphasis
  --     theme = "dragon",
  --     background = {
  --       dark = "dragon", -- "wave" | "dragon" | "lotus"
  --       light = "lotus",
  --     },
  --     -- overrides = function(colors)
  --     --   return {
  --     --     -- Markup / deprecated (Treesitter + LSP)
  --     --     ["@markup.strong"] = { bold = true },
  --     --     ["@markup.italic"] = { italic = true },
  --     --     ["@markup.strikethrough"] = { strikethrough = true },
  --     --     ["@lsp.mod.deprecated"] = { strikethrough = true, italic = true },
  --     --   }
  --     -- end,
  --   },
  --   config = function(_, opts)
  --     require("kanagawa").setup(opts)
  --     vim.cmd.colorscheme("kanagawa-dragon")
  --     -- vim.cmd.colorscheme("kanagawa-wave")
  --     -- vim.cmd.colorscheme("kanagawa-lotus")
  --   end,
  -- },

  -- Tokyo Night (disable noctis if you switch):
  -- Same typography via built-in `styles` (comments + keywords italic; rest plain).
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     style = "night",
  --     transparent = false,
  --     -- transparent = true,
  --     terminal_colors = true,
  --     dim_inactive = true,
  --     styles = {
  --       comments = { italic = true },
  --       keywords = { italic = true },
  --       -- keywords = {}, -- plain keywords
  --       functions = {},
  --       variables = {},
  --       -- sidebars = "dark",
  --       -- floats = "dark",
  --     },
  --     -- on_highlights = function(hl, c)
  --     --   hl["@markup.strong"] = { bold = true }
  --     --   hl["@markup.italic"] = { italic = true }
  --     --   hl["@markup.strikethrough"] = { strikethrough = true }
  --     --   hl["@lsp.mod.deprecated"] = { strikethrough = true, italic = true }
  --     -- end,
  --   },
  --   config = function(_, opts)
  --     require("tokyonight").setup(opts)
  --     vim.cmd.colorscheme("tokyonight-night")
  --   end,
  -- },

  -- Solarized Osaka / Craftzdog (disable noctis if you switch):
  -- Align styles with the same convention when you enable it.
  -- {
  --   "craftzdog/solarized-osaka.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     transparent = true, -- Craftzdog default feel; set false for a solid background
  --     -- transparent = false,
  --     terminal_colors = true,
  --     styles = {
  --       comments = { italic = true },
  --       keywords = { italic = true },
  --       -- keywords = {},
  --       functions = {},
  --       variables = {},
  --       -- conditionals = { italic = true }, -- Catppuccin sometimes italics these
  --     },
  --     -- on_highlights = function(hl, c)
  --     --   hl["@markup.strong"] = { bold = true }
  --     --   hl["@markup.italic"] = { italic = true }
  --     --   hl["@markup.strikethrough"] = { strikethrough = true }
  --     --   hl["@lsp.mod.deprecated"] = { strikethrough = true, italic = true }
  --     -- end,
  --   },
  --   config = function(_, opts)
  --     require("solarized-osaka").setup(opts)
  --     vim.cmd.colorscheme("solarized-osaka")
  --   end,
  -- },
}
