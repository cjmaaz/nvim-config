--------------------------------------------------------------------------------
-- Lightweight project detection shared by lazy-loading gates.
-- Must not require feature modules or start any process.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local SALESFORCE_MARKERS = { "sfdx-project.json", ".forceignore" }
local cache = {}

local function start_path(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_is_valid(bufnr) then
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name ~= "" then
      local stat = uv.fs_stat(name)
      if stat and stat.type == "file" then
        return vim.fs.dirname(name)
      end
      if stat and stat.type == "directory" then
        return name
      end
    end
  end
  return vim.fn.getcwd()
end

function M.salesforce_root(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) or ""
  local cwd = vim.fn.getcwd()
  local key = name ~= "" and name or ("cwd:" .. cwd)
  if cache[bufnr] and cache[bufnr].key == key then
    return cache[bufnr].root or nil
  end
  local marker = vim.fs.find(SALESFORCE_MARKERS, {
    path = start_path(bufnr),
    upward = true,
    type = "file",
  })[1]
  local root = marker and vim.fs.dirname(marker) or nil
  cache[bufnr] = { key = key, root = root or false }
  return root
end

function M.is_salesforce(bufnr)
  return M.salesforce_root(bufnr) ~= nil
end

function M.invalidate(bufnr)
  if bufnr then
    cache[bufnr] = nil
  else
    cache = {}
  end
end

M._test = {
  start_path = start_path,
}

return M
