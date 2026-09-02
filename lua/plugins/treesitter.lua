--------------------------------------------------------------------------------
-- Treesitter — parsers + highlight / indent / folds (nvim-treesitter main)
-- Refs: CodeOSS treesitter.lua; Kickstart SECTION 9 (same main API).
-- Requires: Neovim 0.12+, tree-sitter-cli, C compiler — see docs/TOOLS.md.
-- Alts: master branch (Nvim ≤0.11 only; frozen) · skip folds · no auto-install.
--------------------------------------------------------------------------------

local parsers = {
  -- Kickstart core
  "bash",
  "c",
  "diff",
  "html",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "query",
  "vim",
  "vimdoc",
  -- Common editing
  "css",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "python",
  "regex",
  "toml",
  "tsx",
  "typescript",
  "yaml",
  -- Java / JVM tooling (pom.xml, .properties, Gradle Groovy)
  "java",
  "xml",
  "properties",
  "groovy",
  -- Salesforce (CodeOSS)
  "apex",
  "soql",
  "sosl",
  "sflog",
  -- Systems languages
  "rust",
  "cpp",
  -- Extras (uncomment as needed)
  -- "dockerfile",
  -- "sql",
  -- "scss",
  -- "vue",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- new API (needs Nvim 0.12+); not frozen `master`
    lazy = false, -- load at startup so parsers are ready
    build = ":TSUpdate", -- refresh/compile parsers after plugin update
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.install(parsers) -- ensure curated list is installed

      local auto_install_missing = true -- install when opening an unknown filetype
      -- local auto_install_missing = false -- only the curated list above

      local function attach(bufnr, language)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        if not vim.treesitter.language.add(language) then
          return -- no parser available for this language
        end

        vim.treesitter.start(bufnr, language) -- highlight (+ injections)

        -- Folds (CodeOSS on; Kickstart leaves commented)
        vim.wo.foldmethod = "expr" -- fold using foldexpr
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- treesitter folds
        vim.wo.foldlevel = 99 -- start with folds open
        -- vim.wo.foldmethod = "manual" -- disable treesitter folds

        if vim.treesitter.query.get(language, "indents") then
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- TS indent when query exists
        end
      end

      local available = treesitter.get_available()

      vim.api.nvim_create_autocmd("FileType", {
        desc = "Enable Treesitter highlighting and indentation",
        callback = function(event)
          local language = vim.treesitter.language.get_lang(event.match)
          if not language then
            return
          end

          local installed = treesitter.get_installed("parsers")
          if vim.tbl_contains(installed, language) then
            attach(event.buf, language) -- already installed → enable now
          elseif auto_install_missing and vim.tbl_contains(available, language) then
            treesitter.install(language):await(function()
              vim.schedule(function()
                attach(event.buf, language) -- enable after install finishes
              end)
            end)
          else
            pcall(attach, event.buf, language) -- try anyway (parser maybe elsewhere)
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main", -- direct API compatible with nvim-treesitter main
    event = "VeryLazy", -- queries and maps are needed only after the editor settles
    -- lazy = false, -- make structural text objects available during startup
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      select = {
        -- Let an operator find the next matching object after the cursor.
        lookahead = true,
        -- lookahead = false, -- select only an object already under the cursor

        -- Whole function/class operations should behave like line objects.
        selection_modes = {
          ["@function.outer"] = "V",
          ["@class.outer"] = "V",
          ["@parameter.outer"] = "v",
        },

        -- Keep surrounding blank space out of selections.
        include_surrounding_whitespace = false,
        -- include_surrounding_whitespace = true, -- consume adjacent whitespace like `ap`
      },
    },
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)
      local select = require("nvim-treesitter-textobjects.select")

      local function textobject(lhs, query, desc)
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(query, "textobjects")
        end, { desc = desc })
      end

      textobject("af", "@function.outer", "Around Treesitter function")
      textobject("if", "@function.inner", "Inside Treesitter function")
      textobject("ac", "@class.outer", "Around Treesitter class")
      textobject("ic", "@class.inner", "Inside Treesitter class")
      textobject("aa", "@parameter.outer", "Around Treesitter argument")
      textobject("ia", "@parameter.inner", "Inside Treesitter argument")
    end,
  },
  {
    "windwp/nvim-ts-autotag", -- auto close/rename HTML / JSX / TSX tags
    event = { "BufReadPost", "BufNewFile" }, -- load when editing a buffer
    opts = {
      opts = {
        enable_close = true, -- insert matching close tag
        enable_rename = true, -- rename paired tag together
        enable_close_on_slash = true, -- </ auto-closes
      },
    },
  },
}
