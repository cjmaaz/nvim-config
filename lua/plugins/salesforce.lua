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
local function cancel_sf_actions(opts)
  opts = opts or {}
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

  if cancelled == 0 and not opts.quiet then
    vim.notify("No running Salesforce action to cancel.", vim.log.levels.INFO, { title = "sf.nvim" })
  elseif cancelled > 0 then
    vim.notify(string.format("Cancellation requested for %d Salesforce action(s).", cancelled), vim.log.levels.WARN, {
      title = "sf.nvim",
    })
  end
  return cancelled
end

local function cancel_sf_or_clear_search()
  if cancel_sf_actions({ quiet = true }) == 0 then
    vim.cmd("nohlsearch")
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

local function salesforce_root(bufnr, refresh)
  local project_context = require("config.project_context")
  if refresh then
    project_context.invalidate(bufnr or vim.api.nvim_get_current_buf())
  end
  return project_context.salesforce_root(bufnr)
end

local function guarded_load(callback, bufnr)
  if not salesforce_root(bufnr, true) then
    vim.notify("Open this from a Salesforce project first.", vim.log.levels.WARN, { title = "sf.nvim" })
    return false
  end
  if not package.loaded.sf then
    pcall(vim.api.nvim_del_user_command, "SF")
    require("lazy").load({ plugins = { "sf.nvim" } })
    if not package.loaded.sf then
      vim.notify("Could not load sf.nvim.", vim.log.levels.ERROR, { title = "sf.nvim" })
      return false
    end
  end
  if callback then
    callback()
  end
  return true
end

local plugin = {
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
      -- Fetch hydrates common inventory; target selection only changes CLI context.
      {
        "<leader>SF",
        function()
          sf_metadata().fetch_orgs_and_refresh_common()
        end,
        desc = "Fetch orgs + common metadata",
      },
      {
        "<leader>So",
        function()
          sf_metadata().select_target()
        end,
        desc = "Set local target org",
      },
      {
        "<leader>SO",
        function()
          sf_metadata().select_global_target()
        end,
        desc = "Set global target org",
      },
      { "<leader>Sb", sf_action("org_open"), desc = "Open org in browser" },
      { "<leader>SB", sf_action("org_open_current_file"), desc = "Open current metadata in org" },

      -- Retrieve / diff / logs / term
      { "<leader>Sr", sf_action("retrieve"), desc = "Retrieve current file" },
      { "<leader>Sd", sf_action("diff_in_target_org"), desc = "Diff with target org" },
      { "<leader>Sl", sf_action("pull_log"), desc = "Pull debug log" },
      { "<leader>Se", sf_action("toggle_term"), desc = "Toggle terminal" },
      { "<leader>Sx", cancel_sf_actions, desc = "Cancel active actions" },
      {
        "<leader>SV",
        function()
          require("config.salesforce.vlocity").open()
        end,
        desc = "Retrieve Vlocity DataPacks",
      },

      -- Deploy (save + push current file)
      { "<leader>Sp", sf_action("save_and_push"), desc = "Save and deploy current file" },
      -- { "<leader>Sp", sf_action("push"), desc = "Push without save-first" }, -- if API exists / prefer

      -- Tests
      { "<leader>St", sf_action("run_current_test"), desc = "Test under cursor" },
      { "<leader>ST", sf_action("run_current_test_with_coverage"), desc = "Test under cursor + coverage" },
      { "<leader>Sa", sf_action("run_all_tests_in_this_file"), desc = "All tests in file" },
      {
        "<leader>SA",
        sf_action("run_all_tests_in_this_file_with_coverage"),
        desc = "All tests in file + coverage",
      },
      { "<leader>SR", sf_action("repeat_last_tests"), desc = "Repeat last tests" },
      { "<leader>Sv", sf_action("toggle_sign"), desc = "Toggle coverage signs" },
      { "[v", sf_action("uncovered_jump_backward"), desc = "Previous uncovered line" },
      { "]v", sf_action("uncovered_jump_forward"), desc = "Next uncovered line" },

      -- SOQL builder / whole-file / visual selection.
      {
        "<leader>SQ",
        function()
          require("config.salesforce.query").open()
        end,
        desc = "Build SOQL query",
      },
      {
        "<leader>Sq",
        function()
          require("config.salesforce.query").run_current(false)
        end,
        mode = "n",
        desc = "Run SOQL file",
      },
      {
        "<leader>Sq",
        sf_action("run_highlighted_soql"),
        mode = "x",
        desc = "Run selected SOQL",
      },

      -- Metadata (needs fzf-lua for list pickers)
      { "<leader>Sm", sf_action("list_md_to_retrieve"), desc = "Pick cached metadata to retrieve" },
      {
        "<leader>SU",
        function()
          sf_metadata().prompt_refresh()
        end,
        desc = "Refresh metadata inventory",
      },
      {
        "<leader>Su",
        function()
          require("config.salesforce.browser").open()
        end,
        desc = "Browse metadata inventory",
      },
      {
        "<leader>SP",
        function()
          require("config.salesforce.manifests").open()
        end,
        desc = "Browse package manifests",
      },

      -- sObjects for apex_ls completion
      {
        "<leader>Ss",
        function()
          require("sf").refresh_sobjects({ category = "ALL" })
        end,
        desc = "Refresh SObject definitions",
      },
      -- { "<leader>Ss", function() require("sf").refresh_sobjects({ category = "CUSTOM" }) end, desc = "Refresh custom SObjects" },

      -- Ctags (optional host tool: universal-ctags)
      { "<leader>Sc", sf_action("create_ctags"), desc = "Create Apex ctags" },
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
      require("config.salesforce.query").setup()

      -- SFTerm visibility belongs to <leader>Se (q also hides when focused).
      -- Esc cancels any foreground/background SF action; otherwise it clears search.
      vim.keymap.set("n", "<Esc>", cancel_sf_or_clear_search, {
        silent = true,
        desc = "Cancel active actions / clear search",
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "SFTerm",
        callback = function(event)
          local opts = { buffer = event.buf, silent = true, desc = "Hide Salesforce terminal" }
          vim.keymap.set("n", "q", hide_visible_sf_terms, opts)
          vim.keymap.set("n", "<Esc>", cancel_sf_actions, {
            buffer = event.buf,
            silent = true,
            desc = "Cancel active actions",
          })
          vim.keymap.set("n", "<C-c>", cancel_sf_actions, {
            buffer = event.buf,
            silent = true,
            desc = "Cancel active actions",
          })
          vim.keymap.set("t", "<Esc>", cancel_sf_actions, {
            buffer = event.buf,
            silent = true,
            desc = "Cancel active actions",
          })
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
}

local guarded_keys = plugin.keys
plugin.keys = nil
plugin.cmd = nil
plugin.ft = nil

plugin.init = function()
  for _, key in ipairs(guarded_keys) do
    local mapping = key
    local mode = mapping.mode or "n"
    vim.keymap.set(mode, mapping[1], function()
      guarded_load(mapping[2])
    end, {
      desc = mapping.desc,
      silent = mapping.silent,
    })
  end

  vim.api.nvim_create_user_command("SF", function(opts)
    guarded_load(function()
      vim.cmd("SF" .. (opts.args ~= "" and (" " .. opts.args) or ""))
    end)
  end, {
    nargs = "*",
    desc = "Salesforce commands (Salesforce projects only)",
  })

  local group = vim.api.nvim_create_augroup("salesforce_root_loader", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = {
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
    callback = function(event)
      if salesforce_root(event.buf, true) then
        guarded_load(nil, event.buf)
      end
    end,
  })
end

return { plugin }
