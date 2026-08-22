--------------------------------------------------------------------------------
-- Compact per-window labels — rounded filename + focused LSP symbol context.
-- Ref: Craftzdog incline.nvim; extended here with nvim-navic context.
--------------------------------------------------------------------------------

return {
  {
    "b0o/incline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
      "SmiteshP/nvim-navic",
    },
    config = function()
      local chrome = require("config.ui_chrome")
      local devicons = require("nvim-web-devicons")
      local navic = require("nvim-navic")

      navic.setup({
        highlight = true,
        separator = " > ",
        depth_limit = 3,
        -- depth_limit = 0, -- show the complete symbol chain
        lazy_update_context = true,
      })

      local group = vim.api.nvim_create_augroup("incline_navic_attach", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentSymbolProvider then
            pcall(navic.attach, client, event.buf)
          end
        end,
      })

      require("incline").setup({
        hide = {
          cursorline = "smart",
          focused_win = false,
          only_win = false,
        },
        ignore = {
          buftypes = "special",
          filetypes = { "neo-tree", "SFTerm" },
          floating_wins = true,
          unlisted_buffers = true,
          wintypes = "special",
        },
        window = {
          margin = { horizontal = 1, vertical = 0 },
          padding = 0,
          placement = { horizontal = "right", vertical = "top" },
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          local icon, icon_color = devicons.get_icon_color(filename)
          local bg = props.focused and chrome.highlight_med or chrome.surface
          local fg = props.focused and chrome.text or chrome.muted_fg
          local result = {
            { "", guifg = bg },
            {
              icon and (" " .. icon .. " ") or " ",
              guibg = bg,
              guifg = icon_color or chrome.lavender,
            },
            {
              filename,
              guibg = bg,
              guifg = fg,
              gui = vim.bo[props.buf].modified and "bold,italic" or "bold",
            },
          }

          if props.focused and navic.is_available(props.buf) then
            local data = navic.get_data(props.buf) or {}
            local first = math.max(1, #data - 2)
            for index = first, #data do
              local item = data[index]
              result[#result + 1] = { " > ", guibg = bg, guifg = chrome.muted_fg }
              result[#result + 1] = {
                (item.icon or "") .. (item.name or ""),
                guibg = bg,
                guifg = index == #data and chrome.magenta or chrome.subtle,
              }
            end
          end

          if vim.bo[props.buf].modified then
            result[#result + 1] = { " ●", guibg = bg, guifg = chrome.yellow }
          end
          result[#result + 1] = { " ", guibg = bg }
          result[#result + 1] = { "", guifg = bg }
          return result
        end,
      })
    end,
  },
}
