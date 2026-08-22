--------------------------------------------------------------------------------
-- Shared rainbow palette — brackets (rainbow-delimiters) + indent scope (ibl)
-- Edit hexes here once; both plugins pick them up. Order is high-contrast
-- between adjacent levels (not strict ROYGBIV).
--------------------------------------------------------------------------------

local M = {}

-- { highlight_group_name, guifg }
M.palette = {
  { "RainbowDelimiterCustom1", "#F38BA8" }, -- red
  { "RainbowDelimiterCustom2", "#A6E3A1" }, -- green
  { "RainbowDelimiterCustom3", "#F9E2AF" }, -- yellow
  { "RainbowDelimiterCustom4", "#89DCEB" }, -- sky
  { "RainbowDelimiterCustom5", "#CBA6F7" }, -- mauve
  { "RainbowDelimiterCustom6", "#FAB387" }, -- peach
  { "RainbowDelimiterCustom7", "#94E2D5" }, -- teal
  { "RainbowDelimiterCustom8", "#F5C2E7" }, -- pink
  { "RainbowDelimiterCustom9", "#74C7EC" }, -- sapphire
  { "RainbowDelimiterCustom10", "#EBA0AC" }, -- maroon
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
