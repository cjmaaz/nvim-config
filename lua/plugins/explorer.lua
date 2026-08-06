--------------------------------------------------------------------------------
-- Explorer: neo-tree (sidebar file tree)
-- Refs: Kickstart optional neo-tree.lua; CodeOSS parked editor.lua (defaults we keep).
-- Alts considered: oil.nvim · mini.files · netrw · snacks.explorer — user picked neo-tree.
-- Cheatsheet: docs/keymaps/explorer.md
--------------------------------------------------------------------------------

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
          visible = false, -- hide filtered items unless you toggle them (H)
          -- visible = true, -- show greyed-out filtered items
          hide_dotfiles = false, -- show .env / .gitignored-looking dots (SF / tooling)
          -- hide_dotfiles = true,
          hide_gitignored = false, -- still list ignored files (toggle with I / filtered UI)
          -- hide_gitignored = true,
          hide_by_name = {
            -- ".git",
            -- "node_modules",
          },
          never_show = {
            ".DS_Store",
            "thumbs.db",
          },
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
  },
}
