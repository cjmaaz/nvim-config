--------------------------------------------------------------------------------
-- Shared Monokai Pro chrome — warm neutral surfaces + vivid semantic accents.
--------------------------------------------------------------------------------

local M = {}

M.base = "#221F22"
M.surface = "#19181A"
M.overlay = "#403E41"
M.muted = "#727072"
M.subtle = "#939293"
M.text = "#FCFCFA"
M.red = "#FF6188"
M.orange = "#FC9867"
M.yellow = "#FFD866"
M.green = "#A9DC76"
M.cyan = "#78DCE8"
M.magenta = "#AB9DF2"
M.white = "#FCFCFA"
M.dimmed1 = "#C1C0C0"
M.dimmed2 = "#939293"
M.dimmed3 = "#727072"
M.dimmed4 = "#5B595C"
M.dimmed5 = "#403E41"
M.highlight_low = "#2D2A2E"
M.highlight_med = M.dimmed4
M.highlight_high = M.dimmed3

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
M.border_fg = M.orange
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
