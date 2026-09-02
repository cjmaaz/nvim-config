--------------------------------------------------------------------------------
-- Shared file icons — one nvim-web-devicons registry for every UI surface.
-- Apex source files use the Nerd Font Salesforce cloud in the footer,
-- bufferline, Neo-tree, Telescope, and any other devicons consumer.
--------------------------------------------------------------------------------

local SALESFORCE_ICON = "󰢎" -- nf-md-salesforce
local SALESFORCE_BLUE = "#00A1E0"
-- local SALESFORCE_BLUE = "#1798C1" -- slightly muted Salesforce blue

local function salesforce_icon()
  return {
    icon = SALESFORCE_ICON,
    color = SALESFORCE_BLUE,
    cterm_color = "39",
    name = "Salesforce",
  }
end

local extension_icons = {
  apex = salesforce_icon(),
  cls = salesforce_icon(),
  trigger = salesforce_icon(),
}

return {
  {
    "nvim-tree/nvim-web-devicons",
    enabled = vim.g.have_nerd_font,
    lazy = true, -- load with the first statusline/explorer/bufferline consumer
    -- lazy = false, -- initialize icons before every UI plugin at startup
    opts = {
      -- Non-strict consumers resolve icons by filename-like extension keys.
      override = vim.deepcopy(extension_icons),
      -- Strict consumers such as file explorers resolve the explicit extension.
      override_by_extension = extension_icons,
    },
    config = function(_, opts)
      local devicons = require("nvim-web-devicons")
      devicons.setup(opts)
      devicons.set_icon_by_filetype({
        apex = "apex",
        apexcode = "apex",
      })
    end,
  },
}
