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
      -- Same spirit as kanagawa's opts; implemented manually in `config`.
      undercurl = true, -- keep undercurl on spell/diagnostics (theme default)
      transparent = false, -- true = clear Normal/SignColumn backgrounds
      -- transparent = true,
      dimInactive = true, -- dim NormalNC when the window is unfocused
      -- dimInactive = false,
      terminalColors = true, -- push a Bordo-ish 16-color palette into :terminal
      commentStyle = { italic = true },
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      -- functionStyle = { italic = false },
      -- typeStyle = { bold = true },
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
      local function style(enabled, attr)
        return enabled and attr or false
      end

      -- commentStyle / keywordStyle / statementStyle (kanagawa equivalents)
      hl(0, "Comment", {
        fg = pal.light_grey,
        italic = style(opts.commentStyle and opts.commentStyle.italic, true),
      })
      hl(0, "@comment", { link = "Comment" })

      hl(0, "Keyword", {
        fg = pal.red,
        italic = style(opts.keywordStyle and opts.keywordStyle.italic, true),
        bold = style(opts.keywordStyle and opts.keywordStyle.bold, true),
      })
      hl(0, "@keyword", { link = "Keyword" })

      hl(0, "Statement", {
        fg = pal.red,
        bold = style(opts.statementStyle and opts.statementStyle.bold, true),
        italic = style(opts.statementStyle and opts.statementStyle.italic, true),
      })

      if opts.typeStyle then
        hl(0, "Type", {
          fg = pal.yellow,
          bold = style(opts.typeStyle.bold, true),
          italic = style(opts.typeStyle.italic, true),
        })
      end

      if opts.functionStyle then
        hl(0, "Function", {
          fg = pal.green,
          bold = style(opts.functionStyle.bold, true),
          italic = style(opts.functionStyle.italic, true),
        })
      end

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
  -- {
  --   "rebelot/kanagawa.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     compile = false, -- true = generate a faster compiled theme (optional later)
  --     undercurl = true, -- spell/diagnostics use undercurl when the terminal supports it
  --     transparent = false, -- true = no Normal background (terminal shows through)
  --     -- transparent = true,
  --     dimInactive = true, -- dim windows that are not focused
  --     -- dimInactive = false,
  --     terminalColors = true, -- push palette into :terminal
  --     commentStyle = { italic = true },
  --     keywordStyle = { italic = true },
  --     statementStyle = { bold = true },
  --     -- functionStyle = { italic = false },
  --     -- typeStyle = {},
  --     theme = "dragon", -- default variant when using :colorscheme kanagawa
  --     background = {
  --       -- Used if you ever set vim.o.background = "dark"|"light" with :colorscheme kanagawa
  --       dark = "dragon", -- "wave" | "dragon" | "lotus"
  --       light = "lotus",
  --     },
  --     -- overrides = function(colors)
  --     --   return {} -- tweak highlight groups once you know what you want
  --     -- end,
  --   },
  --   config = function(_, opts)
  --     require("kanagawa").setup(opts)
  --     -- Load the variant by name so background/theme tables cannot surprise you.
  --     -- Other kanagawa commands: kanagawa-wave, kanagawa-lotus, kanagawa
  --     vim.cmd.colorscheme("kanagawa-dragon")
  --     -- vim.cmd.colorscheme("kanagawa-wave")
  --     -- vim.cmd.colorscheme("kanagawa-lotus")
  --   end,
  -- },

  -- Example: Tokyo Night instead (disable noctis if you switch):
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = { style = "night", transparent = false },
  --   config = function(_, opts)
  --     require("tokyonight").setup(opts)
  --     vim.cmd.colorscheme("tokyonight-night")
  --   end,
  -- },

  -- Example: Craftzdog's Solarized Osaka instead (disable noctis if you switch):
  -- {
  --   "craftzdog/solarized-osaka.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     transparent = true, -- Craftzdog default feel; set false for a solid background
  --     -- styles = { comments = { italic = true }, keywords = { italic = true } },
  --   },
  --   config = function(_, opts)
  --     require("solarized-osaka").setup(opts)
  --     vim.cmd.colorscheme("solarized-osaka")
  --   end,
  -- },
}
