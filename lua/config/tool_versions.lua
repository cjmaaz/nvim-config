--------------------------------------------------------------------------------
-- External tool versions — exact Mason/scaffold pins reviewed together.
--------------------------------------------------------------------------------

local M = {}

M.mason = {
  -- Startup Lua/web toolchain.
  ["lua-language-server"] = "3.19.1",
  stylua = "v2.5.2",
  prettierd = "0.29.0",

  -- On-demand language servers.
  basedpyright = "1.40.1",
  clangd = "22.1.6",
  ["css-lsp"] = "4.10.0",
  ["html-lsp"] = "4.10.0",
  jdtls = "v1.60.0",
  ["json-lsp"] = "4.10.0",
  ["rust-analyzer"] = "2026-09-07",
  ["typescript-language-server"] = "6.0.0",
  ["yaml-language-server"] = "1.24.0",
  ["apex-language-server"] = "v67.17.2",

  -- On-demand linters.
  eslint_d = "15.0.3",
  ruff = "0.16.7",
  sqlfluff = "4.3.0",
  shellcheck = "v0.11.0",
  stylelint = "17.14.1",
  markdownlint = "0.49.1",
}

M.scaffold = {
  typescript = "6.0.3",
  tsx = "4.23.13",
  types_node = "24.13.3",
  create_vite = "9.2.0",
  vite = "8.2.2",
  pytest = "9.1.1",
}

function M.mason_spec(name)
  local version = assert(M.mason[name], "Missing Mason version pin for " .. tostring(name))
  return { name, version = version }
end

return M
