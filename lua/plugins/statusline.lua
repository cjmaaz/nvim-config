--------------------------------------------------------------------------------
-- Statusline: lualine + file icons
-- Refs: CodeOSS ui.lua (standalone lualine + SF org/coverage); Craftzdog/LazyVim
--   only tweak LazyVim's. Alternatives to lualine (pick one ecosystem):
--   - echasnovski/mini.statusline  (lighter, mini.nvim family)
--   - rebelot/heirline.nvim        (max control, more code)
--   - built-in 'statusline' string (no plugin; weak icons/git unless you script it)
--------------------------------------------------------------------------------

-- Salesforce org + coverage (CodeOSS ui.lua).
-- package.loaded avoids requiring sf.nvim on every statusline refresh — the
-- component stays empty until a Salesforce command/file loads the plugin.
-- Alts: always `require("sf")` (forces load) · hardcode alias · skip entirely.
local function salesforce_status()
  local sf = package.loaded.sf
  if not sf then
    return "" -- plugin not loaded yet → hide component
    -- return "SF:—", -- show a placeholder instead
  end

  local parts = {}

  -- Target org alias (set via <leader>So / SF org fetch).
  local ok_org, org = pcall(sf.get_target_org)
  if ok_org and org and org ~= "" then
    table.insert(parts, (vim.g.have_nerd_font and "󰢎 " or "SF:") .. org)
    -- table.insert(parts, org) -- text only, no prefix
  end
  -- if not ok_org then … end -- ignore errors (org unset is normal)

  -- Apex test coverage % after a coverage run (ST / SA); empty until then.
  local ok_coverage, coverage = pcall(sf.covered_percent)
  if ok_coverage and coverage and tostring(coverage) ~= "" then
    local coverage_text = tostring(coverage)
    if not coverage_text:match("%%$") then
      coverage_text = coverage_text .. "%"
    end
    table.insert(parts, (vim.g.have_nerd_font and "󰄬 " or "Cov:") .. coverage_text)
    -- table.insert(parts, "cov " .. coverage_text) -- ASCII-only label
  end

  return table.concat(parts, " ")
  -- return table.concat(parts, " · ") -- different separator
end

return {
  {
    "nvim-lualine/lualine.nvim",
    -- When to load the statusline plugin.
    event = "VeryLazy", -- after UI start (fast open; bar appears a tick later)
    -- event = "UIEnter", -- as soon as the UI is ready
    -- lazy = false, -- load at startup (bar sooner, slightly slower open)

    dependencies = {
      -- Filetype icons in the statusline / other UI.
      {
        "nvim-tree/nvim-web-devicons", -- classic icon set (CodeOSS / many configs)
        -- "echasnovski/mini.icons", -- what current LazyVim prefers (swap the string)
        enabled = vim.g.have_nerd_font, -- only if the terminal has a Nerd Font
        -- enabled = true, -- always try icons (may show tofu boxes without a Nerd Font)
        -- enabled = false, -- text-only statusline components
      },
      "SmiteshP/nvim-navic", -- breadcrumbs component in lualine_c (see breadcrumbs.lua opts)
    },
    opts = {
      options = {
        -- Color theme for the bar.
        theme = "auto", -- follow the active colorscheme
        -- theme = "codedark", -- built-in named theme (:help lualine-themes)
        -- theme = "nightfly", -- another built-in; or pass a custom table

        -- Separators between components / sections.
        component_separators = { left = "│", right = "│" }, -- thin ASCII-friendly
        section_separators = { left = "", right = "" }, -- flat sections
        -- component_separators = { left = "", right = "" }, -- Powerline (needs Nerd Font)
        -- section_separators = { left = "", right = "" }, -- Powerline wedges

        -- One bar for the whole screen vs one per window.
        globalstatus = true, -- one bar (pair with vim.opt.laststatus = 3)
        -- globalstatus = false, -- one bar per split (pair with laststatus = 2)

        -- disabled_filetypes = { statusline = { "alpha", "dashboard" } }, -- hide on splash screens
        -- ignore_focus = { "NvimTree", "neo-tree" }, -- keep showing "last" file in sidebars
        -- always_divide_middle = true, -- force left/right sections to stay split
        -- icons_enabled = true, -- false = text-only even when an icon plugin is present
        -- icons_enabled = false, -- force text-only components
      },
      sections = {
        -- Layout: lualine_a .. _c (left) | lualine_x .. _z (right)
        -- Inactive windows use `inactive_sections` if you define it.

        -- Mode indicator (NORMAL / INSERT / …).
        lualine_a = { "mode" }, -- full mode name
        -- lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } }, -- first letter only

        lualine_b = {
          "branch", -- git branch; empty outside a repo
          -- { "branch", icon = "" }, -- custom branch icon
          "diff", -- +/-/~ counts; richer when gitsigns is loaded
          -- { "diff", symbols = { added = "+", modified = "~", removed = "-" } }, -- ASCII diff symbols
        },

        lualine_c = {
          {
            "filename",
            -- How much of the path to show.
            path = 1, -- relative to cwd
            -- path = 0, -- filename only
            -- path = 2, -- absolute
            -- path = 3, -- absolute with ~ for home
            -- file_status = true, -- show [+] modified, [-] readonly, etc. (default on)
            -- newfile_status = true, -- flag buffers not yet on disk
            -- shorting_target = 40, -- shorten long paths to keep the bar readable
            -- symbols = { modified = "●", readonly = "", unnamed = "[No Name]" },
          },
          {
            "navic", -- LSP breadcrumbs (nvim-navic); empty until a supporting LSP attaches
            color_correction = "dynamic",
            navic_opts = { highlight = true },
            -- cond = function() return require("nvim-navic").is_available() end, -- hide when empty
          },
          -- "filesize", -- optional mid component
          -- { "searchcount", maxcount = 999 }, -- match count while searching
        },

        lualine_x = {
          {
            salesforce_status,
            -- Only paint when sf.nvim has been required at least once.
            cond = function()
              return package.loaded.sf ~= nil
            end,
            -- cond = function() return true end, -- always reserve space (shows empty string)
            -- icon = "󰢎", -- lualine can prefix an icon separately if you prefer
          },
          -- { salesforce_status }, -- no cond: still returns "" when unloaded
          "diagnostics", -- LSP/Vim diagnostics; empty until an LSP attaches
          -- { "diagnostics", sources = { "nvim_diagnostic" }, sections = { "error", "warn" } },
          "encoding", -- e.g. utf-8; omit this entry if you always use utf-8
          "fileformat", -- unix / dos / mac line endings
          "filetype", -- name + icon when web-devicons / mini.icons is present
          -- "lsp_status", -- Neovim 0.10+ LSP client names (instead of / besides filetype)
        },

        -- Progress through the buffer.
        lualine_y = { "progress" }, -- percent through file
        -- lualine_y = { "selectioncount" }, -- visual-selection size instead

        -- Cursor position.
        lualine_z = { "location" }, -- line:col
        -- lualine_z = { { "location", padding = { left = 0, right = 1 } } }, -- tighter padding
      },

      -- Shown in windows that are not current (only matters if globalstatus = false).
      -- inactive_sections = {
      --   lualine_c = { { "filename", path = 1 } },
      --   lualine_x = { "location" },
      -- },

      -- Extra bars (usually leave empty while learning):
      -- tabline = {},
      -- winbar = {},
      -- inactive_winbar = {},

      -- extensions = { "lazy", "fugitive", "nvim-tree", "trouble" }, -- nicer sections inside those UIs
    },
  },
}
