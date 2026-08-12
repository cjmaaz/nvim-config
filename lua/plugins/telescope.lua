--------------------------------------------------------------------------------
-- Telescope — fuzzy find files, text, buffers, help, …
-- Refs: CodeOSS telescope.lua; Kickstart init.lua; Craftzdog editor.lua (heavier).
-- TJ video (multi-grep + lazy packages): https://www.youtube.com/watch?v=xdXE1tOT-qg
--   → lua/config/telescope/multigrep.lua (`<leader>sm`); packages: `<leader>sp`
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

      -- Keep the framed picker readable without a Nerd Font.
      local picker_icons = vim.g.have_nerd_font and {
        prompt = "  ",
        caret = " ",
        multi = "󰄬",
      } or {
        prompt = "> ",
        caret = "> ",
        multi = "+",
      }

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
          vim.api.nvim_set_hl(0, group, { fg = chrome.divider_fg, bg = bg })
        end
        -- Use `border` instead of `chrome.divider_fg` above for rose borders.
        vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = chrome.title_fg, bg = bg, bold = true })
        vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = chrome.title_fg, bg = bg })
        vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = chrome.title_fg, bg = bg })
        vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = chrome.divider_fg, bg = chrome.active_bg, bold = true })
        vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { fg = border, bg = chrome.active_bg, bold = true })
        vim.api.nvim_set_hl(0, "TelescopeMultiSelection", { fg = chrome.title_fg, bg = chrome.active_bg })
        vim.api.nvim_set_hl(0, "TelescopeMultiIcon", { fg = chrome.title_fg, bg = chrome.active_bg, bold = true })
        vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = chrome.title_fg, bold = true })
        vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = border, bg = bg, bold = true })
        vim.api.nvim_set_hl(0, "TelescopePromptCounter", { fg = chrome.muted_fg, bg = bg })
        vim.api.nvim_set_hl(0, "TelescopePreviewLine", { fg = chrome.divider_fg, bg = chrome.active_bg })
        vim.api.nvim_set_hl(0, "TelescopePreviewMatch", { fg = chrome.title_fg, bg = chrome.active_bg, bold = true })
        -- vim.api.nvim_set_hl(0, "TelescopeNormal", { link = "NormalFloat" }) -- theme default floats
      end

      telescope.setup({
        defaults = {
          -- Framed results + preview grid, matching the video's layout.
          layout_strategy = "horizontal",
          -- layout_strategy = "vertical", -- stack preview above results on narrow screens
          layout_config = {
            width = 0.90, -- roomy without touching the screen edges
            -- width = 0.80, -- Telescope default; more surrounding editor remains visible
            height = 0.85, -- enough rows for results and code preview
            -- height = 0.70, -- more compact framed picker
            prompt_position = "bottom", -- match the reference's input box below results
            -- prompt_position = "top", -- conventional search-first reading order
            horizontal = {
              preview_width = 0.55, -- give code a little more room than the result list
              -- preview_width = 0.50, -- equal-width results and preview panes
              preview_cutoff = 90, -- hide preview before the two-pane grid becomes cramped
              -- preview_cutoff = 120, -- Telescope default; hide preview sooner
            },
          },

          -- Keep all three picker panes visibly boxed.
          border = true,
          -- border = false, -- flatter picker with no pane outlines
          borderchars = {
            prompt = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
            results = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
            preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          },

          -- Icon-rich prompt, selected row, and multi-selection marker.
          prompt_prefix = picker_icons.prompt,
          selection_caret = picker_icons.caret,
          multi_icon = picker_icons.multi,
          entry_prefix = "  ",

          -- Show the selected file/symbol in the preview pane's border.
          dynamic_preview_title = true,
          -- dynamic_preview_title = false, -- keep a static generic preview title
          results_title = " Results ",
          -- results_title = false, -- hide the results label for cleaner borders

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

      -- fzf-native: load after setup so the sorter is wired (TJ video prerequisite).
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")

      local builtin = require("telescope.builtin")
      local live_multigrep = require("config.telescope.multigrep").open

      -- Search family (<leader>s…)
      vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
      vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Search files" })
      vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "Search select Telescope" })
      vim.keymap.set({ "n", "x" }, "<leader>sw", builtin.grep_string, { desc = "Search current word" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search by grep" })
      -- `pattern  glob` searches content; leading `  glob` lists matching files.
      vim.keymap.set("n", "<leader>sm", live_multigrep, { desc = "Search multi-grep" })
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

      -- Video `<leader>ep`: browse installed lazy.nvim plugin sources.
      vim.keymap.set("n", "<leader>sp", function()
        builtin.find_files({
          cwd = vim.fn.stdpath("data") .. "/lazy",
          prompt_title = "Lazy plugin packages",
        })
      end, { desc = "Search plugin packages" })

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
