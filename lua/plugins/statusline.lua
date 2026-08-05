--------------------------------------------------------------------------------
-- Statusline: lualine + file icons
-- Refs: CodeOSS ui.lua (standalone lualine); Craftzdog/LazyVim only tweak LazyVim's.
-- Alternatives to lualine (pick one ecosystem later — don't enable two bars):
--   - echasnovski/mini.statusline  (lighter, mini.nvim family)
--   - rebelot/heirline.nvim        (max control, more code)
--   - built-in 'statusline' string (no plugin; weak icons/git unless you script it)
--------------------------------------------------------------------------------

return {
  {
    "nvim-lualine/lualine.nvim",
    -- VeryLazy: after UI start. Alternatives:
    --   event = "UIEnter"
    --   lazy = false  -- load at startup (slightly slower open, bar appears sooner)
    event = "VeryLazy",
    dependencies = {
      -- Filetype icons. Alternative: echasnovski/mini.icons (what current LazyVim prefers).
      {
        "nvim-tree/nvim-web-devicons",
        enabled = vim.g.have_nerd_font,
      },
    },
    opts = {
      options = {
        -- "auto" follows colorscheme. Or a built-in name: "auto", "codedark", …
        -- Custom table: see :help lualine-themes
        theme = "auto",

        -- Thin separators. Powerline-style (needs Nerd Font glyphs):
        -- component_separators = { left = "", right = "" },
        -- section_separators = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },

        -- true + vim.opt.laststatus = 3 → one bar for all windows.
        -- false + laststatus = 2 → one bar per split.
        globalstatus = true,

        -- disabled_filetypes = { statusline = { "alpha", "dashboard" } }, -- hide on splash screens
        -- ignore_focus = { "NvimTree", "neo-tree" }, -- keep showing "last" file when focus is a sidebar
        -- always_divide_middle = true, -- force left/right sections to stay split
        -- icons_enabled = true, -- false = text-only components even with an icon plugin
      },
      sections = {
        -- Layout: lualine_a .. _c (left) | lualine_x .. _z (right)
        -- Inactive windows use `inactive_sections` if you define it.
        lualine_a = { "mode" },
        -- "mode" alternatives: { "mode", fmt = function(s) return s:sub(1, 1) end } -- first letter only

        lualine_b = {
          "branch", -- needs git; empty outside a repo
          "diff", -- counts; richer when gitsigns is loaded
          -- "branch" alt: { "branch", icon = "" },
          -- "diff" alt: { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
        },

        lualine_c = {
          {
            "filename",
            -- path: 0 = name, 1 = relative, 2 = absolute, 3 = absolute with ~ for home
            path = 1,
            -- file_status = true, -- show [+] modified, [-] readonly, etc.
            -- newfile_status = true, -- flag buffers not yet on disk
            -- shorting_target = 40, -- shorten long paths to keep the bar readable
            -- symbols = { modified = "●", readonly = "", unnamed = "[No Name]" },
          },
          -- Optional mid components:
          -- "filesize",
          -- { "searchcount", maxcount = 999 }, -- matches when searching
        },

        lualine_x = {
          "diagnostics", -- LSP/Vim diagnostics; empty until an LSP (or similar) attaches
          -- { "diagnostics", sources = { "nvim_diagnostic" }, sections = { "error", "warn" } },
          "encoding", -- e.g. utf-8; hide if you always use utf-8: omit this entry
          "fileformat", -- unix/dos/mac line endings
          "filetype", -- name + icon when web-devicons/mini.icons is present
          -- "lsp_status", -- Neovim 0.10+ LSP client names (if you prefer over plain filetype)
        },

        lualine_y = { "progress" }, -- % through buffer; alt: "selectioncount"
        lualine_z = { "location" }, -- line:col; alt: { "location", padding = { left = 0, right = 1 } }
      },

      -- Shown in windows that are not current (only if globalstatus = false):
      -- inactive_sections = {
      --   lualine_c = { { "filename", path = 1 } },
      --   lualine_x = { "location" },
      -- },

      -- Extra bars (usually leave empty while learning):
      -- tabline = {},
      -- winbar = {},
      -- inactive_winbar = {},

      -- extensions = { "lazy", "fugitive", "nvim-tree" }, -- nicer sections inside those UIs
    },
  },
}
