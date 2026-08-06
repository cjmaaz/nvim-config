--------------------------------------------------------------------------------
-- Explorer: neo-tree (sidebar file tree)
-- Refs: Kickstart optional neo-tree.lua; CodeOSS parked editor.lua (defaults we keep).
-- Alts considered: oil.nvim · mini.files · netrw · snacks.explorer — user picked neo-tree.
-- Cheatsheet: docs/keymaps/explorer.md
--------------------------------------------------------------------------------

--- Sidebar panel bg (shared with which-key / Telescope via config.ui_chrome).
local function apply_neo_tree_hl()
  local chrome = require("config.ui_chrome")
  local bg, fg = chrome.panel_bg, chrome.panel_fg
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { fg = chrome.muted_fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { fg = bg, bg = bg }) -- hide ~ filler
  vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = chrome.divider_fg, bg = bg })
  -- vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = chrome.separator_fg, bg = bg }) -- softer edge
  vim.api.nvim_set_hl(0, "NeoTreeFloatNormal", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { fg = chrome.divider_fg, bg = bg })
  -- vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { fg = chrome.border_fg, bg = bg }) -- rose border
  vim.api.nvim_set_hl(0, "NeoTreeTitleBar", { fg = chrome.title_fg, bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { fg = chrome.divider_fg, bg = chrome.active_bg })
  vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { fg = chrome.border_fg, bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = chrome.panel_fg, bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = chrome.title_fg, bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeModified", { fg = chrome.title_fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeDimText", { fg = chrome.muted_fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeIndentMarker", { fg = chrome.muted_fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeExpander", { fg = chrome.divider_fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeTabActive", { fg = chrome.divider_fg, bg = chrome.active_bg, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeTabInactive", { fg = chrome.muted_fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeTabSeparatorActive", { fg = chrome.divider_fg, bg = chrome.active_bg })
  vim.api.nvim_set_hl(0, "NeoTreeTabSeparatorInactive", { fg = chrome.active_bg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeStatusLine", { fg = fg, bg = chrome.active_bg })
  vim.api.nvim_set_hl(0, "NeoTreeStatusLineNC", { fg = chrome.muted_fg, bg = bg })
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x", -- stable v3 API
    -- branch = "main", -- bleeding edge
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    keys = {
      -- Outside the tree (normal buffers):
      {
        "<leader>fe",
        "<cmd>Neotree filesystem toggle left<CR>",
        desc = "Toggle file explorer",
      },
      {
        "<leader>fE",
        "<cmd>Neotree filesystem reveal left<CR>",
        desc = "Reveal current file in explorer",
      },
      {
        "<leader>ge",
        "<cmd>Neotree git_status toggle<CR>",
        desc = "Toggle git status explorer",
      },
      -- { "\\", "<cmd>Neotree reveal<CR>", desc = "Neo-tree reveal (Kickstart)" }, -- conflicts with maplocalleader
    },
    opts = {
      -- Close neo-tree if it would be the last window (avoids empty layout).
      close_if_last_window = true,
      -- close_if_last_window = false,

      -- Clickable Files / Buffers / Git tabs inside Neo-tree's own winbar.
      source_selector = {
        winbar = true,
        -- winbar = false, -- hide tabs; switch sources only with < / >
        statusline = false, -- lualine owns the global statusline
        sources = {
          { source = "filesystem", display_name = "Files" },
          { source = "buffers", display_name = "Buffers" },
          { source = "git_status", display_name = "Git" },
        },
        content_layout = "center",
        tabs_layout = "equal",
        padding = 1,
      },

      -- Popup border for confirms / prompts inside neo-tree.
      popup_border_style = "rounded",
      -- popup_border_style = "single",
      -- popup_border_style = "NC", -- no border

      enable_git_status = true, -- git marks next to files
      -- enable_git_status = false,
      enable_diagnostics = true, -- LSP diagnostics when an LSP is attached later
      -- enable_diagnostics = false,
      enable_opened_markers = true, -- track files represented by open buffers
      -- enable_opened_markers = false,

      -- Limit `git status` to the displayed subtree (faster in monorepos).
      git_status_scope_to_path = true,
      -- git_status_scope_to_path = false, -- full worktree status if scoped results feel incomplete

      default_component_configs = {
        indent = {
          with_expanders = true, -- nicer folder expand/collapse glyphs
          -- with_expanders = false,
        },
        name = {
          highlight_opened_files = "all", -- rose/bold NeoTreeFileNameOpened for open files
          -- highlight_opened_files = false, -- do not distinguish open files
        },
      },

      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            local manager = require("neo-tree.sources.manager")
            local state = manager.get_state("filesystem")
            if state and state.search_pattern then
              require("neo-tree.sources.filesystem").reset_search(state, true)
            end
          end,
        },
      },

      window = {
        position = "left", -- sidebar
        -- position = "right",
        -- position = "float",
        width = 34, -- base width; restored when auto-expand is toggled off
        -- width = 40,
        auto_expand_width = true, -- grow to the longest visible node instead of truncating
        -- auto_expand_width = false, -- fixed width; long names fade/truncate (press e to toggle)
        mappings = {
          -- Space is our global leader — don't let neo-tree steal it for toggle_node.
          ["<space>"] = "none",
          -- ["<space>"] = { "toggle_node", nowait = false }, -- neo-tree default
        },
      },

      filesystem = {
        -- Take over :Explore / directory buffers (we are not using netrw as primary).
        hijack_netrw_behavior = "open_default",
        -- hijack_netrw_behavior = "disabled", -- CodeOSS parked: keep netrw for :Explore
        -- hijack_netrw_behavior = "open_current",

        follow_current_file = {
          enabled = true, -- sync tree cursor with the buffer you edit
          -- enabled = false,
          leave_dirs_open = false,
          -- leave_dirs_open = true,
        },

        use_libuv_file_watcher = true, -- auto-refresh when files change on disk
        -- use_libuv_file_watcher = false,

        filtered_items = {
          -- `H` toggles `visible` only — it does **not** flip hide_dotfiles.
          -- If hide_dotfiles/hide_gitignored are already false, almost nothing is
          -- filtered, so H logs “Toggling hidden…” but the tree looks unchanged.
          visible = false, -- filtered items hidden until you press H (then shown dimmed)
          -- visible = true, -- always show filtered items (dimmed) without pressing H
          hide_dotfiles = true, -- filter `.env`, `.git`, … so H has something to toggle
          -- hide_dotfiles = false, -- always show dotfiles as normal (H becomes a no-op for them)
          hide_gitignored = true, -- filter gitignored paths; H shows them when visible
          -- hide_gitignored = false, -- always list ignored files
          hide_by_name = {
            -- "node_modules",
          },
          always_show = { -- stay visible even when hide_dotfiles is on
            ".gitignore",
            ".forceignore",
            ".sfdx", -- Salesforce DX / SObject stubs
            ".sf",
          },
          -- always_show_by_pattern = { ".env*" }, -- keep local env files visible
          never_show = { -- never listed, even after H
            ".DS_Store",
            "thumbs.db",
          },
          -- never_show_by_pattern = { "*.o", "*.pyc" },
          show_hidden_count = true, -- “x hidden” footer in folders
          -- show_hidden_count = false,
        },

        window = {
          mappings = {
            ["<space>"] = "none", -- same as global window.mappings
            -- ["\\"] = "close_window", -- Kickstart pairs with \\ open
          },
        },
      },

      git_status = {
        window = {
          position = "float", -- git_status as float is less disruptive
          -- position = "left",
        },
      },
    },

    config = function(_, opts)
      require("neo-tree").setup(opts)
      apply_neo_tree_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("neo_tree_hl", { clear = true }),
        callback = apply_neo_tree_hl,
      })
    end,
  },
}
