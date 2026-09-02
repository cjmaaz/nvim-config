--------------------------------------------------------------------------------
-- Statusline: ordered Catppuccin bubbles + centered file/symbol context
-- Refs: CodeOSS ui.lua (standalone lualine + SF org/coverage); Craftzdog/LazyVim
--   only tweak LazyVim's. Alternatives to lualine (pick one ecosystem):
--   - echasnovski/mini.statusline  (lighter, mini.nvim family)
--   - rebelot/heirline.nvim        (max control, more code)
--   - built-in 'statusline' string (no plugin; weak icons/git unless you script it)
--------------------------------------------------------------------------------

local chrome = require("config.ui_chrome")

local function lighten(hex, amount)
  local value = assert(tonumber(hex:sub(2), 16), "invalid hex color: " .. hex)
  local function lift(channel)
    return math.floor(channel + (255 - channel) * amount + 0.5)
  end
  local red = lift(math.floor(value / 0x10000) % 0x100)
  local green = lift(math.floor(value / 0x100) % 0x100)
  local blue = lift(value % 0x100)
  return string.format("#%02X%02X%02X", red, green, blue)
end

-- Lift footer accents 40% toward white while retaining the editor background.
local footer_lighten = 0.40
-- local footer_lighten = 0.20 -- previous brightness
-- local footer_lighten = 0 -- use the original unlightened colors
local visual_lighten = 0.20 -- darker than adjacent Indigo project bubble
-- local visual_lighten = footer_lighten -- match the other footer accents

-- Shared neutral-Mocha accents; individual components own their bubble colors.
local palette = {
  bg = chrome.base,
  -- bg = chrome.panel_bg, -- match which-key / neo-tree / Telescope
  fg = lighten(chrome.panel_fg, footer_lighten),
  muted = lighten(chrome.muted_fg, footer_lighten),
  yellow = lighten(chrome.yellow, footer_lighten),
}

local bubble = vim.g.have_nerd_font and { left = "", right = "" } or { left = "", right = "" }
local bubble_colors = {
  -- Mode colors make each editing state recognizable at a glance.
  normal = lighten("#00638B", footer_lighten), -- Peacock Blue
  insert = lighten("#008E00", footer_lighten), -- Forest Green
  visual = lighten("#7060EB", visual_lighten), -- distinct darker Noctis purple
  replace = lighten("#D17B9A", footer_lighten), -- Bordo rose
  command = lighten("#E75B45", footer_lighten), -- Tigerlily
  terminal = lighten("#A8D866", footer_lighten), -- Pale Olive Green
  -- Project/file and position retain the requested Indigo.
  file = lighten("#5570D2", footer_lighten),
  -- Indigo remains on the line:column + progress bubble.
  position = lighten("#5570D2", footer_lighten),
  -- Git uses the requested Forest Green.
  git = lighten("#008E00", footer_lighten),
  -- Center relative path uses the requested dark Peacock shade.
  path = lighten("#004066", footer_lighten),
  -- Salesforce/language info reuses the Normal-mode Peacock Blue.
  info = lighten("#00638B", footer_lighten),
  -- Active mode and final info bubble text stays solid black.
  text = "#000000",
}

-- Neutral sections let only the requested components render as bubbles.
local catppuccin_theme = {
  normal = {
    a = { fg = bubble_colors.text, bg = bubble_colors.normal, gui = "bold" },
    b = { fg = palette.muted, bg = palette.bg },
    c = { fg = palette.fg, bg = palette.bg },
  },
  insert = { a = { fg = bubble_colors.text, bg = bubble_colors.insert, gui = "bold" } },
  visual = { a = { fg = bubble_colors.text, bg = bubble_colors.visual, gui = "bold" } },
  replace = { a = { fg = bubble_colors.text, bg = bubble_colors.replace, gui = "bold" } },
  command = { a = { fg = bubble_colors.text, bg = bubble_colors.command, gui = "bold" } },
  terminal = { a = { fg = bubble_colors.text, bg = bubble_colors.terminal, gui = "bold" } },
  inactive = {
    a = { fg = palette.muted, bg = palette.bg, gui = "bold" },
    b = { fg = palette.muted, bg = palette.bg },
    c = { fg = palette.muted, bg = palette.bg },
  },
}

local status_icons = vim.g.have_nerd_font
    and {
      mode = "",
      insert = "",
      visual = "",
      replace = "",
      command = "",
      terminal = "",
      folder = "",
      git = "",
      dirty = "●",
      diagnostics = { error = " ", warn = " " },
      salesforce = "󰢎",
    }
  or {
    mode = "",
    insert = "",
    visual = "",
    replace = "",
    command = "",
    terminal = "",
    folder = "",
    git = "git:",
    dirty = "[+]",
    diagnostics = { error = "E:", warn = "W:" },
    salesforce = "SF:",
  }

local function with_icon(icon, text)
  return string.format("%s%s%s", icon, icon ~= "" and " " or "", text)
end

local function statusline_escape(text)
  return text:gsub("%%", "%%%%")
end

local function mode_label()
  local mode = require("lualine.utils.mode").get_mode()
  local mode_code = vim.fn.mode(1):sub(1, 1)
  local icon = ({
    i = status_icons.insert,
    v = status_icons.visual,
    V = status_icons.visual,
    ["\22"] = status_icons.visual,
    s = status_icons.visual,
    S = status_icons.visual,
    ["\19"] = status_icons.visual,
    R = status_icons.replace,
    r = status_icons.replace,
    c = status_icons.command,
    t = status_icons.terminal,
  })[mode_code] or status_icons.mode
  return with_icon(icon, mode)
end

local function workspace_name()
  local name = vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
  return statusline_escape(with_icon(status_icons.folder, name ~= "" and name or "/"))
end

local function dirty_flag()
  return vim.bo.modified and status_icons.dirty or ""
end

local function left_truncate(text, max_width)
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end
  local suffix_width = math.max(1, max_width - 1)
  local chars = vim.fn.strchars(text)
  local start = 0
  while start < chars and vim.fn.strdisplaywidth(vim.fn.strcharpart(text, start)) > suffix_width do
    start = start + 1
  end
  return "…" .. vim.fn.strcharpart(text, start)
end

local function relative_file_context()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return "[No Name]"
  end

  local text = vim.fs.relpath(vim.fn.getcwd(0), path) or vim.fn.fnamemodify(path, ":~")
  local navic = package.loaded["nvim-navic"]
  if navic and navic.is_available(0) then
    local location = navic.get_location({
      highlight = false,
      separator = " > ",
      depth_limit = 3,
      lazy_update_context = true,
    }, 0)
    if location ~= "" then
      text = text .. " > " .. location
    end
  end

  return statusline_escape(left_truncate(text, math.max(24, math.floor(vim.o.columns * 0.36))))
end

local function language_info()
  local filetype = vim.bo.filetype
  if filetype == "" then
    return ""
  end
  local icon = ""
  if vim.g.have_nerd_font then
    -- Same broad icon provider used by Neo-tree and bufferline.
    icon = require("nvim-web-devicons").get_icon_by_filetype(filetype, { default = true }) or ""
  end
  return icon ~= "" and icon or filetype
end

local function encoding_info()
  local encoding = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
  local normalized = encoding:lower():gsub("_", "-")
  if normalized == "utf-8" or normalized == "utf8" then
    return ""
  end
  return encoding
end

-- Salesforce org + coverage (CodeOSS ui.lua).
-- package.loaded avoids requiring sf.nvim on every statusline refresh — the
-- component stays empty until a Salesforce command/file loads the plugin.
-- Alts: always `require("sf")` (forces load) · hardcode alias · skip entirely.
local function salesforce_status()
  if not require("config.project_context").is_salesforce(0) then
    return ""
  end
  local sf = package.loaded.sf
  if not sf then
    return "" -- plugin not loaded yet → hide component
    -- return "SF:—", -- show a placeholder instead
  end

  local parts = {}

  -- Target org alias (set via <leader>So / SF org fetch).
  local ok_org, org = pcall(sf.get_target_org)
  if ok_org and org and org ~= "" then
    table.insert(parts, with_icon(status_icons.salesforce, org))
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

local function final_context()
  local parts = {}
  if package.loaded.sf then
    local sf = salesforce_status()
    if sf ~= "" then
      parts[#parts + 1] = sf
    end
  end

  local language = language_info()
  if language ~= "" then
    parts[#parts + 1] = language
  end
  local encoding = encoding_info()
  if encoding ~= "" then
    parts[#parts + 1] = encoding
  end
  return statusline_escape(table.concat(parts, "  "))
end

local function setup_navic()
  local navic = require("nvim-navic")
  navic.setup({
    -- Keep context inline with the unstyled center path.
    highlight = false,
    -- highlight = true, -- use per-symbol highlight groups
    -- Match the path/context separator used by the footer.
    separator = " > ",
    -- separator = " › ", -- softer single-glyph alternate
    -- Keep only the nearest method/property chain.
    depth_limit = 3,
    -- depth_limit = 0, -- show every parent symbol
    lazy_update_context = true,
    -- lazy_update_context = false, -- recompute on every statusline evaluation
  })

  local function attach(client, bufnr)
    if client.server_capabilities.documentSymbolProvider and not navic.is_available(bufnr) then
      pcall(navic.attach, client, bufnr)
    end
  end

  local group = vim.api.nvim_create_augroup("statusline_navic_attach", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client then
        attach(client, event.buf)
      end
    end,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        attach(client, bufnr)
      end
    end
  end
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
      "SmiteshP/nvim-navic", -- method/property context in the center section
    },
    opts = {
      options = {
        -- Neutral Catppuccin palette; each bubble supplies its own background.
        theme = catppuccin_theme,
        -- theme = "auto", -- follow the active colorscheme instead

        -- Components opt into one-sided curves instead of reordering whole sections.
        component_separators = { left = "", right = "" },
        -- component_separators = { left = "│", right = "│" }, -- vertical dividers (visually busy)
        section_separators = { left = "", right = "" },
        -- section_separators = { left = "", right = "" }, -- curve every section boundary
        -- component_separators = { left = "", right = "" }, -- Powerline (needs Nerd Font)
        -- section_separators = { left = "", right = "" }, -- Powerline wedges

        -- One bar for the whole screen vs one per window.
        globalstatus = true, -- one bar (pair with vim.opt.laststatus = 3)
        -- globalstatus = false, -- one bar per split (pair with laststatus = 2)

        -- disabled_filetypes = { statusline = { "alpha", "dashboard" } }, -- hide on splash screens
        -- ignore_focus = { "NvimTree", "neo-tree" }, -- keep showing "last" file in sidebars
        always_divide_middle = true, -- hold the right-side icon chips at the edge
        -- always_divide_middle = false, -- let sections consume all available width
        icons_enabled = vim.g.have_nerd_font, -- avoid tofu when the host font lacks icons
        -- icons_enabled = false, -- force text-only components
      },
      sections = {
        -- Layout: lualine_a .. _c (left) | lualine_x .. _z (right)
        -- Inactive windows use `inactive_sections` if you define it.

        -- 1. Vim/terminal mode bubble.
        lualine_a = {
          {
            mode_label,
            separator = { right = bubble.right },
            padding = { left = 1, right = 1 },
          },
        },
        -- lualine_a = { "mode" }, -- text-only mode without a Vim/terminal icon

        -- 2–4. Workspace bubble, Git branch bubble, then standalone dirty flag.
        lualine_b = {
          {
            workspace_name,
            color = { fg = palette.bg, bg = bubble_colors.file, gui = "bold" },
            separator = { right = bubble.right },
            padding = { left = 1, right = 1 },
          },
          {
            "branch",
            icon = status_icons.git,
            color = { fg = palette.bg, bg = bubble_colors.git, gui = "bold" },
            separator = { right = bubble.right },
            padding = { left = 1, right = 1 },
          },
          {
            dirty_flag,
            color = { fg = palette.yellow, bg = palette.bg },
            padding = { left = 1, right = 1 },
          },
        },

        -- 5. Relative path > method/property; no bubble, left-truncated.
        lualine_c = {
          {
            relative_file_context,
            color = { fg = bubble_colors.path, bg = palette.bg, gui = "bold" },
            padding = { left = 1, right = 1 },
          },
        },
        -- lualine_c = { { "filename", path = 1 } }, -- relative file without symbol context

        -- 6. Plain diagnostics without a bubble.
        lualine_x = {
          {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            sections = { "error", "warn" },
            symbols = status_icons.diagnostics,
            colored = false,
            color = { fg = palette.muted, bg = palette.bg },
            padding = { left = 1, right = 1 },
          },
        },

        -- 7. Line:column and progress share one darkened workspace-color bubble.
        lualine_y = {
          {
            "location",
            color = { fg = palette.bg, bg = bubble_colors.position, gui = "bold" },
            separator = { left = bubble.left },
            padding = { left = 1, right = 0 },
          },
          {
            "progress",
            color = { fg = palette.bg, bg = bubble_colors.position, gui = "bold" },
            padding = { left = 1, right = 1 },
          },
        },

        -- 8. Salesforce, language icon, and non-UTF-8 encoding share the final bubble.
        lualine_z = {
          {
            final_context,
            color = { fg = bubble_colors.text, bg = bubble_colors.info, gui = "bold" },
            separator = { left = bubble.left },
            cond = function()
              return vim.bo.filetype ~= ""
                or package.loaded.sf ~= nil
                or encoding_info() ~= ""
            end,
            padding = { left = 1, right = 1 },
          },
        },
        -- lualine_z = { "filetype" }, -- language text only, without SF/encoding data
      },

      -- Shown in windows that are not current (only matters if globalstatus = false).
      -- inactive_sections = {
      --   lualine_c = { { "filename", path = 1 } },
      --   lualine_x = { "location" },
      -- },

      -- Extra bars are kept separate; config.winbar owns the native winbar.
      -- tabline = {},
      -- winbar = {}, -- use Lualine sections instead of the plain native context row
      -- inactive_winbar = {},

      -- extensions = { "lazy", "fugitive", "nvim-tree", "trouble" }, -- nicer sections inside those UIs
    },
    config = function(_, opts)
      setup_navic()
      require("lualine").setup(opts)
      -- Keep the top file/LSP context row hidden for now.
      -- require("config.winbar").setup() -- restore the non-overlapping native winbar
    end,
  },
}
