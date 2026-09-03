--------------------------------------------------------------------------------
-- todo-comments — highlight + jump TODO / FIXME / …
-- Refs: CodeOSS ui.lua; Kickstart (signs = false).
-- Needs: plenary (pulled in). Telescope optional for <leader>st.
-- Alts: signs = false (Kickstart quieter gutter) · skip Telescope map.
--------------------------------------------------------------------------------

return {
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function()
      local chrome = require("config.ui_chrome")
      local icons = vim.g.have_nerd_font
          and {
            todo = "󰄬 ",
            note = "󰋽 ",
            warn = "󰀪 ",
            important = " ",
            question = " ",
          }
        or {
          todo = "T ",
          note = "N ",
          warn = "W ",
          important = "! ",
          question = "? ",
        }

      return {
        signs = true, -- keep colored annotation icons in the gutter and TODO tree
        -- signs = false, -- text highlight only; quieter sign column
        keywords = {
          TODO = { icon = icons.todo, color = "todo" },
          NOTE = { icon = icons.note, color = "note", alt = { "INFO" } },
          WARN = { icon = icons.warn, color = "warning", alt = { "WARNING", "XXX" } },
          IMPORTANT = { icon = icons.important, color = "important", alt = { "ALERT" } },
          QUESTION = { icon = icons.question, color = "question", alt = { "ASK" } },
        },
        merge_keywords = true, -- retain FIX/HACK/PERF/TEST defaults
        -- merge_keywords = false, -- use only the five annotation families above
        gui_style = {
          fg = "BOLD", -- make keyword badges easy to scan
          bg = "BOLD",
        },
        highlight = {
          multiline = true,
          before = "", -- leave the language's comment delimiter muted
          keyword = "wide_fg", -- color keyword plus trailing colon
          -- keyword = "wide_bg", -- stronger filled badge alternate
          after = "fg", -- color the annotation message like Better Comments
          comments_only = true, -- require a Treesitter comment capture
          max_line_len = 400, -- skip pathological generated/minified lines
        },
        colors = {
          todo = { chrome.cyan },
          note = { chrome.teal },
          warning = { chrome.yellow },
          important = { chrome.red },
          question = { chrome.lavender },
        },
      }
    end,
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next TODO comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous TODO comment",
      },
      { "<leader>st", "<cmd>TodoTelescope<CR>", desc = "Search TODO comments" },
      { "<leader>xt", "<cmd>Trouble todo toggle focus=true<CR>", desc = "TODO tree (Trouble)" },
      -- { "<leader>st", "<cmd>TodoQuickFix<CR>", desc = "TODO quickfix" }, -- no Telescope
    },
  },
}
