--------------------------------------------------------------------------------
-- Salesforce actions — captured project/buffer context and argv-only processes.
--------------------------------------------------------------------------------

local M = {}

local api = vim.api
local uv = vim.uv or vim.loop
local org_context = require("config.salesforce.org_context")
local process = require("config.salesforce.process")
local safety = require("config.salesforce.safety")
local terminal = require("config.salesforce.terminal")
local last_tests = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Salesforce" })
end

local function canonical(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end
  return safety.resolve_path(path)
end

local function path_within(root, path)
  root, path = canonical(root), canonical(path)
  return root and path and (path == root or path:sub(1, #root + 1) == root .. "/")
end

local function valid_origin(ctx, require_path)
  if type(ctx) ~= "table" then
    return nil, "Salesforce project context is unavailable."
  end
  if not api.nvim_buf_is_valid(ctx.bufnr) or not api.nvim_buf_is_loaded(ctx.bufnr) then
    return nil, "The originating buffer is no longer available."
  end
  local current_path = api.nvim_buf_get_name(ctx.bufnr)
  current_path = current_path ~= "" and vim.fs.normalize(current_path) or nil
  if ctx.path ~= current_path then
    return nil, "The originating buffer was renamed; retry the action."
  end
  local root = canonical(require("config.project_context").salesforce_root(ctx.bufnr))
  if root ~= canonical(ctx.root) then
    return nil, "The originating buffer now belongs to another Salesforce project."
  end
  if require_path and (not ctx.path or not path_within(ctx.root, ctx.path)) then
    return nil, "Save this file inside the Salesforce project first."
  end
  return true
end

local function valid_capture(ctx, require_path)
  if not org_context.is_current(ctx) then
    return nil, "Salesforce project or target org changed; retry the action."
  end
  return valid_origin(ctx, require_path)
end

local function with_project(input, callback, opts)
  opts = opts or {}
  if type(input) == "table" and input.root and input.bufnr then
    local ok, err = valid_origin(input, opts.require_path)
    if not ok then
      notify(err, vim.log.levels.WARN)
      return
    end
    callback(input)
    return
  end
  local bufnr = type(input) == "table" and input.bufnr or input or api.nvim_get_current_buf()
  local root = canonical(require("config.project_context").salesforce_root(bufnr))
  if not root then
    notify("Open this from a Salesforce project first.", vim.log.levels.WARN)
    return
  end
  local path = api.nvim_buf_get_name(bufnr)
  local win = vim.fn.bufwinid(bufnr)
  local ctx = {
    bufnr = bufnr,
    win = win ~= -1 and win or nil,
    path = path ~= "" and vim.fs.normalize(path) or nil,
    root = root,
  }
  local ok, err = valid_origin(ctx, opts.require_path)
  if not ok then
    notify(err, vim.log.levels.WARN)
    return
  end
  callback(ctx)
end

local function with_context(input, callback, opts)
  opts = opts or {}
  if type(input) == "table" and input.org and input.root and input.bufnr then
    local ok, err = valid_capture(input, opts.require_path)
    if not ok then
      notify(err, vim.log.levels.WARN)
      return
    end
    callback(input)
    return
  end
  local bufnr = type(input) == "table" and input.bufnr or input
  org_context.capture(bufnr or api.nvim_get_current_buf(), function(ctx, err)
    if not ctx then
      notify(err or "Could not resolve the Salesforce project.", vim.log.levels.ERROR)
      return
    end
    local ok, capture_error = valid_capture(ctx, opts.require_path)
    if not ok then
      notify(capture_error, vim.log.levels.WARN)
      return
    end
    callback(ctx)
  end)
end

local function run_term(ctx, args, callback)
  return terminal.run(args, { cwd = ctx.root }, callback)
end

local function run_sf(ctx, args, callback)
  process.run(args, { cwd = ctx.root }, function(result)
    if result.code ~= 0 then
      notify((result.stderr or "Salesforce command failed."):gsub("%s+$", ""), vim.log.levels.ERROR)
      if callback then
        callback(false, result)
      end
      return
    end
    if callback then
      callback(true, result)
    end
  end)
end

local function open_path(path)
  if type(path) == "string" and path ~= "" and uv.fs_stat(path) then
    vim.cmd.edit({ args = { path } })
    return true
  end
  return false
end

local function safe_directory(ctx, path)
  local cap, err = safety.path_for(ctx.root, path, { allow_missing = true })
  if not cap then
    notify(err, vim.log.levels.ERROR)
    return nil
  end
  local created, create_error = safety.mkdirs(cap)
  if not created then
    notify(create_error, vim.log.levels.ERROR)
    return nil
  end
  return created.path
end

local function visual_selection(bufnr)
  local mode = vim.fn.mode()
  local first
  local last
  if bufnr == api.nvim_get_current_buf() and (mode == "v" or mode == "V" or mode == "\22") then
    local anchor = vim.fn.getpos("v")
    local cursor = api.nvim_win_get_cursor(0)
    first = { anchor[2], math.max(0, anchor[3] - 1) }
    last = { cursor[1], cursor[2] }
    if mode == "V" then
      first[2] = 0
      last[2] = math.max(0, #(api.nvim_buf_get_lines(bufnr, last[1] - 1, last[1], false)[1] or "") - 1)
    end
  else
    first = api.nvim_buf_get_mark(bufnr, "<")
    last = api.nvim_buf_get_mark(bufnr, ">")
  end
  if first[1] == 0 or last[1] == 0 then
    return nil
  end
  local start_row, start_col = first[1] - 1, first[2]
  local end_row, end_col = last[1] - 1, last[2] + 1
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = last[2], first[2] + 1
  end
  local ok, lines = pcall(api.nvim_buf_get_text, bufnr, start_row, start_col, end_row, end_col, {})
  return ok and vim.trim(table.concat(lines, "\n")) or nil
end

local function in_origin(ctx, callback, cursor_sensitive)
  local ok, result
  if ctx.win and api.nvim_win_is_valid(ctx.win) and api.nvim_win_get_buf(ctx.win) == ctx.bufnr then
    ok, result = pcall(api.nvim_win_call, ctx.win, callback)
  elseif cursor_sensitive then
    return nil, "The original Apex cursor window is no longer available; retry from that buffer."
  else
    ok, result = pcall(api.nvim_buf_call, ctx.bufnr, callback)
  end
  return ok and result or nil, ok and nil or tostring(result)
end

local function test_names(ctx, current_method)
  local value, err = in_origin(ctx, function()
    local ts = require("sf.ts")
    local class = ts.get_test_class_name()
    local methods = current_method and { ts.get_current_test_method_name() } or ts.get_test_method_names_in_curr_file()
    return { class = class, methods = methods }
  end, current_method)
  if not value then
    return nil, err
  end
  if type(value.class) ~= "string" or not value.class:match("^[A-Za-z_][A-Za-z0-9_]*$") then
    return nil, "Not in an Apex test class."
  end
  local methods = {}
  for _, method in ipairs(value.methods or {}) do
    if type(method) == "string" and method:match("^[A-Za-z_][A-Za-z0-9_]*$") then
      methods[#methods + 1] = method
    end
  end
  if current_method and #methods == 0 then
    return nil, "Cursor is not in an @IsTest method."
  end
  return value.class, methods
end

local function coverage_path(ctx)
  return vim.fs.joinpath(ctx.root, "sf_cache", "test_result.json")
end

local function save_coverage(ctx, term_buf)
  if not api.nvim_buf_is_valid(term_buf) then
    return
  end
  local id
  for _, line in ipairs(api.nvim_buf_get_lines(term_buf, 0, -1, false)) do
    id = id or line:match("Test Run Id%s*([%w]+)")
  end
  if not id then
    notify("Test finished, but no coverage run ID was returned.", vim.log.levels.WARN)
    return
  end
  process.run({
    "sf",
    "apex",
    "get",
    "test",
    "--test-run-id",
    id,
    "--code-coverage",
    "--json",
    "--target-org",
    ctx.org,
  }, { cwd = ctx.root }, function(result)
    if result.code ~= 0 then
      notify("Could not save Apex coverage: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
      return
    end
    local path = coverage_path(ctx)
    local ok, write_error = safety.atomic_write(ctx.root, path, result.stdout or "")
    if not ok then
      notify("Could not write Apex coverage: " .. tostring(write_error), vim.log.levels.ERROR)
      return
    end
    local sign_ok, signs = pcall(require, "sf.sub.test_sign")
    if sign_ok and api.nvim_buf_is_valid(ctx.bufnr) then
      api.nvim_buf_call(ctx.bufnr, signs.invalidate_cache_and_try_place)
    end
  end)
end

local function run_tests(ctx, class, methods, coverage)
  local args = {
    "sf",
    "apex",
    "run",
    "test",
    "--result-format",
    "human",
    "--wait",
    tostring((vim.g.sf or {}).sf_wait_time or 5),
    "--target-org",
    ctx.org,
  }
  if methods and #methods > 0 then
    for _, method in ipairs(methods) do
      args[#args + 1] = "--tests"
      args[#args + 1] = class .. "." .. method
    end
  else
    args[#args + 1] = "--class-names"
    args[#args + 1] = class
  end
  if coverage then
    args[#args + 1] = "--code-coverage"
  else
    args[#args + 1] = "--concise"
  end
  last_tests[ctx.root] = {
    args = vim.deepcopy(args),
    coverage = coverage,
    org = ctx.org,
    revision = ctx.revision,
  }
  run_term(ctx, args, function(ok, _, term_buf)
    if ok and coverage then
      save_coverage(ctx, term_buf)
    end
  end)
end

function M.retrieve(input)
  with_context(input, function(ctx)
    run_term(ctx, {
      "sf",
      "project",
      "retrieve",
      "start",
      "--source-dir",
      ctx.path,
      "--target-org",
      ctx.org,
    }, function(ok)
      if ok and api.nvim_buf_is_valid(ctx.bufnr) then
        vim.schedule(function()
          pcall(api.nvim_buf_call, ctx.bufnr, function()
            vim.cmd("silent checktime")
          end)
        end)
      end
    end)
  end, { require_path = true })
end

function M.deploy(input)
  with_context(input, function(ctx)
    local wrote, write_error = pcall(api.nvim_buf_call, ctx.bufnr, function()
      vim.cmd("silent write")
    end)
    if not wrote then
      notify("Could not save current metadata: " .. tostring(write_error), vim.log.levels.ERROR)
      return
    end
    run_term(ctx, {
      "sf",
      "project",
      "deploy",
      "start",
      "--source-dir",
      ctx.path,
      "--target-org",
      ctx.org,
    })
  end, { require_path = true })
end

function M.open_org(input)
  with_context(input, function(ctx)
    run_sf(ctx, { "sf", "org", "open", "--target-org", ctx.org })
  end)
end

function M.open_current(input)
  with_context(input, function(ctx)
    run_sf(ctx, {
      "sf",
      "org",
      "open",
      "--source-file",
      ctx.path,
      "--target-org",
      ctx.org,
    })
  end, { require_path = true })
end

function M.capture_visual(bufnr)
  return visual_selection(bufnr or api.nvim_get_current_buf())
end

function M.run_query_selection(input, captured_query)
  with_context(input, function(ctx)
    local query = captured_query or visual_selection(ctx.bufnr)
    if not query or query == "" then
      notify("Select a SOQL query first.", vim.log.levels.WARN)
      return
    end
    run_term(ctx, {
      "sf",
      "data",
      "query",
      "--query",
      query,
      "--target-org",
      ctx.org,
    })
  end)
end

function M.run_anonymous(input)
  with_context(input, function(ctx)
    run_term(ctx, {
      "sf",
      "apex",
      "run",
      "--file",
      ctx.path,
      "--target-org",
      ctx.org,
    })
  end, { require_path = true })
end

function M.diff(input, selected_org)
  with_context(input, function(ctx)
    local org = selected_org or ctx.org
    local temp = vim.fs.joinpath(ctx.root, "sf_cache", "diffs", vim.fn.sha256(ctx.path):sub(1, 16))
    if not safe_directory(ctx, temp) then
      return
    end
    process.run_sf_json({
      "sf",
      "project",
      "retrieve",
      "start",
      "--source-dir",
      ctx.path,
      "--output-dir",
      temp,
      "--target-org",
      org,
      "--json",
    }, { cwd = ctx.root }, function(err, result)
      if err then
        notify("Retrieve for diff failed: " .. err, vim.log.levels.ERROR)
        return
      end
      local remote
      for _, file in ipairs((result or {}).files or {}) do
        if file.state == "Failed" then
          notify("Retrieve for diff failed: " .. tostring(file.error or "unknown error"), vim.log.levels.ERROR)
          return
        end
        local file_path = file.filePath
        if file_path and file_path:sub(1, 1) ~= "/" and not file_path:match("^%a:[/\\]") then
          file_path = vim.fs.joinpath(ctx.root, file_path)
        end
        if file_path and uv.fs_stat(file_path) and path_within(temp, file_path) then
          if vim.fs.basename(file_path) == vim.fs.basename(ctx.path) then
            remote = file_path
            break
          end
          remote = remote or file_path
        end
      end
      if not remote then
        for path, kind in vim.fs.dir(temp, { depth = math.huge }) do
          if kind == "file" then
            local candidate = path:sub(1, 1) == "/" and path or vim.fs.joinpath(temp, path)
            local safe_candidate = safety.path_for(ctx.root, candidate)
            if
              safe_candidate
              and path_within(temp, safe_candidate.path)
              and vim.fs.basename(path) == vim.fs.basename(ctx.path)
            then
              remote = safe_candidate.path
              break
            end
          end
        end
      end
      if not remote then
        notify("Retrieve succeeded, but the remote file was not found.", vim.log.levels.ERROR)
        return
      end
      if not api.nvim_buf_is_valid(ctx.bufnr) then
        return
      end
      api.nvim_buf_call(ctx.bufnr, function()
        vim.cmd.diffsplit({ args = { remote }, mods = { vertical = true } })
        vim.bo.buflisted = false
      end)
    end)
  end, { require_path = true })
end

function M.diff_in_org(input)
  with_context(input, function(ctx)
    process.run_sf_json(
      { "sf", "org", "list", "--json", "--skip-connection-status" },
      { cwd = ctx.root },
      function(err, result)
        if err then
          notify("Could not list Salesforce orgs: " .. err, vim.log.levels.ERROR)
          return
        end
        local choices = {}
        for _, org in ipairs(vim.list_extend(result.nonScratchOrgs or {}, result.scratchOrgs or {})) do
          choices[#choices + 1] = org.alias or org.username
        end
        vim.ui.select(choices, { prompt = "Select org to diff in:" }, function(org)
          if org then
            M.diff(ctx, org)
          end
        end)
      end
    )
  end, { require_path = true })
end

function M.run_current_test(input, coverage)
  with_context(input, function(ctx)
    local class, methods_or_error = test_names(ctx, true)
    if not class then
      notify(methods_or_error, vim.log.levels.WARN)
      return
    end
    run_tests(ctx, class, methods_or_error, coverage == true)
  end, { require_path = true })
end

function M.run_file_tests(input, coverage)
  with_context(input, function(ctx)
    local class, methods_or_error = test_names(ctx, false)
    if not class then
      notify(methods_or_error, vim.log.levels.WARN)
      return
    end
    run_tests(ctx, class, nil, coverage == true)
  end, { require_path = true })
end

function M.select_tests(input)
  with_context(input, function(ctx)
    local class, methods_or_error = test_names(ctx, false)
    if not class then
      notify(methods_or_error, vim.log.levels.WARN)
      return
    end
    local methods = methods_or_error
    if #methods == 0 then
      notify("No @IsTest methods found in this file.", vim.log.levels.WARN)
      return
    end
    require("fzf-lua").fzf_exec(methods, {
      prompt = "Apex tests> ",
      header = "Tab select | Enter run",
      fzf_opts = { ["--multi"] = true },
      actions = {
        ["default"] = function(selected)
          if selected and #selected > 0 and valid_capture(ctx, true) then
            run_tests(ctx, class, selected, false)
          end
        end,
      },
    })
  end, { require_path = true })
end

function M.run_local_tests(input)
  with_context(input, function(ctx)
    local args = {
      "sf",
      "apex",
      "run",
      "test",
      "--test-level",
      "RunLocalTests",
      "--code-coverage",
      "--result-format",
      "human",
      "--wait",
      "180",
      "--target-org",
      ctx.org,
    }
    last_tests[ctx.root] = { args = vim.deepcopy(args), coverage = true, org = ctx.org, revision = ctx.revision }
    run_term(ctx, args, function(ok, _, term_buf)
      if ok then
        save_coverage(ctx, term_buf)
      end
    end)
  end)
end

function M.repeat_tests(input)
  with_context(input, function(ctx)
    local previous = last_tests[ctx.root]
    if not previous or previous.org ~= ctx.org then
      notify("No previous Apex test exists for this project and target org.", vim.log.levels.WARN)
      return
    end
    run_term(ctx, vim.deepcopy(previous.args), function(ok, _, term_buf)
      if ok and previous.coverage then
        save_coverage(ctx, term_buf)
      end
    end)
  end)
end

function M.fetch_orgs(input)
  with_project(input, function(ctx)
    process.run_sf_json(
      { "sf", "org", "list", "--json", "--skip-connection-status" },
      { cwd = ctx.root },
      function(err, result)
        if err then
          notify("Could not fetch Salesforce orgs: " .. err, vim.log.levels.ERROR)
          return
        end
        local count = #(result.nonScratchOrgs or {}) + #(result.scratchOrgs or {})
        notify(("Fetched %d Salesforce org%s."):format(count, count == 1 and "" or "s"))
      end
    )
  end)
end

function M.pull_log(input)
  with_context(input, function(ctx)
    process.run_sf_json({
      "sf",
      "apex",
      "list",
      "log",
      "--target-org",
      ctx.org,
      "--json",
    }, { cwd = ctx.root }, function(err, logs)
      if err then
        notify("Could not list Apex logs: " .. err, vim.log.levels.ERROR)
        return
      end
      if #logs == 0 then
        notify("No Apex logs found.", vim.log.levels.WARN)
        return
      end
      vim.ui.select(logs, {
        prompt = "Apex log:",
        format_item = function(log)
          local user = log.LogUser and log.LogUser.Name or log.User or ""
          return string.format(
            "%s | %s | %s bytes | %s",
            user,
            log.StartTime or "",
            log.LogLength or 0,
            log.Status or ""
          )
        end,
      }, function(log)
        if not log then
          return
        end
        local dir = vim.fs.joinpath(ctx.root, "sf_cache", "logs")
        if not safe_directory(ctx, dir) then
          return
        end
        run_sf(ctx, {
          "sf",
          "apex",
          "get",
          "log",
          "--log-id",
          log.Id,
          "--output-dir",
          dir,
          "--target-org",
          ctx.org,
        }, function(ok)
          if ok and not open_path(vim.fs.joinpath(dir, log.Id .. ".log")) then
            notify("Log downloaded, but its output file was not found.", vim.log.levels.WARN)
          end
        end)
      end)
    end)
  end)
end

local function package_default(root)
  local file = vim.fs.joinpath(root, "sfdx-project.json")
  local ok, lines = pcall(vim.fn.readfile, file, "b")
  local decoded_ok, project = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  if not decoded_ok or type(project) ~= "table" then
    return vim.fs.joinpath(root, "force-app", "main", "default")
  end
  local selected
  for _, entry in ipairs(project.packageDirectories or {}) do
    if entry.default then
      selected = entry.path
      break
    end
    selected = selected or entry.path
  end
  local base = vim.fs.joinpath(root, selected or "force-app")
  if not base:gsub("\\", "/"):match("/main/default$") then
    base = vim.fs.joinpath(base, "main", "default")
  end
  return base
end

local function create_component(input, kind, supplied_name)
  with_project(input, function(ctx)
    local function create(name)
      name = vim.trim(name or "")
      if not name:match("^[A-Za-z_][A-Za-z0-9_]*$") then
        notify("Use a Salesforce identifier containing only letters, numbers, and underscores.", vim.log.levels.ERROR)
        return
      end
      local base = package_default(ctx.root)
      local args, opened
      if kind == "apex" then
        local dir = vim.fs.joinpath(base, "classes")
        args = { "sf", "apex", "generate", "class", "--output-dir", dir, "--name", name }
        opened = vim.fs.joinpath(dir, name .. ".cls")
      elseif kind == "trigger" then
        local dir = vim.fs.joinpath(base, "triggers")
        args = { "sf", "apex", "generate", "trigger", "--output-dir", dir, "--name", name }
        opened = vim.fs.joinpath(dir, name .. ".trigger")
      else
        local dir = vim.fs.joinpath(base, kind)
        args = {
          "sf",
          "lightning",
          "generate",
          "component",
          "--output-dir",
          dir,
          "--name",
          name,
          "--type",
          kind,
        }
        opened = vim.fs.joinpath(dir, name, name .. (kind == "aura" and ".cmp" or ".js"))
      end
      local output_dir = args[6]
      if not path_within(ctx.root, output_dir) then
        notify("Generated metadata output resolves outside the Salesforce project.", vim.log.levels.ERROR)
        return
      end
      run_sf(ctx, args, function(ok)
        if ok then
          open_path(opened)
        end
      end)
    end
    if supplied_name and supplied_name ~= "" then
      create(supplied_name)
    else
      vim.ui.input({ prompt = ("Enter %s name: "):format(kind) }, create)
    end
  end)
end

function M.create_apex(input, name)
  create_component(input, "apex", name)
end

function M.create_trigger(input, name)
  create_component(input, "trigger", name)
end

function M.create_aura(input, name)
  create_component(input, "aura", name)
end

function M.create_lwc(input, name)
  create_component(input, "lwc", name)
end

function M.create_ctags(input, list_after)
  with_project(input, function(ctx)
    if vim.fn.executable("ctags") ~= 1 then
      notify("Universal Ctags is required.", vim.log.levels.ERROR)
      return
    end
    local tags = vim.fs.joinpath(ctx.root, "tags")
    local classes = vim.fs.joinpath(package_default(ctx.root), "classes")
    local tags_cap, tags_error = safety.path_for(ctx.root, tags, { allow_missing = true })
    if not tags_cap or not path_within(ctx.root, classes) or not uv.fs_stat(classes) then
      notify(tags_error or "Apex classes directory is unavailable or outside the project.", vim.log.levels.ERROR)
      return
    end
    run_sf(ctx, {
      "ctags",
      "--extras=+q",
      "--langmap=Java:+.cls.trigger",
      "-f",
      tags,
      "-R",
      classes,
    }, function(ok)
      if ok then
        notify("Tags updated successfully.")
        if list_after then
          require("fzf-lua").tags({ cwd = ctx.root })
        end
      end
    end)
  end)
end

function M.metadata_list(input)
  with_context(input, function(ctx)
    api.nvim_buf_call(ctx.bufnr, function()
      require("config.salesforce.browser").open()
    end)
  end)
end

function M.metadata_refresh(input, common)
  with_context(input, function(ctx)
    api.nvim_buf_call(ctx.bufnr, function()
      if common then
        require("config.salesforce.metadata").refresh_common()
      else
        require("config.salesforce.metadata").refresh_all()
      end
    end)
  end)
end

function M.toggle_terminal()
  terminal.toggle()
end

function M.cancel_terminal()
  return terminal.cancel()
end

function M.install_command_overrides()
  local ok, commands = pcall(require, "sf.sub.config_user_command")
  if not ok then
    return
  end
  local funcs = commands.sub_cmd_tbl
  funcs.currentFile.funcs.push = M.deploy
  funcs.currentFile.funcs.retrieve = M.retrieve
  funcs.currentFile.funcs.diff = M.diff
  funcs.currentFile.funcs.diffIn = M.diff_in_org
  funcs.currentFile.funcs.RunAsAnonymous = M.run_anonymous
  funcs.md.funcs.pull = function()
    M.metadata_refresh(nil, true)
  end
  funcs.md.funcs.list = M.metadata_list
  funcs.mdtype.funcs.pull = function()
    M.metadata_refresh(nil, false)
  end
  funcs.mdtype.funcs.list = M.metadata_list
  funcs.org.funcs.setTarget = function()
    require("config.salesforce.metadata").select_target()
  end
  funcs.org.funcs.setGlobalTarget = function()
    require("config.salesforce.metadata").select_global_target()
  end
  funcs.org.funcs.fetchList = M.fetch_orgs
  funcs.org.funcs.open = M.open_org
  funcs.org.funcs.openCurrentFile = M.open_current
  funcs.org.funcs.pullLog = M.pull_log
  funcs.term.funcs.toggle = M.toggle_terminal
  funcs.term.funcs.cancel = M.cancel_terminal
  funcs.test.funcs.currentTest = M.run_current_test
  funcs.test.funcs.allTestsInThisFile = M.run_file_tests
  funcs.test.funcs.select = M.select_tests
  funcs.test.funcs.allTestsInOrg = M.run_local_tests
  funcs.create.funcs.apex = function(name)
    M.create_apex(nil, name)
  end
  funcs.create.funcs.lwc = function(name)
    M.create_lwc(nil, name)
  end
  funcs.create.funcs.aura = function(name)
    M.create_aura(nil, name)
  end
  funcs.create.funcs.trigger = function(name)
    M.create_trigger(nil, name)
  end
  funcs.create.funcs.ctags = M.create_ctags
  funcs.create.funcs.ctagsAndList = function()
    M.create_ctags(nil, true)
  end
  funcs.sobject.funcs.refresh = function(opts)
    require("config.salesforce.sobject").refresh(opts)
  end
  pcall(api.nvim_del_user_command, "SF")
  commands.create_user_commands()
end

M._test = {
  last_tests = last_tests,
  package_default = package_default,
  path_within = path_within,
  valid_capture = valid_capture,
  visual_selection = visual_selection,
}

return M
