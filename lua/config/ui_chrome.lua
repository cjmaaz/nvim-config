--------------------------------------------------------------------------------
-- Shared Rosé Pine Main chrome — bars, floats, pickers, sidebars, diagnostics.
--------------------------------------------------------------------------------

local M = {}

M.base = "#191724"
M.surface = "#1F1D2E"
M.overlay = "#26233A"
M.muted = "#6E6A86"
M.subtle = "#908CAA"
M.text = "#E0DEF4"
M.love = "#EB6F92"
M.gold = "#F6C177"
M.rose = "#EBBCBA"
M.pine = "#31748F"
M.foam = "#9CCFD8"
M.iris = "#C4A7E7"
M.highlight_low = "#21202E"
M.highlight_med = "#403D52"
M.highlight_high = "#524F67"

-- Inset panels remain distinct without introducing near-black islands.
M.panel_bg = M.surface
-- M.panel_bg = M.overlay -- brighter panels with stronger separation
M.panel_fg = M.text
M.border_fg = M.rose
-- M.border_fg = M.love -- stronger warning-like borders
M.title_fg = M.gold
M.muted_fg = M.subtle

-- Dividers stay readable but avoid the previous near-white glare.
M.divider_fg = M.subtle
-- M.divider_fg = M.text -- strongest edge contrast

-- Selected rows / components sit one step above the panel background.
M.active_bg = M.overlay
-- M.active_bg = M.highlight_med -- stronger selected-row fill
M.separator_fg = M.active_bg -- compatibility name used by existing chrome

return M
