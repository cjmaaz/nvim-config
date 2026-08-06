--------------------------------------------------------------------------------
-- Linting — nvim-lint (external linters → vim.diagnostic)
-- Refs: CodeOSS linting.lua; Kickstart plugins/lint.lua (autocmd pattern).
-- Complements LSP (rules engines) and conform (format). Same ]d / <leader>e UI.
-- Linters: listed for common fts; Mason-install on first matching FileType (lazy).
-- Alts: LSP-only diagnostics · none-ls · manual :MasonInstall only.
--------------------------------------------------------------------------------

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" }, -- load when you open a file
    -- event = "VeryLazy",
    dependencies = {
      "mason-org/mason.nvim", -- needed for lazy package install
    },
    keys = {
      {
        "<leader>cl", -- Code Lint (pairs with <leader>cf format)
        function()
          -- ignore_errors: missing binary (pre-Mason) should not spam ERROR notify
          require("lint").try_lint(nil, { ignore_errors = true })
        end,
        desc = "Lint current buffer",
      },
      {
        "<leader>tl", -- Toggle auto-lint (when autocmd is enabled below)
        function()
          vim.g.disable_autolint = not vim.g.disable_autolint
          vim.notify(
            "Auto-lint: " .. (vim.g.disable_autolint and "disabled" or "enabled")
          )
        end,
        desc = "Toggle auto-lint",
      },
    },
    config = function()
      local lint = require("lint")

      -- --- Which linter runs for which filetype ---
      -- To turn a language OFF: comment its line (statusline-style).
      -- To change tool: swap the name (must exist in nvim-lint; Mason name in map below).
      -- Example disable Python: -- python = { "ruff" },
      lint.linters_by_ft = {
        -- Web / JS
        javascript = { "eslint_d" }, -- fast ESLint daemon (usually needs project eslint)
        -- javascript = { "eslint" }, -- non-daemon eslint
        javascriptreact = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },

        -- Python
        python = { "ruff" }, -- lint only (formatting is conform's ruff_format)
        -- python = { "ruff", "mypy" }, -- add type checker if you install mypy

        -- SQL
        sql = { "sqlfluff" }, -- dialect set below (postgres)

        -- Shell
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        -- zsh = { "shellcheck" }, -- shellcheck is weak on zsh; enable if you want anyway

        -- CSS
        css = { "stylelint" },
        scss = { "stylelint" },
        -- less = { "stylelint" },

        -- Markdown / prose
        markdown = { "markdownlint" },
        -- markdown = { "markdownlint-cli2" }, -- alt CLI if you prefer

        -- Lua (optional — lua_ls already diagnoses a lot)
        -- lua = { "selene" }, -- uncomment for extra Lua lint via Selene
        -- lua = { "luacheck" },

        -- YAML / Docker / JSON (uncomment if you use them)
        -- yaml = { "yamllint" },
        -- dockerfile = { "hadolint" },
        -- json = { "jsonlint" },
      }

      -- SQLFluff: JSON for nvim-lint; pin dialect when the project has no .sqlfluff.
      if lint.linters.sqlfluff then
        lint.linters.sqlfluff.args = {
          "lint",
          "--format=json",
          "--dialect=postgres", -- change to mysql / snowflake / … if needed
          -- "--dialect=ansi",
          "-",
        }
      end

      -- --- Mason package names (nvim-lint name → :MasonInstall name) ---
      local linter_to_mason = {
        eslint_d = "eslint_d",
        -- eslint = "eslint",
        ruff = "ruff",
        sqlfluff = "sqlfluff",
        shellcheck = "shellcheck",
        stylelint = "stylelint",
        markdownlint = "markdownlint",
        -- ["markdownlint-cli2"] = "markdownlint-cli2",
        selene = "selene",
        luacheck = "luacheck",
        yamllint = "yamllint",
        hadolint = "hadolint",
        -- jsonlint = "jsonlint",
      }

      -- Filetype → Mason packages to install on first open.
      local mason_by_ft = {}
      for ft, linters in pairs(lint.linters_by_ft) do
        for _, name in ipairs(linters or {}) do
          local pkg = linter_to_mason[name]
          if pkg then
            mason_by_ft[ft] = mason_by_ft[ft] or {}
            table.insert(mason_by_ft[ft], pkg)
          end
        end
      end

      local ensure_once = {} -- avoid re-queueing the same package

      -- nvim-lint notifies ERROR on ENOENT; during BufEnter that aborts the autocmd
      -- (E5108 via neo-tree open, etc.). Only run linters whose cmd is on PATH.
      -- Declared before ensure_mason_package so the install callback can call it.
      local function available_linters(ft)
        local names = {}
        for _, name in ipairs(lint.linters_by_ft[ft] or {}) do
          local linter = lint.linters[name]
          if type(linter) == "function" then
            linter = linter()
          end
          local cmd = linter and linter.cmd
          if type(cmd) == "function" then
            cmd = cmd()
          end
          if type(cmd) == "string" and vim.fn.executable(cmd) == 1 then
            names[#names + 1] = name
          end
        end
        return names
      end

      local function ensure_mason_package(pkg_name)
        local ok_reg, registry = pcall(require, "mason-registry")
        if not ok_reg then
          return
        end
        registry.refresh(function()
          local ok, pkg = pcall(registry.get_package, pkg_name)
          if not ok or not pkg then
            vim.notify("Mason package not found: " .. pkg_name, vim.log.levels.WARN)
            return
          end
          if pkg:is_installed() or ensure_once[pkg_name] then
            return
          end
          ensure_once[pkg_name] = true
          vim.notify("Installing " .. pkg_name .. " (first lint filetype)…", vim.log.levels.INFO)
          pkg:install():once("closed", function()
            if not pkg:is_installed() then
              ensure_once[pkg_name] = nil
              vim.notify("Failed to install " .. pkg_name, vim.log.levels.ERROR)
              return
            end
            -- Lint current buffer once the tool is ready (if still on a matching ft).
            vim.schedule(function()
              if vim.g.disable_autolint or not vim.bo.modifiable then
                return
              end
              local names = available_linters(vim.bo.filetype)
              if #names > 0 then
                lint.try_lint(names, { ignore_errors = true })
              end
            end)
          end)
        end)
      end

      local function ensure_linters_for_ft(ft)
        for _, pkg in ipairs(mason_by_ft[ft] or {}) do
          ensure_mason_package(pkg)
        end
      end

      local function run_lint(bufnr)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        if vim.g.disable_autolint or vim.b[bufnr].disable_autolint then
          return -- global / buffer toggle off (<leader>tl or vim.b.disable_autolint = true)
        end
        if not vim.bo[bufnr].modifiable then
          return -- skip hover popups / readonly buffers
        end
        local ft = vim.bo[bufnr].filetype
        ensure_linters_for_ft(ft) -- kick off Mason install if needed; lint retries on closed
        local names = available_linters(ft)
        if #names > 0 then
          -- ignore_errors: never let a spawn failure abort BufEnter (neo-tree open)
          lint.try_lint(names, { ignore_errors = true })
        end
      end

      local lint_group = vim.api.nvim_create_augroup("user_lint", { clear = true })

      -- Lazy-install when filetype is set (Decision 3).
      vim.api.nvim_create_autocmd("FileType", {
        group = lint_group,
        desc = "Lazy Mason-install linters for this filetype",
        callback = function(event)
          ensure_linters_for_ft(event.match)
        end,
      })

      -- --- Auto-lint (Decision 2: on by default) ---
      -- Runs on enter, after save, and when you leave insert.
      -- If this is slow, noisy, or fights a project tool: either
      --   (a) press <leader>tl to disable until restart / toggle again, or
      --   (b) comment out this autocmd block and use <leader>cl only.
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_group,
        desc = "Run nvim-lint on buffer events",
        callback = function(event)
          run_lint(event.buf)
        end,
      })
      -- Manual-only alternative (uncomment means: delete/comment the autocmd above):
      -- -- no BufEnter/BufWritePost/InsertLeave autocmd — lint only via <leader>cl
    end,
  },
}
