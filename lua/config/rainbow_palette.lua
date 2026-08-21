--------------------------------------------------------------------------------
-- Shared rainbow palette — brackets (rainbow-delimiters) + indent scope (ibl)
-- Edit hexes here once; both plugins pick them up. Order is high-contrast
-- between adjacent levels (not strict ROYGBIV).
--------------------------------------------------------------------------------

local M = {}

-- { highlight_group_name, guifg }
M.palette = {
  { "RainbowDelimiterCustom1", "#EB6F92" }, -- love
  { "RainbowDelimiterCustom2", "#9CCFD8" }, -- foam
  { "RainbowDelimiterCustom3", "#F6C177" }, -- gold
  { "RainbowDelimiterCustom4", "#C4A7E7" }, -- iris
  { "RainbowDelimiterCustom5", "#31748F" }, -- pine
  { "RainbowDelimiterCustom6", "#EBBCBA" }, -- rose
  { "RainbowDelimiterCustom7", "#B4637A" }, -- deep love
  { "RainbowDelimiterCustom8", "#56949F" }, -- deep foam
  { "RainbowDelimiterCustom9", "#C49A5A" }, -- deep gold
  { "RainbowDelimiterCustom10", "#907AA9" }, -- deep iris
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
