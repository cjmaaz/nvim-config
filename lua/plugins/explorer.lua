--------------------------------------------------------------------------------
-- Explorer: neo-tree (sidebar file tree)
-- Refs: Kickstart optional neo-tree.lua; CodeOSS parked editor.lua (defaults we keep).
-- Alts considered: oil.nvim · mini.files · netrw · snacks.explorer — user picked neo-tree.
-- Cheatsheet: docs/keymaps/explorer.md
--------------------------------------------------------------------------------

--- Sidebar panel bg (keep in sync with which-key panel if you want matching chrome).
local function apply_neo_tree_hl()
  local bg = "#000000" -- solid black sidebar
  -- local bg = "#0a0a0a" -- near-black
  -- local bg = "#2B2528" -- Bordo bg2 (dimmer than editor)
  -- local bg = nil -- leave theme defaults (comment out the set_hl calls below)
  local fg = "#C9BEC2"
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { fg = bg, bg = bg }) -- hide ~ filler
  vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = "#3C2F34", bg = bg })
  -- vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { link = "WinSeparator" })
  vim.api.nvim_set_hl(0, "NeoTreeFloatNormal", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { fg = "#D17B9A", bg = bg })
  -- vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { link = "FloatBorder" })
  vim.api.nvim_set_hl(0, "NeoTreeTitleBar", { fg = "#F6C38A", bg = bg, bold = true })
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

      -- Popup border for confirms / prompts inside neo-tree.
      popup_border_style = "rounded",
      -- popup_border_style = "single",
      -- popup_border_style = "NC", -- no border

      enable_git_status = true, -- git marks next to files
      -- enable_git_status = false,
      enable_diagnostics = true, -- LSP diagnostics when an LSP is attached later
      -- enable_diagnostics = false,

      default_component_configs = {
        indent = {
          with_expanders = true, -- nicer folder expand/collapse glyphs
          -- with_expanders = false,
        },
      },

      window = {
        position = "left", -- sidebar
        -- position = "right",
        -- position = "float",
        width = 34, -- CodeOSS-ish
        -- width = 40,
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
