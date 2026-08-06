--------------------------------------------------------------------------------
-- Indent guides (indent-blankline / ibl) + current-scope “reverse L”
-- Refs: CodeOSS ui.lua; Kickstart plugins/indent_line.lua (empty opts).
-- Alts: mini.indentscope · snacks indent · none (treesitter indent only).
--
-- Scope line colors match rainbow brackets via lua/config/rainbow_palette.lua.
-- show_start + show_end draw underlines at the block edges → reverse-L look
-- with the vertical scope guide.
--------------------------------------------------------------------------------

local palette = require("config.rainbow_palette")

return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    -- event = "VeryLazy",
    dependencies = {
      -- Optional: load after treesitter so scope queries work sooner
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local hooks = require("ibl.hooks")
      local rainbow_names = palette.names()

      -- Dim passive guides; brighten / sync scope via palette (and ColorScheme).
      local function apply_indent_highlights()
        palette.apply({ bold = true })

        -- Non-active indent columns — same “quiet but visible” weight as listchars
        -- space dots (Whitespace ≈ #3d3a45 in autocmds.lua). Active scope stays bright.
        vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3d3a45", nocombine = true })
        -- vim.api.nvim_set_hl(0, "IblIndent", { fg = "#2a2833", nocombine = true }) -- near-invisible
        -- vim.api.nvim_set_hl(0, "IblIndent", { fg = "#4a4654", nocombine = true }) -- stronger guides
        -- vim.api.nvim_set_hl(0, "IblIndent", { fg = "#5c5866", nocombine = true }) -- match stronger Whitespace
        -- vim.api.nvim_set_hl(0, "IblIndent", { link = "Whitespace" }) -- always track listchars dots

        -- Fallback single-color scope (used only if scope.highlight is a string / IblScope).
        -- When using the rainbow list below, depth colors come from RainbowDelimiterCustom*.
        vim.api.nvim_set_hl(0, "IblScope", { fg = "#BD93F9", bold = true, nocombine = true })
        -- vim.api.nvim_set_hl(0, "IblScope", { fg = "#8BE9FD", bold = true }) -- cyan
        -- vim.api.nvim_set_hl(0, "IblScope", { fg = "#FFB86C", bold = true }) -- orange
        -- vim.api.nvim_set_hl(0, "IblScope", { link = "Identifier" }) -- follow theme
      end

      -- HIGHLIGHT_SETUP runs whenever ibl (re)builds its highlight cache.
      hooks.register(hooks.type.HIGHLIGHT_SETUP, apply_indent_highlights)
      apply_indent_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_ibl_highlights", { clear = true }),
        callback = apply_indent_highlights,
      })

      require("ibl").setup({
        indent = {
          char = "│", -- passive guide character (straight dim line on every indent)
          -- char = "┊", -- lighter dotted guide
          -- char = "¦",
          -- char = " ", -- invisible passive guides (scope-only mode)
          tab_char = "│", -- guides on real tab indents (same glyph as spaces)
          -- tab_char = "┊",
          -- tab_char = "→",
          highlight = "IblIndent", -- dim passive columns (see apply_indent_highlights)
          -- highlight = "Whitespace", -- force same hl group as space dots
          -- highlight = rainbow_names, -- rainbow every indent column (noisier)
          -- smart_indent_cap = true, -- default-ish: cap indent depth oddly
        },

        whitespace = {
          -- remove_blankline_trail = true, -- trim trail markers on blank lines
          -- highlight = { "Whitespace", "NonText" },
        },

        scope = {
          enabled = true, -- highlight the treesitter scope under the cursor
          -- enabled = false, -- guides only, no current-block emphasis

          -- Vertical bar glyph. Left-edge blocks sit more “in the gutter” than │.
          char = "▏", -- U+258F left one-eighth block (reads a bit more left)
          -- char = "▎", -- U+258E left quarter block (thicker, still left-biased)
          -- char = "│", -- centered box-drawing (default ibl look)
          -- char = "┃", -- heavy centered bar
          -- char = "▌", -- full left half block (very obvious)

          -- Reverse-L: underline on first + last line of the scope + vertical bar.
          show_start = true, -- top of the “L” / underline at scope start
          show_end = true, -- bottom underline at scope end
          -- show_start = false, -- vertical bar only (old look)
          -- show_end = false,

          -- Underline from the exact node start/end column (not only at indent col).
          -- Keep false so the bar/underline stay on the indent column (left of `if`/`for`).
          show_exact_scope = false, -- classic indent-column reverse-L
          -- show_exact_scope = true, -- underlines hug the real TS node edges (often under the keyword)

          injected_languages = true, -- scopes inside injections (JS in HTML, …)
          -- injected_languages = false,

          -- Same palette as rainbow brackets → scope depth matches bracket color.
          highlight = rainbow_names,
          -- highlight = "IblScope", -- single bright color instead of rainbow
          -- highlight = { "IblScope" },

          -- ibl only ships scope node maps for some langs (JS/Lua/Java/…). Apex is
          -- missing upstream — register nodes here (from apex locals.scm / grammar).
          include = {
            node_type = {
              apex = {
                "block",
                "class_body",
                "class_declaration",
                "interface_declaration",
                "enum_declaration",
                "trigger_declaration",
                "method_declaration",
                "constructor_declaration",
                "if_statement",
                "for_statement",
                "while_statement",
                "do_statement",
                "try_statement",
                "catch_clause",
                "enhanced_for_statement",
                -- "switch_expression",
                -- "switch_statement",
              },
              -- soql = { "source_file", "select_clause", … }, -- uncomment if you want SOQL scopes
              -- ["*"] = { "*" }, -- every named node (very noisy)
            },
          },
          exclude = {
            language = {}, -- e.g. { "help", "markdown" }
            -- language = { "markdown", "text" },
            node_type = {
              -- ["*"] = { "source_file", "program" }, -- skip whole-file scopes
              -- apex = { "class_declaration" }, -- if whole-class scope feels too big
            },
          },
        },

        exclude = {
          filetypes = {
            "help",
            "lazy",
            "mason",
            "neo-tree",
            "notify",
            "TelescopePrompt",
            "Trouble",
            "undotree",
            -- "markdown", -- uncomment if guides annoy in prose
          },
          buftypes = {
            "terminal",
            "nofile",
            "quickfix",
            "prompt",
          },
        },
      })

      -- Map treesitter scope depth → rainbow highlight index (bracket sync).
      hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
      -- Without this hook, a multi-name scope.highlight list won’t track nesting as well.
    end,
  },

  -- mini.indentscope alternate (animated scope line; disable ibl scope if you use it):
  -- {
  --   "echasnovski/mini.indentscope",
  --   event = { "BufReadPost", "BufNewFile" },
  --   opts = {
  --     symbol = "│",
  --     -- symbol = "┃",
  --     options = { try_as_border = true },
  --   },
  -- },
}
