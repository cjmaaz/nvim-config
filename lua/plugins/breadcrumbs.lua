--------------------------------------------------------------------------------
-- Breadcrumbs — clickable path + symbol navigation in the winbar (dropbar.nvim)
-- Sources: path plus LSP / Treesitter / Markdown fallbacks, chosen automatically.
-- Needs: Neovim 0.11+; icons and fzf-native are optional enhancements.
-- Active alternate: nvim-navic in Lualine's native winbar (statusline.lua).
--------------------------------------------------------------------------------

--- Neutral theme-aware menu chrome retained for the disabled Dropbar alternate.
local function apply_dropbar_hl()
  local chrome = require("config.ui_chrome")
  local bg, fg = chrome.panel_bg, chrome.panel_fg
  local selected_bg = chrome.separator_fg

  -- Keep the bar part of the editor plane; only dropdown menus use panel_bg.
  vim.api.nvim_set_hl(0, "WinBar", { fg = fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = chrome.muted_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "DropBarMenuNormalFloat", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "DropBarMenuFloatBorder", { fg = chrome.divider_fg, bg = bg })
  -- vim.api.nvim_set_hl(0, "DropBarMenuFloatBorder", { fg = chrome.border_fg, bg = bg }) -- rose border

  for _, group in ipairs({
    "DropBarCurrentContext",
    "DropBarHover",
    "DropBarMenuCurrentContext",
    "DropBarMenuHoverEntry",
    "DropBarPreview",
  }) do
    vim.api.nvim_set_hl(0, group, { fg = chrome.divider_fg, bg = selected_bg })
  end
  vim.api.nvim_set_hl(0, "DropBarCurrentContextIcon", { link = "DropBarCurrentContext" })
  vim.api.nvim_set_hl(0, "DropBarCurrentContextName", { link = "DropBarCurrentContext" })
  vim.api.nvim_set_hl(0, "DropBarMenuHoverIcon", { fg = chrome.divider_fg, bg = selected_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuHoverSymbol", { fg = chrome.divider_fg, bg = selected_bg, bold = true })

  vim.api.nvim_set_hl(0, "DropBarIconUISeparator", { fg = chrome.divider_fg })
  vim.api.nvim_set_hl(0, "DropBarIconUISeparatorMenu", { link = "DropBarIconUISeparator" })
  vim.api.nvim_set_hl(0, "DropBarIconUIIndicator", { fg = chrome.border_fg, bold = true })
  vim.api.nvim_set_hl(0, "DropBarIconUIPickPivot", { fg = chrome.title_fg, bold = true })
  vim.api.nvim_set_hl(0, "DropBarFzfMatch", { fg = chrome.title_fg, bold = true })
  vim.api.nvim_set_hl(0, "DropBarMenuSbar", { bg = selected_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuThumb", { bg = chrome.divider_fg })
  -- Previous/default chrome: remove this helper + its ColorScheme autocmd.
end

return {
  {
    "Bekaboo/dropbar.nvim",
    enabled = false, -- temporarily hide the breadcrumb winbar
    -- enabled = true, -- restore the winbar and breadcrumb mappings
    -- The plugin's startup file installs lightweight lazy autocmds itself.
    lazy = false,
    dependencies = {
      {
        "nvim-tree/nvim-web-devicons",
        enabled = vim.g.have_nerd_font,
      },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    config = function()
      local dropbar = require("dropbar.api")

      vim.o.mousemoveevent = true -- hover + preview for winbar/menu symbols
      vim.keymap.set("n", "<leader>;", dropbar.pick, { desc = "Pick symbols in winbar" })
      vim.keymap.set("n", "[;", dropbar.goto_context_start, { desc = "Go to start of current context" })
      vim.keymap.set("n", "];", dropbar.select_next_context, { desc = "Select next context" })

      apply_dropbar_hl()
      local hl_group = vim.api.nvim_create_augroup("dropbar_theme_hl", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = hl_group,
        callback = apply_dropbar_hl,
      })
      -- dropbar defines its default groups on the first FileType; reapply after it.
      vim.api.nvim_create_autocmd("FileType", {
        group = hl_group,
        once = true,
        callback = function()
          vim.schedule(apply_dropbar_hl)
        end,
      })
    end,
  },
}
