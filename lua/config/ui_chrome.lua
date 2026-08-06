--------------------------------------------------------------------------------
-- Shared UI chrome — lualine, bufferline, dropbar, which-key, neo-tree, Telescope
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
M.muted_fg = "#87757C" -- subdued labels / inactive bars

-- Bright, thin dividers shared by bars and panel borders.
M.divider_fg = "#E8E1E4" -- soft white; visible without pure-white glare
-- M.divider_fg = "#C9BEC2" -- quieter: match normal panel text

-- Selected rows / components sit one step above the panel background.
M.active_bg = "#3C2F34" -- Bordo bg1
-- M.active_bg = "#2B2528" -- subtler active fill
M.separator_fg = M.active_bg -- compatibility name used by existing chrome

return M
