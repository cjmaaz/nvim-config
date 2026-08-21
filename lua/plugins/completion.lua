--------------------------------------------------------------------------------
-- Autocompletion — blink.cmp + LuaSnip
-- Refs: Kickstart SECTION 8 (preset default / <C-y>); CodeOSS Tab/CR accept.
-- Alts: nvim-cmp (older) · blink without LuaSnip (vim.snippet only).
--------------------------------------------------------------------------------

return {
  {
    "L3MON4D3/LuaSnip", -- snippet engine (expand/jump placeholders)
    version = "v2.*", -- pin major v2
    -- version = "*",
    build = (vim.fn.has("win32") == 0 and vim.fn.executable("make") == 1)
        and "make install_jsregexp" -- better snippet transforms when make exists
      or nil, -- skip build on Windows / no make (pure Lua still works)
    dependencies = { "rafamadriz/friendly-snippets" }, -- VS Code–style snippet packs
    config = function()
      require("luasnip").config.setup({
        history = true, -- remember last snippet for re-jump
        -- history = false,
        updateevents = "TextChanged,TextChangedI", -- live-update snippet nodes while typing
      })
      require("luasnip.loaders.from_vscode").lazy_load() -- load friendly-snippets lazily
      -- require("luasnip.loaders.from_lua").load({ paths = … }) -- your own lua snippets
    end,
  },
  {
    "saghen/blink.cmp", -- completion UI + LSP/path/buffer/snippet sources
    version = "1.*",
    event = "InsertEnter", -- load when you start inserting
    -- lazy = false,
    dependencies = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = {
        -- Kickstart: built-in-like; accept with <C-y>. See :help ins-completion.
        preset = "default", -- <C-n>/<C-p> select, <C-y> accept, <C-e> cancel
        -- preset = "super-tab", -- Tab accepts (blink built-in)
        -- preset = "enter", -- Enter accepts
        -- CodeOSS-style Tab / S-Tab / Enter (uncomment to use instead of <C-y>):
        -- ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        -- ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        -- ["<CR>"] = { "accept", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono", -- icon spacing for Nerd Font Mono
        -- nerd_font_variant = "normal",
      },
      completion = {
        documentation = {
          auto_show = false, -- Kickstart quiet; open docs with <C-space>
          -- auto_show = true, -- CodeOSS: show docs after delay
          auto_show_delay_ms = 500, -- used when auto_show = true
          -- auto_show_delay_ms = 300,
        },
      },
      snippets = {
        preset = "luasnip", -- expand via LuaSnip
        -- preset = "default", -- Neovim vim.snippet only (no LuaSnip)
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" }, -- full set
        -- default = { "lsp", "path", "snippets" }, -- drop buffer word noise
        -- default = { "lsp", "path" }, -- minimal
        per_filetype = {
          soql = function()
            if require("config.project_context").is_salesforce(0) then
              return { "soql", "snippets", "buffer" }
            end
            return { "snippets", "buffer" } -- standalone SOQL: no SF module/cache load
          end,
          -- soql = { "soql" }, -- schema only; no snippets/buffer words
        },
        providers = {
          soql = {
            name = "SOQL",
            module = "config.salesforce.completion",
            score_offset = 100, -- rank org fields/objects above buffer words
            -- score_offset = 0, -- let every source rank equally
          },
        },
      },
      signature = {
        enabled = true, -- show function signature help while typing
        -- enabled = false,
      },
      fuzzy = {
        implementation = "prefer_rust_with_warning", -- fast matcher; warns if Rust missing
        -- implementation = "lua", -- pure Lua; no download
        -- implementation = "prefer_rust", -- rust only, no warning
      },
    },
    opts_extend = { "sources.default" }, -- allow other specs to extend sources
  },
}
