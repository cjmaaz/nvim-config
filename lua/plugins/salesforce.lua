--------------------------------------------------------------------------------
-- Salesforce — sf.nvim (CLI workflows: org, retrieve, deploy, tests, metadata)
-- Refs: CodeOSS salesforce.lua; upstream xixiaofinland/sf.nvim.
-- Needs: `sf` CLI on PATH · SF project root (sfdx-project.json / .forceignore).
-- apex_ls stays in lsp.lua; this plugin is org/test/deploy/metadata UI.
-- Alts: raw `:!sf …` in terminal · skip fzf-lua (lose md list pickers).
--------------------------------------------------------------------------------

local function sf_action(method, ...)
  local args = { ... }
  return function()
    local sf = require("sf")
    sf[method](unpack(args))
  end
end

return {
  {
    "xixiaofinland/sf.nvim",
    cmd = "SF", -- :SF … user commands
    ft = { -- load when editing SF-ish buffers
      "apex",
      "html",
      "javascript",
      "javascriptreact",
      "sflog",
      "soql",
      "sosl",
      "typescript",
      "typescriptreact",
    },
    -- lazy = false, -- always load (heavier; usually unnecessary)
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- apex/soql/sosl/sflog parsers (we already install)
      {
        "ibhagwan/fzf-lua", -- metadata list UI (upstream prefers this over Telescope)
        dependencies = {
          { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
        },
        opts = {}, -- stock fzf-lua; customize later if you want
        -- opts = { winopts = { preview = { default = "bat" } } },
      },
    },
    keys = {
      -- Org
      { "<leader>SF", sf_action("fetch_org_list"), desc = "SF: fetch orgs" },
      { "<leader>So", sf_action("set_target_org"), desc = "SF: set target org" },
      { "<leader>SO", sf_action("set_global_target_org"), desc = "SF: set global org" },
      { "<leader>Sb", sf_action("org_open"), desc = "SF: open org in browser" },
      { "<leader>SB", sf_action("org_open_current_file"), desc = "SF: open current metadata in org" },

      -- Retrieve / diff / logs / term
      { "<leader>Sr", sf_action("retrieve"), desc = "SF: retrieve current file" },
      { "<leader>Sd", sf_action("diff_in_target_org"), desc = "SF: diff with target org" },
      { "<leader>Sl", sf_action("pull_log"), desc = "SF: pull debug log" },
      { "<leader>Se", sf_action("toggle_term"), desc = "SF: toggle terminal" },
      { "<leader>Sx", sf_action("cancel"), desc = "SF: cancel running command (e.g. deploy)" },

      -- Deploy (save + push current file)
      { "<leader>Sp", sf_action("save_and_push"), desc = "SF: save and deploy current file" },
      -- { "<leader>Sp", sf_action("push"), desc = "SF: push without save-first" }, -- if API exists / prefer

      -- Tests
      { "<leader>St", sf_action("run_current_test"), desc = "SF: test under cursor" },
      { "<leader>ST", sf_action("run_current_test_with_coverage"), desc = "SF: test under cursor + coverage" },
      { "<leader>Sa", sf_action("run_all_tests_in_this_file"), desc = "SF: all tests in file" },
      {
        "<leader>SA",
        sf_action("run_all_tests_in_this_file_with_coverage"),
        desc = "SF: all tests in file + coverage",
      },
      { "<leader>SR", sf_action("repeat_last_tests"), desc = "SF: repeat last tests" },
      { "<leader>Sv", sf_action("toggle_sign"), desc = "SF: toggle coverage signs" },
      { "[v", sf_action("uncovered_jump_backward"), desc = "SF: previous uncovered line" },
      { "]v", sf_action("uncovered_jump_forward"), desc = "SF: next uncovered line" },

      -- SOQL (visual selection)
      {
        "<leader>Sq",
        sf_action("run_highlighted_soql"),
        mode = "x",
        desc = "SF: run selected SOQL",
      },

      -- Metadata (needs fzf-lua for list pickers)
      { "<leader>SM", sf_action("pull_md_json"), desc = "SF: pull metadata inventory" },
      { "<leader>Sm", sf_action("list_md_to_retrieve"), desc = "SF: list metadata to retrieve" },
      { "<leader>SK", sf_action("pull_md_type_json"), desc = "SF: pull metadata types" },
      { "<leader>Sk", sf_action("list_md_type_to_retrieve"), desc = "SF: list metadata types" },

      -- sObjects for apex_ls completion
      {
        "<leader>Ss",
        function()
          require("sf").refresh_sobjects({ category = "ALL" })
        end,
        desc = "SF: refresh SObject definitions",
      },
      -- { "<leader>Ss", function() require("sf").refresh_sobjects({ category = "CUSTOM" }) end, … },

      -- Ctags (optional host tool: universal-ctags)
      { "<leader>Sc", sf_action("create_ctags"), desc = "SF: create Apex ctags" },
    },
    config = function()
      require("sf").setup({
        enable_hotkeys = false, -- we define <leader>S… above (avoids fighting Telescope <leader>s)
        -- enable_hotkeys = true, -- upstream defaults (many conflicts)

        fetch_org_list_at_nvim_start = false, -- don't run `sf org list` on every Neovim start
        -- fetch_org_list_at_nvim_start = true, -- auto-fetch; use <leader>SF manually otherwise

        hotkeys_in_filetypes = {
          "apex",
          "html",
          "javascript",
          "javascriptreact",
          "sflog",
          "soql",
          "sosl",
          "typescript",
          "typescriptreact",
        },

        types_to_retrieve = {
          "ApexClass",
          "ApexTrigger",
          "AuraDefinitionBundle",
          "CustomObject",
          "FlexiPage",
          "Flow",
          "LightningComponentBundle",
          "OmniDataTransform",
          "OmniIntegrationProcedure",
          "OmniScript",
          "PermissionSet",
          "StaticResource",
        },

        terminal = "integrated", -- disposable SF term UI
        -- terminal = "overseer", -- needs overseer.nvim dependency

        auto_display_code_sign = true, -- show coverage signs after coverage test runs
        -- auto_display_code_sign = false, -- only via <leader>Sv
      })

      -- Upstream maps every *.log → sflog. Limit that to SF cache / tooling dirs
      -- so unrelated app logs stay filetype "log".
      vim.filetype.add({
        extension = {
          log = function(path)
            local normalized = path:gsub("\\", "/")
            if normalized:find("/sf_cache/", 1, true) or normalized:find("/.sfdx/", 1, true) then
              return "sflog"
            end
            return "log"
            -- return "sflog" -- adopt upstream: all .log files are sflog
          end,
        },
      })
    end,
  },
}
