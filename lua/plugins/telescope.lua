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

      --- Soft Bordo-dark panel (shared with which-key / neo-tree).
      local function apply_telescope_hl()
        local chrome = require("config.ui_chrome")
        local bg, fg = chrome.panel_bg, chrome.panel_fg
        local border = chrome.border_fg
        for _, group in ipairs({
          "TelescopeNormal",
          "TelescopePromptNormal",
          "TelescopeResultsNormal",
          "TelescopePreviewNormal",
        }) do
          vim.api.nvim_set_hl(0, group, { fg = fg, bg = bg })
        end
        for _, group in ipairs({
          "TelescopeBorder",
          "TelescopePromptBorder",
          "TelescopeResultsBorder",
          "TelescopePreviewBorder",
        }) do
          vim.api.nvim_set_hl(0, group, { fg = border, bg = bg })
        end
        vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = chrome.title_fg, bg = bg, bold = true })
        vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = chrome.title_fg, bg = bg })
        vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = chrome.title_fg, bg = bg })
        vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = fg, bg = chrome.separator_fg, bold = true })
        -- vim.api.nvim_set_hl(0, "TelescopeNormal", { link = "NormalFloat" }) -- theme default floats
      end

      telescope.setup({
        defaults = {
          path_display = { "smart" }, -- shorten long paths intelligently
          -- path_display = { "truncate" }, -- cut the middle of long paths
          -- path_display = { "absolute" }, -- full paths (noisy in big monorepos)
          -- path_display = { "hidden" }, -- hide path column (filename focus)

          -- If preview still errors on an old Telescope pin, disable TS highlight there:
          -- preview = { treesitter = false },
          -- preview = { hide_on_startup = true }, -- open pickers without preview until toggled

          -- Extra ignore globs on top of `.gitignore` (Lua patterns; `%` escapes magic chars).
          -- rg/fd already skip gitignored files — these catch lockfiles, build dirs, SF metadata, …
          -- To search inside an ignored path once: Telescope find_files no_ignore=true (or clear a line).
          file_ignore_patterns = {
            "node_modules/", -- JS/TS deps
            -- "node_modules", -- without trailing slash also matches files named node_modules
            "%.git/", -- git objects / metadata (Telescope sometimes still walks them)
            "%.sfdx/", -- Salesforce DX cache / tools (SObject stubs, …)
            "%.sf/", -- modern SF CLI state under the project
            "target/", -- Maven / Rust-ish build output
            "dist/", -- frontend build
            "build/", -- generic build dir
            -- "coverage/", -- test coverage reports (uncomment if noisy)
            -- "%.next/", -- Next.js build
            "%.class", -- Java bytecode
            "%.jar", -- Java archives
            "package%-lock%.json", -- npm lock (huge / low signal in pickers)
            "yarn%.lock",
            "pnpm%-lock%.yaml",
            -- "Cargo%.lock", -- Rust lockfile
            "%.min%.js", -- minified bundles
            "%.min%.css",
            -- "%.map", -- source maps
          },
          -- file_ignore_patterns = {}, -- honor only .gitignore / fd defaults

          mappings = {
            i = { -- insert mode inside the picker
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              -- ["<C-n>"] = actions.move_selection_next, -- stock-ish
              -- ["<C-p>"] = actions.move_selection_previous,
              -- ["<C-q>"] = actions.send_to_qflist + actions.open_qflist, -- classic Telescope → qflist
            },
            -- n = { -- normal mode inside the picker
            --   ["q"] = actions.close,
            -- },
          },
        },
        extensions = {
          -- Table form avoids odd merge issues with get_dropdown() as a bare table.
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      apply_telescope_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("telescope_panel_hl", { clear = true }),
        callback = apply_telescope_hl,
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
