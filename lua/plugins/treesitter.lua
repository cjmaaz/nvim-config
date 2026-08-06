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
