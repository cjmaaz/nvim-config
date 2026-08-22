--------------------------------------------------------------------------------
-- Colorscheme
-- Must load early (lazy = false, high priority) or the UI flashes the default
-- theme, then switches — and lualine's theme = "auto" would lag behind.
--
-- Alternatives (enable only one colorscheme plugin at a time):
--   - loctvl842/monokai-pro.nvim      (previous warm-charcoal theme; retained below)
--   - rose-pine/neovim               (previous Rosé Pine Main; retained below)
--   - talha-akram/noctis.nvim         (previous Noctis Bordo; retained below)
--   - rebelot/kanagawa.nvim          (Kanagawa dragon — commented below)
--   - folke/tokyonight.nvim          (LazyVim default)
--   - craftzdog/solarized-osaka.nvim (Craftzdog)
--   - catppuccin/nvim
--   - edenEast/nightfox.nvim
--   - Built-in: :colorscheme habamax / desert / … (no plugin)
--------------------------------------------------------------------------------

return {
  -- Active: Catppuccin Mocha accents on a neutral near-black background.
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false, -- paint before UI plugins so curved separators inherit colors
    -- lazy = true, -- wrong for themes: bubbles can initialize with black edges
    priority = 1000,
    -- priority = 50, -- too late for statusline/chrome consumers
    opts = {
      flavour = "mocha",
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      -- transparent_background = true, -- use terminal background instead
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = true,
        shade = "dark",
        percentage = 0.08,
      },
      styles = {
        comments = { "italic" },
        conditionals = {},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {
        mocha = {
          base = "#18181B",
          mantle = "#141417",
          crust = "#101012",
          surface0 = "#27272C",
          surface1 = "#3F3F46",
          surface2 = "#52525B",
          overlay0 = "#71717A",
          overlay1 = "#8B8B95",
          overlay2 = "#A1A1AA",
        },
      },
      default_integrations = true,
      auto_integrations = true,
      integrations = {
        blink_cmp = true,
        bufferline = true,
        fidget = true,
        fzf = true,
        gitsigns = true,
        indent_blankline = {
          enabled = true,
          scope_color = "mauve",
          colored_indent_levels = false,
        },
        lsp_trouble = true,
        mason = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
            ok = { "undercurl" },
          },
        },
        neotree = true,
        rainbow_delimiters = true,
        render_markdown = true,
        telescope = { enabled = true },
        treesitter = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin-mocha")
      -- vim.cmd.colorscheme("catppuccin") -- follows configured flavour

      local chrome = require("config.ui_chrome")
      local hl = vim.api.nvim_set_hl
      local function apply_overrides()
        hl(0, "NormalFloat", { fg = chrome.panel_fg, bg = chrome.panel_bg })
        -- hl(0, "NormalFloat", { link = "Normal" }) -- blend floats into editor
        hl(0, "FloatBorder", { fg = chrome.divider_fg, bg = chrome.panel_bg })
        -- hl(0, "FloatBorder", { fg = chrome.red, bg = chrome.panel_bg }) -- vivid edge
        hl(0, "FloatTitle", { fg = chrome.title_fg, bg = chrome.panel_bg, bold = true })
        hl(0, "FloatFooter", { fg = chrome.muted_fg, bg = chrome.panel_bg })
        hl(0, "@markup.strong", { bold = true })
        hl(0, "@markup.italic", { italic = true })
        hl(0, "@markup.strikethrough", { strikethrough = true })
        hl(0, "@lsp.mod.deprecated", { strikethrough = true, italic = true })
        hl(0, "DiagnosticDeprecated", { strikethrough = true })
      end
      apply_overrides()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_float_chrome", { clear = true }),
        callback = apply_overrides,
      })
    end,
  },

  -- Inactive alternate: Monokai Pro.
  {
    "loctvl842/monokai-pro.nvim",
    enabled = false, -- retain the previous theme without loading it
    -- enabled = true, -- switch back after disabling Catppuccin above
    lazy = false, -- paint before UI plugins to avoid startup flash
    -- lazy = true, -- wrong for themes: bars/floats initialize against defaults
    priority = 1000,
    -- priority = 50, -- too late for statusline/chrome consumers
    opts = {
      transparent_background = false,
      -- transparent_background = true, -- use the terminal's own background
      terminal_colors = true,
      devicons = vim.g.have_nerd_font,
      filter = "pro",
      -- filter = "ristretto", -- warmer/deeper alternate
      styles = {
        comment = { italic = true },
        keyword = {},
        type = {},
        storageclass = {},
        structure = {},
        parameter = {},
        annotation = {},
        tag_attribute = {},
      },
      inc_search = "background",
      -- inc_search = "underline", -- quieter incremental-search treatment
      background_clear = {},
      plugins = {
        bufferline = {
          underline_selected = false,
          underline_visible = false,
          underline_fill = false,
          bold = true,
        },
        indent_blankline = {
          context_highlight = "default",
          context_start_underline = false,
        },
      },
    },
    config = function(_, opts)
      require("monokai-pro").setup(opts)
      vim.cmd.colorscheme("monokai-pro")
      -- require("monokai-pro").load("ristretto") -- warmer/deeper filter

      local chrome = require("config.ui_chrome")
      local hl = vim.api.nvim_set_hl
      local function apply_overrides()
        hl(0, "NormalFloat", { fg = chrome.panel_fg, bg = chrome.panel_bg })
        -- hl(0, "NormalFloat", { link = "Normal" }) -- blend floats into editor
        hl(0, "FloatBorder", { fg = chrome.divider_fg, bg = chrome.panel_bg })
        -- hl(0, "FloatBorder", { fg = chrome.red, bg = chrome.panel_bg }) -- vivid edge
        hl(0, "FloatTitle", { fg = chrome.title_fg, bg = chrome.panel_bg, bold = true })
        hl(0, "FloatFooter", { fg = chrome.muted_fg, bg = chrome.panel_bg })
        hl(0, "@markup.strong", { bold = true })
        hl(0, "@markup.italic", { italic = true })
        hl(0, "@markup.strikethrough", { strikethrough = true })
        hl(0, "@lsp.mod.deprecated", { strikethrough = true, italic = true })
        hl(0, "DiagnosticDeprecated", { strikethrough = true })
      end
      apply_overrides()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_float_chrome", { clear = true }),
        callback = apply_overrides,
      })
    end,
  },

  -- Inactive alternate: Rosé Pine Main.
  {
    "rose-pine/neovim",
    name = "rose-pine",
    enabled = false, -- retain the previous theme without loading it
    -- enabled = true, -- switch back after disabling Catppuccin above
    lazy = false, -- paint before UI plugins to avoid startup flash
    -- lazy = true, -- wrong for themes: bars/floats initialize against defaults
    priority = 1000,
    -- priority = 50, -- too late for statusline/chrome consumers
    opts = {
      variant = "main",
      -- variant = "moon", -- softer/cooler alternate
      dark_variant = "main",
      dim_inactive_windows = true,
      -- dim_inactive_windows = false, -- keep every split equally bright
      extend_background_behind_borders = true,
      enable = {
        terminal = true,
        legacy_highlights = true,
        migrations = true,
      },
      styles = {
        bold = true,
        italic = true,
        transparency = false,
      },
      groups = {
        border = "subtle",
        link = "iris",
        panel = "surface",
        error = "love",
        hint = "iris",
        info = "foam",
        note = "pine",
        todo = "rose",
        warn = "gold",
      },
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd.colorscheme("rose-pine-main")
      -- vim.cmd.colorscheme("rose-pine-moon") -- softer/cooler Rosé Pine variant

      local chrome = require("config.ui_chrome")
      local hl = vim.api.nvim_set_hl
      local function apply_overrides()
        hl(0, "NormalFloat", { fg = chrome.panel_fg, bg = chrome.panel_bg })
        -- hl(0, "NormalFloat", { link = "Normal" }) -- blend floats into editor
        hl(0, "FloatBorder", { fg = chrome.divider_fg, bg = chrome.panel_bg })
        -- hl(0, "FloatBorder", { fg = chrome.love, bg = chrome.panel_bg }) -- vivid edge
        hl(0, "FloatTitle", { fg = chrome.title_fg, bg = chrome.panel_bg, bold = true })
        hl(0, "FloatFooter", { fg = chrome.muted_fg, bg = chrome.panel_bg })
        hl(0, "@markup.strong", { bold = true })
        hl(0, "@markup.italic", { italic = true })
        hl(0, "@markup.strikethrough", { strikethrough = true })
        hl(0, "@lsp.mod.deprecated", { strikethrough = true, italic = true })
        hl(0, "DiagnosticDeprecated", { strikethrough = true })
      end
      apply_overrides()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_float_chrome", { clear = true }),
        callback = apply_overrides,
      })
    end,
  },

  -- Inactive alternate: VS Code Noctis Bordo (warm rose / burgundy).
  -- talha-akram/noctis.nvim has no plugin setup()/opts API (unlike kanagawa).
  -- The `opts` table below mirrors the kanagawa knobs we care about and is
  -- applied with nvim_set_hl after :colorscheme.
  {
    "talha-akram/noctis.nvim",
    enabled = false, -- keep the previous theme available without loading it
    -- enabled = true, -- switch back after disabling Catppuccin above
    -- Load timing: colorschemes should paint before other UI plugins.
    lazy = false, -- load at startup (required for colorschemes)
    -- lazy = true, -- wrong for themes: UI would flash the default first
    priority = 1000, -- load before other UI plugins
    -- priority = 50, -- too late; statusline/theme plugins may paint first

    opts = {
      -- Typography aligned with common Neovim theme defaults (Tokyo Night /
      -- Catppuccin): italic for comments (+ keywords); plain functions/types;
      -- strikethrough only for markup/deprecated — not for normal code.

      -- Spell + diagnostic underlines (not the same as strikethrough).
      undercurl = true, -- undercurl for spell/diagnostics
      -- undercurl = false, -- plain underlines / no special underline style

      -- Clear editor backgrounds (terminal wallpaper shows through).
      transparent = false, -- solid backgrounds
      -- transparent = true, -- clear Normal / SignColumn / etc.

      -- Dim unfocused windows.
      dimInactive = true, -- fade NormalNC when another window is focused
      -- dimInactive = false, -- same brightness in all windows

      -- Push a Bordo-ish 16-color palette into :terminal.
      terminalColors = true, -- tint :terminal to match the theme
      -- terminalColors = false, -- leave the terminal's own palette alone

      -- Italic (soft / secondary meaning)
      commentStyle = { italic = true }, -- almost universal
      -- commentStyle = {}, -- plain comments
      -- commentStyle = { bold = true }, -- rare; heavy comments

      keywordStyle = { italic = true }, -- Tokyo Night–style
      -- keywordStyle = {}, -- Catppuccin-style plain keywords
      -- keywordStyle = { bold = true }, -- heavier keywords

      -- Plain by default (color carries meaning; avoid bold-everything)
      statementStyle = {}, -- modern themes usually leave plain
      -- statementStyle = { bold = true }, -- older Kanagawa-ish bold statements
      -- statementStyle = { italic = true }, -- soft statements via Keyword link

      functionStyle = {}, -- neither bold nor italic
      -- functionStyle = { bold = true }, -- emphasize function names
      -- functionStyle = { italic = true }, -- soft functions

      typeStyle = {}, -- neither bold nor italic
      -- typeStyle = { bold = true }, -- optional: some themes emphasize types
      -- typeStyle = { italic = true }, -- soft types

      -- Markup / LSP only (see config apply below)
      -- strikethrough: @markup.strikethrough, @lsp.mod.deprecated
      -- bold: @markup.strong
      -- italic: @markup.italic
    },
    config = function(_, opts)
      -- Active Noctis variant.
      vim.cmd.colorscheme("noctis_bordo") -- warm rose / burgundy
      -- vim.cmd.colorscheme("noctis") -- default Noctis
      -- vim.cmd.colorscheme("noctis_azureus") -- blue-leaning
      -- vim.cmd.colorscheme("noctis_minimus")
      -- vim.cmd.colorscheme("noctis_uva")
      -- vim.cmd.colorscheme("noctis_viola")
      -- vim.cmd.colorscheme("noctis_obscuro")
      -- vim.cmd.colorscheme("noctis_sereno")
      -- vim.cmd.colorscheme("noctis_lux")
      -- vim.cmd.colorscheme("noctis_lilac")
      -- vim.cmd.colorscheme("noctis_hibernus")

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
      local chrome = require("config.ui_chrome")
      local function has(style_tbl, key)
        return style_tbl and style_tbl[key] == true
      end

      -- Give unowned floats the same inset Bordo panel used by plugin UIs.
      local function apply_float_chrome()
        local float_bg = opts.transparent and "NONE" or chrome.panel_bg
        hl(0, "NormalFloat", { fg = chrome.panel_fg, bg = float_bg })
        -- hl(0, "NormalFloat", { link = "Normal" }) -- let floats blend into the editor
        hl(0, "FloatBorder", { fg = chrome.divider_fg, bg = float_bg })
        -- hl(0, "FloatBorder", { fg = chrome.border_fg, bg = float_bg }) -- rose outline
        hl(0, "FloatTitle", { fg = chrome.title_fg, bg = float_bg, bold = true })
        hl(0, "FloatFooter", { fg = chrome.muted_fg, bg = float_bg })
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

      -- Apply after transparent/theme overrides; re-apply after runtime switches.
      apply_float_chrome()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_float_chrome", { clear = true }),
        callback = apply_float_chrome,
      })
    end,
  },

  -- Kanagawa Dragon (disable/remove noctis above if you switch back).
  -- Typography matches the active noctis opts (community defaults).
  -- {
  --   "rebelot/kanagawa.nvim",
  --   lazy = false, -- load at startup
  --   -- lazy = true, -- wrong for themes
  --   priority = 1000, -- before other UI plugins
  --   opts = {
  --     compile = false, -- no compiled cache (simpler while tuning)
  --     -- compile = true, -- faster startup after :KanagawaCompile
  --     undercurl = true, -- spell/diagnostic undercurls
  --     -- undercurl = false,
  --     transparent = false, -- solid backgrounds
  --     -- transparent = true, -- clear backgrounds
  --     dimInactive = true, -- fade unfocused windows
  --     -- dimInactive = false,
  --     terminalColors = true, -- tint :terminal
  --     -- terminalColors = false,
  --     commentStyle = { italic = true }, -- almost universal
  --     -- commentStyle = {},
  --     keywordStyle = { italic = true }, -- Tokyo Night–style
  --     -- keywordStyle = {}, -- Catppuccin-style plain keywords
  --     statementStyle = {}, -- plain statements
  --     -- statementStyle = { bold = true }, -- older Kanagawa bold
  --     functionStyle = {},
  --     -- functionStyle = { bold = true },
  --     typeStyle = {},
  --     -- typeStyle = { bold = true }, -- optional emphasis
  --     theme = "dragon", -- dark default when background=dark is unset
  --     -- theme = "wave",
  --     -- theme = "lotus",
  --     background = {
  --       dark = "dragon", -- strongest dark pick here
  --       -- dark = "wave", -- classic Kanagawa dark
  --       -- dark = "lotus", -- not typical for dark bg
  --       light = "lotus", -- light background variant
  --       -- light = "wave",
  --     },
  --     -- overrides = function(colors)
  --     --   return {
  --     --     ["@markup.strong"] = { bold = true },
  --     --     ["@markup.italic"] = { italic = true },
  --     --     ["@markup.strikethrough"] = { strikethrough = true },
  --     --     ["@lsp.mod.deprecated"] = { strikethrough = true, italic = true },
  --     --   }
  --     -- end,
  --   },
  --   config = function(_, opts)
  --     require("kanagawa").setup(opts)
  --     vim.cmd.colorscheme("kanagawa-dragon") -- matches background.dark above
  --     -- vim.cmd.colorscheme("kanagawa-wave")
  --     -- vim.cmd.colorscheme("kanagawa-lotus")
  --   end,
  -- },

  -- Tokyo Night (disable noctis if you switch).
  -- Same typography via built-in `styles` (comments + keywords italic; rest plain).
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     style = "night", -- darkest built-in
  --     -- style = "storm", -- slightly softer dark
  --     -- style = "moon", -- cooler dark
  --     -- style = "day", -- light
  --     transparent = false, -- solid backgrounds
  --     -- transparent = true,
  --     terminal_colors = true, -- tint :terminal
  --     -- terminal_colors = false,
  --     dim_inactive = true, -- fade unfocused windows
  --     -- dim_inactive = false,
  --     styles = {
  --       comments = { italic = true },
  --       -- comments = {},
  --       keywords = { italic = true }, -- Tokyo Night default
  --       -- keywords = {}, -- plain keywords
  --       functions = {},
  --       -- functions = { bold = true },
  --       variables = {},
  --       -- sidebars = "dark", -- "dark" | "transparent" | "normal"
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
  --     vim.cmd.colorscheme("tokyonight-night") -- match opts.style
  --     -- vim.cmd.colorscheme("tokyonight-storm")
  --     -- vim.cmd.colorscheme("tokyonight-moon")
  --     -- vim.cmd.colorscheme("tokyonight-day")
  --   end,
  -- },

  -- Solarized Osaka / Craftzdog (disable noctis if you switch).
  -- Align styles with the same convention when you enable it.
  -- {
  --   "craftzdog/solarized-osaka.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     transparent = true, -- Craftzdog default feel
  --     -- transparent = false, -- solid background
  --     terminal_colors = true,
  --     -- terminal_colors = false,
  --     styles = {
  --       comments = { italic = true },
  --       -- comments = {},
  --       keywords = { italic = true },
  --       -- keywords = {},
  --       functions = {},
  --       -- functions = { bold = true },
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
