--------------------------------------------------------------------------------
-- Statusline: lualine + file icons
--------------------------------------------------------------------------------

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy", -- load after startup UI is ready (not on the critical path)
    dependencies = {
      -- Filetype icons in the bar. Skip the plugin if you have no Nerd Font.
      {
        "nvim-tree/nvim-web-devicons",
        enabled = vim.g.have_nerd_font,
      },
    },
    opts = {
      options = {
        theme = "auto", -- follow whatever colorscheme you use later
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" }, -- flat look; try ""/"" later if you want powerline wedges
        globalstatus = true, -- one bar for the whole UI (pairs with laststatus = 3)
      },
      sections = {
        -- Left → right sections: a b c | x y z
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" }, -- git branch + added/changed/removed counts
        lualine_c = {
          {
            "filename",
            path = 1, -- 0 = name only, 1 = relative path, 2 = absolute
          },
        },
        lualine_x = {
          "diagnostics", -- empty until LSP; harmless to keep
          "encoding",
          "fileformat",
          "filetype", -- shows icon when web-devicons is enabled
        },
        lualine_y = { "progress" }, -- % through the file
        lualine_z = { "location" }, -- line:column
      },
    },
  },
}
