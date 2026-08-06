--------------------------------------------------------------------------------
-- LSP — Mason, servers, LspAttach maps (Neovim 0.12 vim.lsp.config / enable)
-- Refs: CodeOSS lsp.lua (split + apex + Telescope maps); Kickstart SECTION 6.
-- Minimal always-on: lua_ls (+ stylua via mason-tool-installer).
-- Other servers: install+enable on first FileType open (lazy).
-- Alts: ensure_installed everything (CodeOSS) · Kickstart grn/gra-only maps.
--------------------------------------------------------------------------------

return {
  {
    "folke/lazydev.nvim", -- Lua LSP extras for Neovim APIs (vim.*, plugins)
    ft = "lua", -- only when editing Lua
    -- event = "VeryLazy",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } }, -- luv types for vim.uv
        -- { path = "${3rd}/luassert/library", words = { "assert" } },
      },
    },
  },
  {
    "neovim/nvim-lspconfig", -- ships lsp/* configs consumed by vim.lsp.config
    event = { "BufReadPre", "BufNewFile", "VeryLazy" }, -- load before most buffers
    -- lazy = false, -- always load at startup
    dependencies = {
      { "mason-org/mason.nvim", opts = {} }, -- UI + install binaries (:Mason)
      "mason-org/mason-lspconfig.nvim", -- maps Mason pkgs ↔ lspconfig names
      "WhoIsSethDaniel/mason-tool-installer.nvim", -- ensure_installed at startup
      "saghen/blink.cmp", -- completion capabilities for LSP
      "b0o/SchemaStore.nvim", -- JSON/YAML schemas for jsonls / yamlls
      { "j-hui/fidget.nvim", opts = {} }, -- LSP progress in the corner
      -- { "folke/neodev.nvim", … }, -- older; prefer lazydev above
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities() -- tell servers about blink
      -- local capabilities = vim.lsp.protocol.make_client_capabilities() -- stock, no blink
      local schemastore = require("schemastore")

      vim.lsp.config("*", { capabilities = capabilities }) -- apply to every server

      local lsp_group = vim.api.nvim_create_augroup("user_lsp", { clear = true })

      -- --- LspAttach keymaps (buffer-local when a server attaches) ---
      vim.api.nvim_create_autocmd("LspAttach", {
        group = lsp_group,
        desc = "Configure LSP keymaps",
        callback = function(event)
          local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
          local function map(keys, func, desc, mode)
            vim.keymap.set(mode or "n", keys, func, {
              buffer = event.buf, -- only this buffer
              desc = "LSP: " .. desc,
            })
          end

          -- CodeOSS-style maps (Telescope where useful).
          -- Kickstart alt: grn rename, gra code_action, grD declaration, grd/grr via Telescope autocmd.
          map("K", vim.lsp.buf.hover, "Hover documentation")
          -- map("K", vim.lsp.buf.signature_help, "Signature help") -- if you prefer signatures on K
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gd", vim.lsp.buf.definition, "Go to definition")
          -- map("gd", require("telescope.builtin").lsp_definitions, "Go to definition") -- Telescope picker
          map("gI", vim.lsp.buf.implementation, "Go to implementation")
          map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          -- map("grn", vim.lsp.buf.rename, "Rename symbol") -- Kickstart / Neovim 0.11 default lettering
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          -- map("gra", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          map("gr", require("telescope.builtin").lsp_references, "References")
          -- map("gr", vim.lsp.buf.references, "References") -- quickfix instead of Telescope
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Document symbols")
          map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace symbols")

          -- Highlight other references of the symbol under the cursor (CursorHold).
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_group =
              vim.api.nvim_create_augroup("user_lsp_highlight_" .. event.buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = highlight_group,
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group = highlight_group,
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd("LspDetach", {
              group = highlight_group,
              buffer = event.buf,
              once = true,
              callback = function()
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = event.buf })
              end,
            })
          end

          -- Inlay hints (types/params inline); off until toggled.
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map("<leader>th", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, "Toggle inlay hints")
          end
        end,
      })

      -- --- Server configs (vim.lsp.config now; enable below / on-demand) ---
      ---@type table<string, vim.lsp.Config>
      local servers = {
        -- Always-on (minimal)
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = "Replace" }, -- expand call snippets
              -- completion = { callSnippet = "Disable" },
              diagnostics = { globals = { "vim" } }, -- allow vim global in config
              format = { enable = false }, -- stylua via conform instead
              -- format = { enable = true }, -- use lua_ls formatter
              hint = { enable = true }, -- inlay hints if you toggle <leader>th
              -- hint = { enable = false },
              workspace = { checkThirdParty = false }, -- quieter workspace prompts
            },
          },
        },

        -- On-demand (configured now; Mason install + enable on matching FileType)
        basedpyright = {}, -- Python (alt: pyright = {} · pylsp = {})
        -- pyright = {},
        clangd = {}, -- C / C++
        cssls = {}, -- CSS / SCSS
        html = {}, -- HTML
        jdtls = {}, -- Java (heavy; first open installs via Mason)
        jsonls = {
          settings = {
            json = {
              schemas = schemastore.json.schemas(), -- SchemaStore catalogs
              validate = { enable = true },
            },
          },
        },
        rust_analyzer = {}, -- Rust
        ts_ls = {}, -- JS / TS (alt: vtsls = {} like CodeOSS)
        -- vtsls = {},
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = "" }, -- use SchemaStore plugin instead
              schemas = schemastore.yaml.schemas(),
            },
          },
        },
      }

      for name, config in pairs(servers) do
        vim.lsp.config(name, config) -- register overrides; does not start the server
      end

      -- Apex (CodeOSS): JAR from Mason share path or $APEX_LS_JAR
      local apex_jar_path = vim.env.APEX_LS_JAR -- override: export APEX_LS_JAR=/path/to.jar
      if not apex_jar_path or apex_jar_path == "" then
        apex_jar_path = vim.fn.stdpath("data")
          .. "/mason/share/apex-language-server/apex-jorje-lsp.jar"
      end
      vim.lsp.config("apex_ls", {
        apex_jar_path = apex_jar_path,
        apex_enable_semantic_errors = true, -- surface semantic errors
        -- apex_enable_semantic_errors = false,
        apex_enable_completion_statistics = false, -- no completion telemetry
      })

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {}, -- empty: we don't mass-install (minimal + on-demand)
        -- ensure_installed = { "lua_ls", "ts_ls", … }, -- CodeOSS-style eager install
        automatic_enable = false, -- we call vim.lsp.enable ourselves
        -- automatic_enable = true, -- enable every installed Mason LSP
      })

      -- Always install these at startup (minimal toolchain).
      require("mason-tool-installer").setup({
        ensure_installed = {
          "lua-language-server", -- package name for lua_ls
          "stylua", -- Lua formatter used by conform
          "prettierd", -- FoS for web/json/yaml (formatting.lua allowlist)
          -- "ruff", -- optional: always keep Python format/lint ready
          -- "apex-language-server", -- or rely on on-demand Apex FileType hook
        },
        run_on_start = true, -- install missing on Neovim start
        -- run_on_start = false, -- only :MasonInstall manually
        start_delay = 1000, -- ms before first install run
        debounce_hours = 24, -- don't re-check constantly
      })

      vim.lsp.enable("lua_ls") -- always attach Lua LSP when editing Lua
      -- vim.lsp.enable({ "lua_ls", "ts_ls" }) -- enable several at once

      -- Install a Mason package if needed, then run on_done (on main loop).
      -- Single-flight: concurrent FileType (e.g. netrw opening several .cls) must not
      -- call pkg:install() twice — Mason asserts "Package is already installing."
      local ensure_pending = {} -- pkg_name → { on_done, … }

      local function ensure_mason_package(pkg_name, on_done)
        if ensure_pending[pkg_name] then
          table.insert(ensure_pending[pkg_name], on_done)
          return
        end
        ensure_pending[pkg_name] = { on_done }

        local function flush(ok)
          local cbs = ensure_pending[pkg_name] or {}
          ensure_pending[pkg_name] = nil
          if not ok then
            return
          end
          for _, cb in ipairs(cbs) do
            vim.schedule(cb)
          end
        end

        local registry = require("mason-registry")
        registry.refresh(function()
          local ok, pkg = pcall(registry.get_package, pkg_name)
          if not ok or not pkg then
            vim.notify("Mason package not found: " .. pkg_name, vim.log.levels.WARN)
            ensure_pending[pkg_name] = nil
            return
          end
          if pkg:is_installed() then
            flush(true)
            return
          end

          local function on_closed()
            if pkg:is_installed() then
              flush(true)
            else
              vim.notify("Failed to install " .. pkg_name, vim.log.levels.ERROR)
              ensure_pending[pkg_name] = nil
            end
          end

          -- Another path already kicked off install (or we raced past pending).
          if pkg:is_installing() then
            pkg:get_install_handle():if_present(function(handle)
              handle:once("closed", on_closed)
            end)
            return
          end

          vim.notify("Installing " .. pkg_name .. " (first open)…", vim.log.levels.INFO)
          pkg:install():once("closed", on_closed)
        end)
      end

      local function lsp_to_mason(server)
        local maps = require("mason-lspconfig").get_mappings()
        return maps.lspconfig_to_package[server] -- nil if not a Mason-backed server
      end

      -- Filetype → LSP server name(s) to install+enable on first open.
      local on_demand_by_ft = {
        python = { "basedpyright" }, -- alt list: { "pyright" }
        javascript = { "ts_ls" },
        javascriptreact = { "ts_ls" },
        typescript = { "ts_ls" },
        typescriptreact = { "ts_ls" },
        html = { "html" },
        css = { "cssls" },
        scss = { "cssls" },
        java = { "jdtls" },
        rust = { "rust_analyzer" },
        c = { "clangd" },
        cpp = { "clangd" },
        json = { "jsonls" },
        jsonc = { "jsonls" },
        yaml = { "yamlls" },
        -- go = { "gopls" },
      }

      local enabled_once = {} -- remember so we don't re-queue installs

      local function enable_server(server)
        if enabled_once[server] then
          vim.lsp.enable(server) -- already requested; just ensure enabled
          return
        end
        enabled_once[server] = true
        local pkg = lsp_to_mason(server)
        if not pkg then
          vim.lsp.enable(server) -- config-only / non-Mason package
          return
        end
        ensure_mason_package(pkg, function()
          vim.lsp.enable(server)
        end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = lsp_group,
        desc = "On-demand Mason install + LSP enable by filetype",
        callback = function(event)
          local servers_for_ft = on_demand_by_ft[event.match]
          if not servers_for_ft then
            return
          end
          for _, server in ipairs(servers_for_ft) do
            enable_server(server)
          end
        end,
      })

      -- Apex: install apex-language-server on first apex buffer, then enable.
      local function enable_apex_ls()
        if enabled_once["apex_ls"] then
          if vim.uv.fs_stat(apex_jar_path) then
            vim.lsp.enable("apex_ls")
          end
          return
        end
        enabled_once["apex_ls"] = true

        local function try_enable()
          if vim.uv.fs_stat(apex_jar_path) then
            vim.lsp.enable("apex_ls")
          else
            vim.notify_once(
              "Apex LSP JAR missing after install. Check :Mason / $APEX_LS_JAR.",
              vim.log.levels.WARN
            )
          end
        end
        if vim.uv.fs_stat(apex_jar_path) then
          try_enable()
          return
        end
        ensure_mason_package("apex-language-server", try_enable)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = lsp_group,
        pattern = { "apex", "apexcode" },
        callback = enable_apex_ls,
      })
    end,
  },
}
