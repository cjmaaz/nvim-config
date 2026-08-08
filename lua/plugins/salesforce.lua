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

local function sf_metadata()
  return require("config.salesforce.metadata")
end

local function sf_term_windows()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local config = vim.api.nvim_win_get_config(win)
    if vim.bo[buf].filetype == "SFTerm" and config.relative ~= "" then
      wins[#wins + 1] = win
    end
  end
  return wins
end

--- Hide SFTerm floats without touching their terminal jobs.
local function hide_visible_sf_terms()
  local wins = sf_term_windows()
  for _, win in ipairs(wins) do
    pcall(vim.api.nvim_win_close, win, false)
  end
  return #wins > 0
end

--- Cancel SF terminal jobs and background inventory regardless of window focus.
local function cancel_sf_actions()
  local cancelled = sf_metadata().cancel_background()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "SFTerm" and vim.bo[buf].buftype == "terminal" then
      local channel = vim.bo[buf].channel
      if channel and channel > 0 and vim.fn.jobwait({ channel }, 0)[1] == -1 then
        local ok = pcall(vim.api.nvim_chan_send, channel, "\003")
        if ok then
          cancelled = cancelled + 1
        end
      end
    end
  end

  if cancelled == 0 then
    vim.notify("No running Salesforce action to cancel.", vim.log.levels.INFO, { title = "sf.nvim" })
  else
    vim.notify(string.format("Cancellation requested for %d Salesforce action(s).", cancelled), vim.log.levels.WARN, {
      title = "sf.nvim",
    })
  end
end

-- Modern `sf org display --json` redacts accessToken ("[REDACTED] Use 'sf org auth
-- show-access-token'…"). sf.nvim still feeds that into curl → HTTP 401 on
-- <leader>Ss even when retrieve/deploy work. Intercept display --json and splice
-- in a real token from `sf org auth show-access-token`.
local function install_sf_access_token_fix()
  if vim.g._sf_access_token_fix then
    return
  end
  vim.g._sf_access_token_fix = true

  local orig_system = vim.system
  vim.system = function(cmd, opts, on_exit)
    local is_org_display_json = type(cmd) == "table"
      and cmd[1] == "sf"
      and cmd[2] == "org"
      and cmd[3] == "display"
      and vim.tbl_contains(cmd, "--json")

    if not is_org_display_json then
      return orig_system(cmd, opts, on_exit)
    end

    -- Support vim.system(cmd, on_exit) two-arg form.
    if type(opts) == "function" then
      on_exit = opts
      opts = nil
    end

    local org
    for i, v in ipairs(cmd) do
      if (v == "-o" or v == "--target-org") and cmd[i + 1] then
        org = cmd[i + 1]
        break
      end
    end

    if type(on_exit) ~= "function" or not org then
      return orig_system(cmd, opts, on_exit)
    end

    return orig_system(cmd, opts, function(obj)
      if obj.code ~= 0 then
        return on_exit(obj)
      end

      local ok, parsed = pcall(vim.json.decode, obj.stdout or "")
      if not ok or type(parsed) ~= "table" or type(parsed.result) ~= "table" then
        return on_exit(obj)
      end

      local token = parsed.result.accessToken
      if type(token) == "string" and token ~= "" and not token:find("REDACTED", 1, true) then
        return on_exit(obj)
      end

      orig_system(
        { "sf", "org", "auth", "show-access-token", "-o", org, "--json", "-p" },
        { text = true },
        function(tok_obj)
          if tok_obj.code == 0 then
            local tok_ok, tok_parsed = pcall(vim.json.decode, tok_obj.stdout or "")
            local real = tok_ok
              and type(tok_parsed) == "table"
              and tok_parsed.result
              and tok_parsed.result.accessToken
            if type(real) == "string" and real ~= "" then
              parsed.result.accessToken = real
              obj.stdout = vim.json.encode(parsed)
            end
          end
          on_exit(obj)
        end
      )
    end)
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
      -- Local org fetch/set refreshes the common project-local metadata inventory.
      {
        "<leader>SF",
        function()
          sf_metadata().fetch_orgs_and_refresh_common()
        end,
        desc = "SF: fetch orgs + metadata",
      },
      {
        "<leader>So",
        function()
          sf_metadata().select_target_and_refresh_common()
        end,
        desc = "SF: set target org + metadata",
      },
      -- Global target stays selection-only (no automatic inventory refresh).
      {
        "<leader>SO",
        function()
          sf_metadata().select_global_target()
        end,
        desc = "SF: set global org",
      },
      { "<leader>Sb", sf_action("org_open"), desc = "SF: open org in browser" },
      { "<leader>SB", sf_action("org_open_current_file"), desc = "SF: open current metadata in org" },

      -- Retrieve / diff / logs / term
      { "<leader>Sr", sf_action("retrieve"), desc = "SF: retrieve current file" },
      { "<leader>Sd", sf_action("diff_in_target_org"), desc = "SF: diff with target org" },
      { "<leader>Sl", sf_action("pull_log"), desc = "SF: pull debug log" },
      { "<leader>Se", sf_action("toggle_term"), desc = "SF: toggle terminal" },
      { "<leader>Sx", cancel_sf_actions, desc = "SF: cancel active actions" },

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
      {
        "<leader>SM",
        function()
          sf_metadata().refresh_common()
        end,
        desc = "SF: pull metadata inventory",
      },
      { "<leader>Sm", sf_action("list_md_to_retrieve"), desc = "SF: list metadata to retrieve" },
      { "<leader>SK", sf_action("pull_md_type_json"), desc = "SF: pull metadata types" },
      { "<leader>Sk", sf_action("list_md_type_to_retrieve"), desc = "SF: list metadata types" },
      {
        "<leader>SU",
        function()
          sf_metadata().prompt_refresh()
        end,
        desc = "SF: update metadata browser",
      },
      {
        "<leader>Su",
        function()
          require("config.salesforce.browser").open()
        end,
        desc = "SF: browse metadata",
      },

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
      install_sf_access_token_fix()

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

      -- sf.nvim leaves SFTerm visible but restores focus to the source window.
      -- Dispatch Esc globally only while that non-focused float exists.
      vim.keymap.set("n", "<Esc>", function()
        if not hide_visible_sf_terms() then
          vim.cmd("nohlsearch")
        end
      end, { silent = true, desc = "SF: hide terminal / clear search" })

      -- SFTerm stays open after the job exits so output remains readable. Esc/q hide;
      -- <leader>Sx (or normal-mode <C-c> here) cancels regardless of focus.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "SFTerm",
        callback = function(event)
          local opts = { buffer = event.buf, silent = true, desc = "SF: hide terminal" }
          vim.keymap.set("n", "<Esc>", hide_visible_sf_terms, opts)
          vim.keymap.set("n", "q", hide_visible_sf_terms, opts)
          vim.keymap.set("n", "<C-c>", cancel_sf_actions, {
            buffer = event.buf,
            silent = true,
            desc = "SF: cancel active actions",
          })
          -- While the job is running you're often in terminal-mode; still hide, don't cancel.
          vim.keymap.set("t", "<Esc>", function()
            vim.cmd.stopinsert()
            hide_visible_sf_terms()
          end, opts)
          -- Terminal-mode <C-c> remains the terminal's native interrupt.
        end,
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
