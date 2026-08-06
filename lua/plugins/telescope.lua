--------------------------------------------------------------------------------
-- Telescope — fuzzy find files, text, buffers, help, …
-- Refs: CodeOSS telescope.lua; Kickstart init.lua; Craftzdog editor.lua (heavier).
-- Alts: fzf-lua (faster, needs fzf binary) · snacks.picker (LazyVim-modern).
-- Needs: ripgrep (rg), fd — see docs/TOOLS.md. Optional: make (fzf-native).
--------------------------------------------------------------------------------

return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter", -- Kickstart/CodeOSS: available soon after UI
    -- event = "VeryLazy",
    -- branch = "0.1.x", -- frozen; breaks preview highlight with treesitter `main` (ft_to_lang nil)
    branch = "master", -- works with nvim-treesitter main + Nvim 0.12
    -- version = "*", -- alternate: release tags when they catch up
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim", -- native sorter (faster)
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      "nvim-telescope/telescope-ui-select.nvim", -- vim.ui.select → Telescope
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope master uses `utils.if_nil = vim.nonnil or vim.F.if_nil`.
      -- On Nvim 0.12 that can be nil → layout_strategies / ui-select crash
      -- (e.g. <leader>So org picker). Always install a tiny compatible shim.
      local t_utils = require("telescope.utils")
      t_utils.if_nil = function(x, default)
        if x == nil then
          return default
        end
        return x
      end

      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          path_display = { "smart" }, -- shorten long paths
          -- path_display = { "truncate" },
          -- If preview still errors on an old Telescope pin, disable TS highlight there:
          -- preview = { treesitter = false },
          mappings = {
            i = { -- insert mode inside the picker
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              -- ["<C-n>"] = actions.move_selection_next, -- stock-ish
              -- ["<C-p>"] = actions.move_selection_previous,
            },
          },
        },
        extensions = {
          -- Table form avoids odd merge issues with get_dropdown() as a bare table.
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")

      local builtin = require("telescope.builtin")

      -- Search family (<leader>s…)
      vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
      vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Search files" })
      vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "Search select Telescope" })
      vim.keymap.set({ "n", "x" }, "<leader>sw", builtin.grep_string, { desc = "Search current word" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search by grep" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
      vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Search resume" })
      vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "Search commands" })
      vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = "Search recent files" })

      vim.keymap.set("n", "<leader>s/", function()
        builtin.live_grep({
          grep_open_files = true,
          prompt_title = "Live grep in open files",
        })
      end, { desc = "Search in open files" })

      vim.keymap.set("n", "<leader>sn", function()
        builtin.find_files({ cwd = vim.fn.stdpath("config"), follow = true })
      end, { desc = "Search Neovim config" })

      vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Find buffers" })

      vim.keymap.set("n", "<leader>/", function()
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = "Fuzzy search current buffer" })
    end,
  },
}
