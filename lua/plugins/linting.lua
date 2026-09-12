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
      local tool_versions = require("config.tool_versions")

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

      local ensure_pending = {} -- package → originating buffers waiting for install

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

      local function lint_origin(bufnr, expected_ft)
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end
        if
          vim.g.disable_autolint
          or vim.b[bufnr].disable_autolint
          or not vim.bo[bufnr].modifiable
          or vim.bo[bufnr].filetype ~= expected_ft
        then
          return
        end
        local names = available_linters(expected_ft)
        if #names > 0 then
          vim.api.nvim_buf_call(bufnr, function()
            lint.try_lint(names, { ignore_errors = true })
          end)
        end
      end

      local function ensure_mason_package(pkg_name, bufnr, ft)
        local ok_reg, registry = pcall(require, "mason-registry")
        if not ok_reg then
          return
        end
        if ensure_pending[pkg_name] then
          if bufnr then
            ensure_pending[pkg_name][bufnr] = ft
          end
          return
        end
        ensure_pending[pkg_name] = {}
        if bufnr then
          ensure_pending[pkg_name][bufnr] = ft
        end
        registry.refresh(function()
          local ok, pkg = pcall(registry.get_package, pkg_name)
          if not ok or not pkg then
            vim.notify("Mason package not found: " .. pkg_name, vim.log.levels.WARN)
            ensure_pending[pkg_name] = nil
            return
          end
          local pin = tool_versions.mason[pkg_name]
          if not pin then
            ensure_pending[pkg_name] = nil
            vim.notify("No exact Mason version pin for " .. pkg_name, vim.log.levels.ERROR)
            return
          end
          local installed_version = pkg:is_installed() and pkg:get_installed_version() or nil
          if installed_version == pin then
            ensure_pending[pkg_name] = nil
            return
          end
          local function on_closed(success)
            local origins = ensure_pending[pkg_name] or {}
            ensure_pending[pkg_name] = nil
            local current_version = pkg:is_installed() and pkg:get_installed_version() or nil
            if success == false or current_version ~= pin then
              vim.notify(
                string.format("Failed to install %s at pinned version %s", pkg_name, pin),
                vim.log.levels.ERROR
              )
              return
            end
            vim.schedule(function()
              for origin, origin_ft in pairs(origins) do
                lint_origin(origin, origin_ft)
              end
            end)
          end
          if pkg.is_installing and pkg:is_installing() then
            pkg:get_install_handle():if_present(function(handle)
              handle:once("closed", on_closed)
            end)
            return
          end
          vim.notify(string.format("Installing %s@%s (first lint filetype)…", pkg_name, pin), vim.log.levels.INFO)
          pkg:install({ version = pin, force = installed_version ~= nil, strict = false }, on_closed)
        end)
      end

      local function ensure_linters_for_ft(ft, bufnr)
        for _, pkg in ipairs(mason_by_ft[ft] or {}) do
          ensure_mason_package(pkg, bufnr, ft)
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
        ensure_linters_for_ft(ft, bufnr) -- kick off Mason install if needed; lint retries on closed
        lint_origin(bufnr, ft) -- ignore spawn failures and keep the originating buffer scoped
      end

      local lint_group = vim.api.nvim_create_augroup("user_lint", { clear = true })

      -- Lazy-install when filetype is set (Decision 3).
      vim.api.nvim_create_autocmd("FileType", {
        group = lint_group,
        desc = "Lazy Mason-install linters for this filetype",
        callback = function(event)
          ensure_linters_for_ft(event.match, event.buf)
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
