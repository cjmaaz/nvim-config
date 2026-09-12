--------------------------------------------------------------------------------
-- Salesforce — sf.nvim (CLI workflows: org, retrieve, deploy, tests, metadata)
-- Refs: CodeOSS salesforce.lua; upstream xixiaofinland/sf.nvim.
-- Needs: `sf` CLI on PATH · SF project root (sfdx-project.json / .forceignore).
-- apex_ls stays in lsp.lua; this plugin is org/test/deploy/metadata UI.
-- Alts: raw `:!sf …` in terminal · skip fzf-lua (lose md list pickers).
--------------------------------------------------------------------------------

local function sf_action(method, ...)
  local args = { ... }
  return function(ctx)
    local function invoke()
      local sf = require("sf")
      sf[method](unpack(args))
    end
    if ctx and ctx.win and vim.api.nvim_win_is_valid(ctx.win) and vim.api.nvim_win_get_buf(ctx.win) == ctx.bufnr then
      vim.api.nvim_win_call(ctx.win, invoke)
    elseif ctx and ctx.bufnr and vim.api.nvim_buf_is_valid(ctx.bufnr) then
      vim.api.nvim_buf_call(ctx.bufnr, invoke)
    else
      invoke()
    end
  end
end

local function sf_metadata()
  return require("config.salesforce.metadata")
end

local function sf_actions()
  return require("config.salesforce.actions")
end

local project_caps = {}

local function in_captured_buffer(ctx, callback)
  if not ctx or not ctx.bufnr or not vim.api.nvim_buf_is_valid(ctx.bufnr) then
    return
  end
  return vim.api.nvim_buf_call(ctx.bufnr, callback)
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
  if require("config.salesforce.terminal").hide() then
    return true
  end
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
  local owned_terminal = require("config.salesforce.terminal")
  cancelled = cancelled + owned_terminal.cancel()
  local owned_buf = owned_terminal.current_buffer()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      buf ~= owned_buf
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].filetype == "SFTerm"
      and vim.bo[buf].buftype == "terminal"
    then
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

local function salesforce_root(bufnr, refresh)
  local project_context = require("config.project_context")
  if refresh then
    project_context.invalidate(bufnr or vim.api.nvim_get_current_buf())
  end
  return project_context.salesforce_root(bufnr)
end

local function guarded_load(callback, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local root = salesforce_root(bufnr, true)
  if not root then
    vim.notify("Open this from a Salesforce project first.", vim.log.levels.WARN, { title = "sf.nvim" })
    return false
  end
  local cap, safety_error = require("config.salesforce.safety").preflight(root)
  if not cap then
    vim.notify(safety_error, vim.log.levels.ERROR, { title = "sf.nvim" })
    return false
  end
  project_caps[cap.root] = cap
  if not package.loaded.sf then
    pcall(vim.api.nvim_del_user_command, "SF")
    require("lazy").load({ plugins = { "sf.nvim" } })
    if not package.loaded.sf then
      vim.notify("Could not load sf.nvim.", vim.log.levels.ERROR, { title = "sf.nvim" })
      return false
    end
  end
  require("config.salesforce.org_context").capture(bufnr, function(ctx, err)
    if ctx then
      local ok, util = pcall(require, "sf.util")
      if ok then
        util.target_org = ctx.org -- compatibility mirror; commands still receive explicit --target-org
      end
    elseif err then
      vim.notify(err, vim.log.levels.WARN, { title = "sf.nvim" })
      ctx = {
        bufnr = bufnr,
        path = vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) or nil,
        root = root,
      }
    end
    if callback then
      callback(ctx)
    end
  end)
  return true
end

local function register_local_actions()
  local provider = require("config.local_actions.salesforce").new({
    cancel = cancel_sf_actions,
    guarded_load = guarded_load,
    salesforce_root = salesforce_root,
    actions = sf_actions,
  })
  require("config.local_actions").register(provider)
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
      -- Keep upstream fetch semantics: refresh orgs/default target, not metadata.
      { "<leader>SF", sf_actions().fetch_orgs, desc = "Fetch orgs" },
      {
        "<leader>So",
        function(ctx)
          in_captured_buffer(ctx, function()
            sf_metadata().select_target()
          end)
        end,
        desc = "Set local target org",
      },
      {
        "<leader>SO",
        function(ctx)
          in_captured_buffer(ctx, function()
            sf_metadata().select_global_target()
          end)
        end,
        desc = "Set global target org",
      },
      { "<leader>Sb", sf_actions().open_org, desc = "Open org in browser" },
      { "<leader>SB", sf_actions().open_current, desc = "Open current metadata in org" },

      -- Retrieve / diff / logs / term
      { "<leader>Sr", sf_actions().retrieve, desc = "Retrieve current file" },
      { "<leader>Sd", sf_actions().diff, desc = "Diff with target org" },
      { "<leader>Sl", sf_actions().pull_log, desc = "Pull debug log" },
      { "<leader>Se", sf_actions().toggle_terminal, desc = "Toggle terminal" },
      { "<leader>Sx", cancel_sf_actions, desc = "Cancel active actions" },
      {
        "<leader>SV",
        function(ctx)
          in_captured_buffer(ctx, function()
            require("config.salesforce.vlocity").open()
          end)
        end,
        desc = "Retrieve Vlocity DataPacks",
      },

      -- Deploy (save + push current file)
      { "<leader>Sp", sf_actions().deploy, desc = "Save and deploy current file" },
      -- { "<leader>Sp", sf_action("push"), desc = "Push without save-first" }, -- if API exists / prefer

      -- Tests
      { "<leader>St", sf_actions().run_current_test, desc = "Test under cursor" },
      {
        "<leader>ST",
        function(ctx)
          sf_actions().run_current_test(ctx, true)
        end,
        desc = "Test under cursor + coverage",
      },
      { "<leader>Sa", sf_actions().run_file_tests, desc = "All tests in file" },
      {
        "<leader>SA",
        function(ctx)
          sf_actions().run_file_tests(ctx, true)
        end,
        desc = "All tests in file + coverage",
      },
      { "<leader>SR", sf_actions().repeat_tests, desc = "Repeat last tests" },
      { "<leader>Sv", sf_action("toggle_sign"), desc = "Toggle coverage signs" },
      { "[v", sf_action("uncovered_jump_backward"), desc = "Previous uncovered line" },
      { "]v", sf_action("uncovered_jump_forward"), desc = "Next uncovered line" },

      -- SOQL builder / whole-file / visual selection.
      {
        "<leader>SQ",
        function(ctx)
          in_captured_buffer(ctx, function()
            require("config.salesforce.query").open()
          end)
        end,
        desc = "Build SOQL query",
      },
      {
        "<leader>Sq",
        function(ctx)
          in_captured_buffer(ctx, function()
            require("config.salesforce.query").run_current(false, ctx.bufnr)
          end)
        end,
        mode = "n",
        desc = "Run SOQL file",
      },
      {
        "<leader>Sq",
        sf_actions().run_query_selection,
        mode = "x",
        capture_visual = true,
        desc = "Run selected SOQL",
      },

      -- Metadata (needs fzf-lua for list pickers)
      { "<leader>Sm", sf_actions().metadata_list, desc = "Pick cached metadata to retrieve" },
      {
        "<leader>SU",
        function(ctx)
          in_captured_buffer(ctx, function()
            sf_metadata().prompt_refresh()
          end)
        end,
        desc = "Refresh metadata inventory",
      },
      {
        "<leader>Su",
        function(ctx)
          in_captured_buffer(ctx, function()
            require("config.salesforce.browser").open()
            -- vim.cmd("Neotree sf_org toggle left") -- put the Org Browser on Su instead
          end)
        end,
        desc = "Browse metadata inventory",
      },
      {
        "<leader>SE",
        function(ctx)
          in_captured_buffer(ctx, function()
            vim.cmd("Neotree sf_org toggle left")
          end)
        end,
        desc = "Toggle Org Browser",
      },
      {
        "<leader>SP",
        function(ctx)
          in_captured_buffer(ctx, function()
            require("config.salesforce.manifests").open()
          end)
        end,
        desc = "Browse package manifests",
      },

      -- sObjects for apex_ls completion
      {
        "<leader>Ss",
        function(ctx)
          in_captured_buffer(ctx, function()
            require("config.salesforce.sobject").refresh({ category = "ALL" })
          end)
        end,
        desc = "Refresh SObject definitions",
      },
      -- { "<leader>Ss", function() require("sf").refresh_sobjects({ category = "CUSTOM" }) end, desc = "Refresh custom SObjects" },

      -- Ctags (optional host tool: universal-ctags)
      { "<leader>Sc", sf_actions().create_ctags, desc = "Create Apex ctags" },
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

        -- Keep all plugin-generated state in the validated project cache.
        plugin_folder_name = "/sf_cache/",
        -- plugin_folder_name = "/.sf-cache/", -- alternate single project-local component
      })
      sf_actions().install_command_overrides()
      require("config.salesforce.query").setup()

      -- Replace sf.nvim's unchecked recursive diff cleanup with contained removal.
      for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = "SF", event = "VimLeavePre" })) do
        pcall(vim.api.nvim_del_autocmd, autocmd.id)
      end
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("salesforce_safe_cleanup", { clear = true }),
        callback = function()
          local safety = require("config.salesforce.safety")
          for _, project_cap in pairs(project_caps) do
            local diffs = safety.path(project_cap, "sf_cache/diffs", { allow_missing = true })
            if diffs and (vim.uv or vim.loop).fs_lstat(diffs.path) then
              safety.remove_tree(diffs)
            end
          end
        end,
      })

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
          vim.keymap.set("n", "<leader><leader>", require("config.salesforce.terminal").toggle, {
            buffer = event.buf,
            silent = true,
            desc = "Toggle Salesforce terminal",
          })
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
  register_local_actions()

  for _, key in ipairs(guarded_keys) do
    local mapping = key
    local mode = mapping.mode or "n"
    vim.keymap.set(mode, mapping[1], function()
      local bufnr = vim.api.nvim_get_current_buf()
      local selected = mapping.capture_visual and sf_actions().capture_visual(bufnr) or nil
      guarded_load(function(ctx)
        mapping[2](ctx, selected)
      end, bufnr)
    end, {
      desc = mapping.desc,
      silent = mapping.silent,
    })
  end

  vim.api.nvim_create_user_command("SF", function(opts)
    local bufnr = vim.api.nvim_get_current_buf()
    guarded_load(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("SF" .. (opts.args ~= "" and (" " .. opts.args) or ""))
        end)
      end
    end, bufnr)
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
