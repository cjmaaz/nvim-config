--------------------------------------------------------------------------------
-- Shared rainbow palette — brackets (rainbow-delimiters) + indent scope (ibl)
-- Edit hexes here once; both plugins pick them up. Order is high-contrast
-- between adjacent levels (not strict ROYGBIV).
--------------------------------------------------------------------------------

local M = {}

-- { highlight_group_name, guifg }
M.palette = {
  { "RainbowDelimiterCustom1", "#FF6188" }, -- red / pink
  { "RainbowDelimiterCustom2", "#A9DC76" }, -- green
  { "RainbowDelimiterCustom3", "#FFD866" }, -- yellow
  { "RainbowDelimiterCustom4", "#78DCE8" }, -- cyan
  { "RainbowDelimiterCustom5", "#AB9DF2" }, -- magenta
  { "RainbowDelimiterCustom6", "#FC9867" }, -- orange
  { "RainbowDelimiterCustom7", "#E14775" }, -- deep red
  { "RainbowDelimiterCustom8", "#86B45B" }, -- deep green
  { "RainbowDelimiterCustom9", "#D8AC4D" }, -- deep yellow
  { "RainbowDelimiterCustom10", "#8C7BD1" }, -- deep magenta
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
