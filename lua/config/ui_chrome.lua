--------------------------------------------------------------------------------
-- Shared UI chrome — panel backgrounds for which-key, neo-tree, Telescope
-- Noctis Bordo editor bg0 is #312A2D; panels use a slightly darker sibling so
-- floats/sidebars read as inset chrome without pure #000 harshness.
--------------------------------------------------------------------------------

local M = {}

-- Bordo bg0 (#312A2D) nudged darker (~same hue, lower luminance).
M.panel_bg = "#241F22"
-- M.panel_bg = "#2B2528" -- stock Bordo bg2 (only a hair darker than editor)
-- M.panel_bg = "#1C181A" -- deeper still
-- M.panel_bg = "#000000" -- pure black (harsh on Bordo)

M.panel_fg = "#C9BEC2" -- Bordo fg
M.border_fg = "#D17B9A" -- Bordo rose
M.title_fg = "#F6C38A" -- Bordo yellow
M.separator_fg = "#3C2F34" -- Bordo bg1

return M
