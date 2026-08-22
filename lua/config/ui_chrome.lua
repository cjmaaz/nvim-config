--------------------------------------------------------------------------------
-- Catppuccin Mocha chrome with neutral near-black background overrides.
--------------------------------------------------------------------------------

local M = {}

M.base = "#18181B"
M.surface = "#141417"
M.overlay = "#27272C"
M.muted = "#71717A"
M.subtle = "#A6ADC8"
M.text = "#CDD6F4"
M.red = "#F38BA8"
M.orange = "#FAB387"
M.yellow = "#F9E2AF"
M.green = "#A6E3A1"
M.cyan = "#89DCEB"
M.teal = "#94E2D5"
M.magenta = "#CBA6F7"
M.pink = "#F5C2E7"
M.lavender = "#B4BEFE"
M.white = "#CDD6F4"
M.dimmed1 = "#BAC2DE"
M.dimmed2 = "#A6ADC8"
M.dimmed3 = "#7F849C"
M.dimmed4 = "#585B70"
M.dimmed5 = "#45475A"
M.highlight_low = "#27272C"
M.highlight_med = "#3F3F46"
M.highlight_high = "#52525B"

-- Compatibility semantic names used by existing UI modules.
M.love = M.red
M.gold = M.yellow
M.rose = M.orange
M.pine = M.green
M.foam = M.cyan
M.iris = M.magenta

-- Inset panels remain distinct without introducing near-black islands.
M.panel_bg = M.surface
-- M.panel_bg = M.overlay -- brighter panels with stronger separation
M.panel_fg = M.dimmed1
-- M.panel_fg = M.text -- maximum text contrast
M.border_fg = M.lavender
-- M.border_fg = M.red -- stronger warning-like borders
M.title_fg = M.yellow
M.muted_fg = M.subtle

-- Dividers stay readable but avoid the previous near-white glare.
M.divider_fg = M.dimmed3
-- M.divider_fg = M.text -- strongest edge contrast

-- Selected rows / components sit one step above the panel background.
M.active_bg = M.highlight_low
-- M.active_bg = M.overlay -- stronger selected-row fill
M.separator_fg = M.active_bg -- compatibility name used by existing chrome

return M
