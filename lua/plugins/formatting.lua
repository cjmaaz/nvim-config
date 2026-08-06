--------------------------------------------------------------------------------
-- Formatting — conform.nvim (formatters + optional format-on-save)
-- Refs: Kickstart SECTION 7 (FoS allowlist); CodeOSS formatting.lua (toggle).
-- <leader>cf format · <leader>tf toggle FoS (not <leader>f — File/Find / neo-tree).
-- Alts: LSP-only vim.lsp.buf.format · none-ls (older).
--------------------------------------------------------------------------------

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" }, -- load before write (for FoS when allowlisted)
    -- event = { "BufReadPost", "BufNewFile" }, -- earlier load
    cmd = { "ConformInfo" }, -- :ConformInfo debugger
    keys = {
      {
        "<leader>cf", -- Code Format (avoids clash with <leader>f File/Find)
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "x" }, -- normal + visual range
        desc = "Format buffer",
      },
      -- { "<leader>f", function() … end, … }, -- CodeOSS letter; we keep <leader>f for neo-tree
      {
        "<leader>tf", -- Toggle Format-on-save disable flag
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify(
            "Format on save: "
              .. (vim.g.disable_autoformat and "disabled" or "enabled (allowlisted fts only)")
          )
        end,
        desc = "Toggle format on save",
      },
    },
    opts = {
      notify_on_error = false, -- quieter; set true to see formatter failures
      -- notify_on_error = true,
      default_format_opts = {
        lsp_format = "fallback", -- external formatter first, else LSP
        -- lsp_format = "never", -- never use LSP format
        -- lsp_format = "prefer", -- LSP first
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return -- global or buffer toggle off
        end
        -- Kickstart-style allowlist. <leader>tf still disables FoS globally.
        -- Skip java/markdown/apex (heavier or taste); uncomment when you want them.
        local enabled_filetypes = {
          -- java = true,
          javascript = true,
          javascriptreact = true,
          typescript = true,
          typescriptreact = true,
          html = true,
          css = true,
          scss = true,
          json = true,
          jsonc = true,
          yaml = true,
          lua = true, -- stylua (auto via mason-tool-installer)
          python = true, -- ruff_format (Mason on demand / PATH)
          -- markdown = true,
        }
        -- local enabled_filetypes = { ["*"] = true } -- not supported; list fts explicitly
        if not enabled_filetypes[vim.bo[bufnr].filetype] then
          return -- ft not allowlisted → no FoS (default)
        end
        return {
          timeout_ms = 3000, -- give slow formatters time
          -- timeout_ms = 500, -- Kickstart-ish snappier fail
          lsp_format = "fallback",
        }
      end,
      -- format_on_save = false, -- hard-disable FoS entirely
      -- format_on_save = { timeout_ms = 3000, lsp_format = "fallback" }, -- FoS for every ft
      formatters_by_ft = {
        c = { "clang_format" }, -- needs :MasonInstall clang-format
        cpp = { "clang_format" },
        css = { "prettierd" }, -- needs prettierd (or prettier below)
        -- css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd" },
        java = { "google_java_format" }, -- needs :MasonInstall google-java-format
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        lua = { "stylua" }, -- auto-installed via mason-tool-installer in lsp.lua
        markdown = { "prettierd" },
        python = { "ruff_format" }, -- alt: { "isort", "black" }
        -- python = { "ruff_organize_imports", "ruff_format" },
        rust = { "rustfmt" }, -- usually from rustup, not Mason
        scss = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        yaml = { "prettierd" },
        -- apex = {}, -- no dedicated formatter; <leader>cf uses LSP fallback
      },
    },
  },
}
