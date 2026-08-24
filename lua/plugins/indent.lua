--------------------------------------------------------------------------------
-- Scope engine (indent-blankline / ibl) + bracket-colored scope number gutter
-- Refs: CodeOSS ui.lua; Kickstart plugins/indent_line.lua (empty opts).
-- Alts: mini.indentscope · snacks indent · none (treesitter indent only).
--
-- Scope gutter reuses the matching rainbow bracket depth color.
-- Horizontal start/end caps remain available as commented alternates below.
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
      local gutter_names = {}
      local gutter_namespace = vim.api.nvim_create_namespace("ibl_scope_gutter")
      local gutter_generation = {}
      for index in ipairs(palette.palette) do
        gutter_names[index] = "IblScopeGutter" .. index
      end

      local function blend(foreground, background, strength)
        local fg = assert(tonumber(foreground:sub(2), 16))
        local bg = assert(tonumber(background:sub(2), 16))
        local function channel(value, shift)
          return math.floor(value / shift) % 0x100
        end
        local function mixed(fg_channel, bg_channel)
          return math.floor(fg_channel * strength + bg_channel * (1 - strength) + 0.5)
        end
        return string.format(
          "#%02X%02X%02X",
          mixed(channel(fg, 0x10000), channel(bg, 0x10000)),
          mixed(channel(fg, 0x100), channel(bg, 0x100)),
          mixed(channel(fg, 1), channel(bg, 1))
        )
      end

      -- Scope gutter uses 100% of the matching bracket color.
      local gutter_strength = 1.00
      -- local gutter_strength = 0.70 -- softer bracket-color tint
      -- local gutter_strength = 0.40 -- muted gutter tint

      -- Sync the scope gutter palette on ColorScheme.
      local function apply_indent_highlights()
        local chrome = require("config.ui_chrome")
        palette.apply({ bold = false }) -- exact same non-bold groups as rainbow brackets
        -- palette.apply({ bold = true }) -- stronger brackets and active scope
        for index, item in ipairs(palette.palette) do
          vim.api.nvim_set_hl(0, gutter_names[index], {
            fg = blend(item[2], chrome.base, gutter_strength),
            bold = false,
            nocombine = true,
          })
        end

        -- Dormant passive-guide color, used only if a glyph is restored below.
        vim.api.nvim_set_hl(0, "IblIndent", { fg = chrome.highlight_med, nocombine = true })
        -- vim.api.nvim_set_hl(0, "IblIndent", { fg = "#2a2833", nocombine = true }) -- near-invisible
        -- vim.api.nvim_set_hl(0, "IblIndent", { fg = "#4a4654", nocombine = true }) -- stronger guides
        -- vim.api.nvim_set_hl(0, "IblIndent", { fg = "#5c5866", nocombine = true }) -- match stronger Whitespace
        -- vim.api.nvim_set_hl(0, "IblIndent", { link = "Whitespace" }) -- always track listchars dots

        -- Fallback single-color scope (used only if scope.highlight is a string / IblScope).
        -- When using the rainbow list below, depth colors come from RainbowDelimiterCustom*.
        vim.api.nvim_set_hl(0, "IblScope", { fg = chrome.iris, bold = false, nocombine = true })
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

      local function clear_scope_gutter(bufnr)
        gutter_generation[bufnr] = (gutter_generation[bufnr] or 0) + 1
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_clear_namespace(bufnr, gutter_namespace, 0, -1)
        end
      end

      local function paint_scope_gutter(bufnr, scope, highlight_index)
        local start_row = select(1, scope:start())
        local end_row = select(1, scope:end_())
        local generation = gutter_generation[bufnr] or 0
        local group = gutter_names[((highlight_index - 1) % #gutter_names) + 1]

        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(bufnr) or (gutter_generation[bufnr] or 0) ~= generation then
            return
          end
          local winid = vim.api.nvim_get_current_win()
          if not vim.api.nvim_win_is_valid(winid) or vim.api.nvim_win_get_buf(winid) ~= bufnr then
            return
          end
          local visible = vim.api.nvim_win_call(winid, function()
            return { vim.fn.line("w0") - 1, vim.fn.line("w$") - 1 }
          end)
          local first_visible, last_visible = visible[1], visible[2]
          vim.api.nvim_buf_clear_namespace(bufnr, gutter_namespace, 0, -1)
          local first_row = math.max(0, start_row, first_visible)
          local last_row = math.min(end_row, last_visible, vim.api.nvim_buf_line_count(bufnr) - 1)
          for row = first_row, last_row do
            vim.api.nvim_buf_set_extmark(bufnr, gutter_namespace, row, 0, {
              number_hl_group = group,
              priority = 120,
              strict = false,
            })
          end
        end)
      end

      local gutter_group = vim.api.nvim_create_augroup("user_ibl_scope_gutter", { clear = true })
      vim.api.nvim_create_autocmd({
        "BufEnter",
        "BufLeave",
        "CursorMoved",
        "CursorMovedI",
        "TextChanged",
        "TextChangedI",
        "WinScrolled",
      }, {
        group = gutter_group,
        callback = function(event)
          clear_scope_gutter(event.buf)
        end,
      })
      vim.api.nvim_create_autocmd("BufDelete", {
        group = gutter_group,
        callback = function(event)
          gutter_generation[event.buf] = nil
        end,
      })

      require("ibl").setup({
        indent = {
          -- Hide passive in-code guides while retaining ibl's scope calculation.
          char = " ",
          -- char = "│", -- restore the single-stroke passive guide
          -- char = "▏", -- previous: left-edge eighth block
          -- char = "▎", -- thicker left quarter
          -- char = "▍", -- U+258D left three-eighths (nudge further right)
          -- char = "┊", -- lighter dotted guide
          -- char = "¦",
          -- char = " ", -- invisible passive guides (scope-only mode)
          -- char = "▕", -- right edge of the indent cell
          tab_char = " ", -- hide passive tab guides too
          -- tab_char = "│", -- restore the single-stroke tab guide
          -- tab_char = "▏", -- previous left-edge block
          -- tab_char = "┊",
          -- tab_char = "→",
          highlight = "IblIndent", -- applies if a passive glyph is restored above
          -- highlight = "Whitespace", -- force same hl group as space dots
          -- highlight = palette.names(), -- rainbow every indent column (noisier)
          -- smart_indent_cap = true, -- default-ish: cap indent depth oddly
        },

        whitespace = {
          -- remove_blankline_trail = true, -- trim trail markers on blank lines
          -- highlight = { "Whitespace", "NonText" },
        },

        scope = {
          enabled = true, -- highlight the treesitter scope under the cursor
          -- enabled = false, -- guides only, no current-block emphasis

          -- Hide the in-code scope glyph; active scope moves to the number gutter.
          char = " ",
          -- char = "│", -- restore the in-code hairline
          -- char = "▏", -- previous: left-edge eighth block
          -- char = "▎", -- thicker left quarter
          -- char = "▍", -- thicker still
          -- char = "┃", -- heavy centered bar
          -- char = "▌", -- full left half block (very obvious)

          -- Horizontal caps stay off while the active glyph itself is hidden.
          show_start = false,
          show_end = false,
          -- show_start = true, -- restore the top reverse-L underline
          -- show_end = true, -- restore the bottom reverse-L underline

          show_exact_scope = false, -- only matters when a scope underline is enabled
          -- show_exact_scope = true, -- underline from exact TS node (more to the right)

          injected_languages = true, -- scopes inside injections (JS in HTML, …)
          -- injected_languages = false,

          -- Reuse the exact bracket groups so ibl's extmark hook finds the same depth color.
          highlight = rainbow_names,
          -- highlight = "IblScope", -- single bright color instead of rainbow
          -- highlight = { "IblScope" },

          -- ibl's ECMA map omits class_body, so the outer class scope disappears.
          -- Apex is also missing upstream; register both gaps explicitly.
          include = {
            node_type = {
              javascript = { "class_body" },
              typescript = { "class_body" },
              tsx = { "class_body" },
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
            "markdown", -- render-markdown owns prose structure
            "markdown.mdx",
            -- "text", -- also suppress guides in plain text buffers
          },
          buftypes = {
            "terminal",
            "nofile",
            "quickfix",
            "prompt",
          },
        },
      })

      -- Match the enclosing bracket depth, then paint that exact color in the number gutter.
      hooks.register(hooks.type.SCOPE_HIGHLIGHT, function(tick, bufnr, scope, scope_index)
        local highlight_index = hooks.builtin.scope_highlight_from_extmark(tick, bufnr, scope, scope_index)
        paint_scope_gutter(bufnr, scope, highlight_index)
        return highlight_index
      end)
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
