--------------------------------------------------------------------------------
-- Shared rainbow palette — brackets (rainbow-delimiters) + indent scope (ibl)
-- Edit hexes here once; both plugins pick them up. Order is high-contrast
-- between adjacent levels (not strict ROYGBIV).
--------------------------------------------------------------------------------

local M = {}

-- { highlight_group_name, guifg }
M.palette = {
  { "RainbowDelimiterCustom1", "#FF5555" }, -- vivid red
  { "RainbowDelimiterCustom2", "#F1FA8C" }, -- bright yellow
  { "RainbowDelimiterCustom3", "#8BE9FD" }, -- cyan
  { "RainbowDelimiterCustom4", "#FF79C6" }, -- pink / magenta
  { "RainbowDelimiterCustom5", "#50FA7B" }, -- green
  { "RainbowDelimiterCustom6", "#BD93F9" }, -- purple
  { "RainbowDelimiterCustom7", "#FFB86C" }, -- orange
  { "RainbowDelimiterCustom8", "#61AFEF" }, -- blue
  { "RainbowDelimiterCustom9", "#FF6E6E" }, -- coral
  { "RainbowDelimiterCustom10", "#E2E2A0" }, -- pale gold / khaki
}

--- Apply guifg (+ bold) for every palette group. Safe to call on ColorScheme.
---@param opts? { bold?: boolean }
function M.apply(opts)
  opts = opts or {}
  local bold = opts.bold
  if bold == nil then
    bold = true
  end
  for _, item in ipairs(M.palette) do
    vim.api.nvim_set_hl(0, item[1], { fg = item[2], bold = bold })
    -- vim.api.nvim_set_hl(0, item[1], { fg = item[2], bold = false })
  end
end

--- List of highlight group names only (for plugin `highlight = { … }` opts).
---@return string[]
function M.names()
  local names = {}
  for _, item in ipairs(M.palette) do
    names[#names + 1] = item[1]
  end
  return names
end

return M
