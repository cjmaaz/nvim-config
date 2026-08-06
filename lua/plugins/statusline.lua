--------------------------------------------------------------------------------
-- Statusline: clean Bordo lualine + file icons
-- Refs: CodeOSS ui.lua (standalone lualine + SF org/coverage); Craftzdog/LazyVim
--   only tweak LazyVim's. Alternatives to lualine (pick one ecosystem):
--   - echasnovski/mini.statusline  (lighter, mini.nvim family)
--   - rebelot/heirline.nvim        (max control, more code)
--   - built-in 'statusline' string (no plugin; weak icons/git unless you script it)
--------------------------------------------------------------------------------

local chrome = require("config.ui_chrome")

-- Noctis Bordo accents; statusline layers sit slightly darker than other panels.
local bordo = {
  bg = "#1F1B1D", -- modest step darker than shared panel_bg (#241F22)
  -- bg = chrome.panel_bg, -- match which-key / neo-tree / Telescope
  bg_alt = "#2B2528", -- raised section, still darker than the old Bordo bg1
  -- bg_alt = chrome.active_bg, -- brighter section contrast
  fg = chrome.panel_fg,
  muted = chrome.muted_fg,
  rose = chrome.border_fg,
  orange = "#C5663F",
  yellow = chrome.title_fg,
  green = "#7BE6AB",
  cyan = "#4CA1B3",
  blue = "#64AAE4",
  purple = "#7060EB",
}

-- Flat sections with a mode-colored cap on both ends.
local bordo_theme = {
  normal = {
    a = { fg = bordo.bg, bg = bordo.blue, gui = "bold" },
    b = { fg = bordo.fg, bg = bordo.bg_alt },
    c = { fg = bordo.fg, bg = bordo.bg },
  },
  insert = { a = { fg = bordo.bg, bg = bordo.green, gui = "bold" } },
  visual = { a = { fg = bordo.bg, bg = bordo.purple, gui = "bold" } },
  replace = { a = { fg = bordo.bg, bg = bordo.rose, gui = "bold" } },
  command = { a = { fg = bordo.bg, bg = bordo.yellow, gui = "bold" } },
  terminal = { a = { fg = bordo.bg, bg = bordo.orange, gui = "bold" } },
  inactive = {
    a = { fg = bordo.muted, bg = bordo.bg, gui = "bold" },
    b = { fg = bordo.muted, bg = bordo.bg },
    c = { fg = bordo.muted, bg = bordo.bg },
  },
}

local status_icons = vim.g.have_nerd_font
    and {
      branch = "",
      diff = { added = " ", modified = " ", removed = " " },
      diagnostics = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
      lsp = "",
      readonly = "",
    }
  or {
    branch = "git:",
    diff = { added = "+", modified = "~", removed = "-" },
    diagnostics = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
    lsp = "LSP:",
    readonly = "RO",
  }

--- Hide secondary components before they crowd the filename.
local function min_columns(width)
  return function()
    return vim.o.columns >= width
  end
end

--- Keep unusually long branch names from taking over the left side.
local function compact_branch(branch)
  return #branch > 24 and branch:sub(1, 21) .. "…" or branch
end

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
      -- Previous breadcrumbs (navic); uncomment after restoring breadcrumbs.lua:
      -- "SmiteshP/nvim-navic",
    },
    opts = {
      options = {
        -- Bordo palette with a mode-colored cap.
        theme = bordo_theme,
        -- theme = "auto", -- follow the active colorscheme instead

        -- Keep component boundaries clean; the horizontal edge separates the bar.
        component_separators = { left = "", right = "" },
        -- component_separators = { left = "│", right = "│" }, -- vertical dividers (visually busy)
        section_separators = { left = "", right = "" }, -- clean, no Powerline wedges
        -- component_separators = { left = "", right = "" }, -- Powerline (needs Nerd Font)
        -- section_separators = { left = "", right = "" }, -- Powerline wedges

        -- One bar for the whole screen vs one per window.
        globalstatus = true, -- one bar (pair with vim.opt.laststatus = 3)
        -- globalstatus = false, -- one bar per split (pair with laststatus = 2)

        -- disabled_filetypes = { statusline = { "alpha", "dashboard" } }, -- hide on splash screens
        -- ignore_focus = { "NvimTree", "neo-tree" }, -- keep showing "last" file in sidebars
        always_divide_middle = true, -- protect the filename from right-side growth
        -- always_divide_middle = false, -- let sections consume all available width
        icons_enabled = vim.g.have_nerd_font, -- avoid tofu when the host font lacks icons
        -- icons_enabled = false, -- force text-only components
      },
      sections = {
        -- Layout: lualine_a .. _c (left) | lualine_x .. _z (right)
        -- Inactive windows use `inactive_sections` if you define it.

        -- Mode indicator (NORMAL / INSERT / …).
        lualine_a = {
          { "mode", padding = { left = 1, right = 1 } }, -- full mode name in colored cap
        },
        -- lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } }, -- first letter only

        lualine_b = {
          {
            "branch", -- git branch; empty outside a repo
            icon = status_icons.branch,
            fmt = compact_branch,
          },
          {
            "diff", -- +/-/~ counts; richer when gitsigns is loaded
            symbols = status_icons.diff,
            diff_color = {
              added = { fg = bordo.green },
              modified = { fg = bordo.yellow },
              removed = { fg = bordo.rose },
            },
          },
          -- { "diff", symbols = { added = "+", modified = "~", removed = "-" } }, -- ASCII-only
        },

        lualine_c = {
          {
            "filename",
            -- How much of the path to show.
            path = 1, -- relative to cwd, as before dropbar
            -- path = 0, -- filename only (dropbar already carries the path above)
            -- path = 2, -- absolute
            -- path = 3, -- absolute with ~ for home
            -- file_status = true, -- show [+] modified, [-] readonly, etc. (default on)
            newfile_status = true, -- flag buffers not yet written
            -- newfile_status = false, -- show no distinct new-file marker
            -- Reserve room for the other sections; shorten parent directories first.
            shorting_target = 40, -- e.g. very/long/path/file.lua → v/l/p/file.lua
            -- shorting_target = 0, -- never shorten the displayed path
            symbols = {
              modified = "●",
              readonly = status_icons.readonly,
              unnamed = "[No Name]",
              newfile = "[New]",
            },
          },
          -- Previous breadcrumbs (navic); uncomment after restoring breadcrumbs.lua:
          -- { "navic", color_correction = "dynamic", navic_opts = { highlight = true } },
          -- "filesize", -- optional mid component
          -- { "searchcount", maxcount = 999 }, -- match count while searching
        },

        lualine_x = {
          {
            salesforce_status,
            color = { fg = bordo.blue, gui = "bold" },
            -- Only paint when sf.nvim is loaded and the screen has room.
            cond = function()
              return package.loaded.sf ~= nil and vim.o.columns >= 100
            end,
            -- cond = function() return package.loaded.sf ~= nil end, -- show at every width
            -- icon = "󰢎", -- lualine can prefix an icon separately if you prefer
          },
          -- { salesforce_status }, -- no cond: still returns "" when unloaded
          {
            "diagnostics", -- counts by severity
            sources = { "nvim_diagnostic" },
            symbols = status_icons.diagnostics,
            diagnostics_color = {
              error = { fg = bordo.rose },
              warn = { fg = bordo.yellow },
              info = { fg = bordo.blue },
              hint = { fg = bordo.cyan },
            },
          },
          {
            "lsp_status", -- active client names + progress
            icon = status_icons.lsp,
            color = { fg = bordo.cyan },
            cond = min_columns(120),
          },
          {
            "filetype", -- name + devicon
            color = { fg = bordo.yellow },
            cond = min_columns(90),
          },
          -- { "encoding", cond = min_columns(140) }, -- show utf-8 on very wide screens
          -- { "fileformat", cond = min_columns(130) }, -- show unix/dos/mac
        },

        -- Progress through the buffer.
        lualine_y = {
          { "progress", cond = min_columns(80) }, -- percent through file
        },
        -- lualine_y = { "selectioncount" }, -- visual-selection size instead

        -- Cursor position.
        lualine_z = {
          { "location", padding = { left = 1, right = 1 } }, -- line:col in mode cap
        },
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
