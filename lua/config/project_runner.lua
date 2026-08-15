--------------------------------------------------------------------------------
-- Project runner — detect the nearest project and run its native CLI tasks.
-- Uses one reusable terminal split; no task-runner plugin or shell interpolation
-- of raw project values.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local title = "Project runner"
local terminal = { buf = nil, win = nil, job = nil, serial = 0 }

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = title })
end

local function exists(path, kind)
  local stat = uv.fs_stat(path)
  return stat ~= nil and (kind == nil or stat.type == kind)
end

local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or {}
end

local function read_text(path)
  return table.concat(read_lines(path), "\n")
end

local function contains_text(path, pattern)
  return read_text(path):find(pattern) ~= nil
end

local function shell_command(args)
  return table.concat(
    vim.tbl_map(function(arg)
      return vim.fn.shellescape(tostring(arg))
    end, args),
    " "
  )
end

local function rendered_steps(root, steps)
  return table.concat(
    vim.tbl_map(function(step)
      local cwd = step.cwd or root
      local command = shell_command(step.args)
      if cwd == root then
        return command
      end
      return string.format("cd %s && %s", vim.fn.shellescape(cwd), command)
    end, steps),
    " && "
  )
end

local function job_running()
  if not terminal.job then
    return false
  end
  local status = vim.fn.jobwait({ terminal.job }, 0)[1]
  return status == -1
end

local function open_terminal_window(use_existing_buffer)
  local height = math.max(10, math.floor(vim.o.lines * 0.30))
  if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
    vim.api.nvim_set_current_win(terminal.win)
  else
    vim.cmd(string.format("botright %dsplit", height))
    terminal.win = vim.api.nvim_get_current_win()
  end

  if use_existing_buffer and terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
    vim.api.nvim_win_set_buf(terminal.win, terminal.buf)
    return terminal.buf
  end

  local old_buf = terminal.buf
  local buf = vim.api.nvim_create_buf(false, true)
  terminal.serial = terminal.serial + 1
  vim.api.nvim_buf_set_name(buf, string.format("project://task/%d", terminal.serial))
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.keymap.set("n", "q", function()
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      pcall(vim.api.nvim_win_close, win, true)
      if terminal.win == win then
        terminal.win = nil
      end
    end
  end, { buffer = buf, silent = true, desc = "Project: hide task terminal" })
  vim.api.nvim_win_set_buf(terminal.win, buf)
  terminal.buf = buf

  if old_buf and old_buf ~= buf and vim.api.nvim_buf_is_valid(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end
  return buf
end

local function focus_terminal()
  if not terminal.buf or not vim.api.nvim_buf_is_valid(terminal.buf) then
    notify("The project task terminal is no longer available.", vim.log.levels.WARN)
    return
  end
  open_terminal_window(true)
  vim.cmd("startinsert")
end

local function missing_executable(steps)
  for _, step in ipairs(steps) do
    local executable = step.args[1]
    if executable:find("/", 1, true) then
      if vim.fn.executable(executable) ~= 1 then
        return executable
      end
    elseif vim.fn.executable(executable) ~= 1 then
      return executable
    end
  end
end

local function start_task(project, label, steps)
  local missing = missing_executable(steps)
  if missing then
    notify("Missing executable: " .. missing .. "\nSee docs/TOOLS.md.", vim.log.levels.ERROR)
    return
  end

  local command = rendered_steps(project.root, steps)
  local buf = open_terminal_window(false)
  vim.api.nvim_set_current_buf(buf)
  notify(string.format("%s\n%s", label, command))

  local job
  job = vim.fn.jobstart({ vim.o.shell, vim.o.shellcmdflag, command }, {
    cwd = project.root,
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if terminal.job == job then
          terminal.job = nil
        end
        if code ~= 0 then
          notify(string.format("%s exited with code %d.", label, code), vim.log.levels.ERROR)
        end
      end)
    end,
  })
  if job <= 0 then
    terminal.job = nil
    notify("Could not start project task.", vim.log.levels.ERROR)
    return
  end

  terminal.job = job
  vim.cmd("startinsert")
end

local function static_action(label, args)
  return {
    label = label,
    steps = { { args = args } },
  }
end

local function multi_action(label, steps)
  return {
    label = label,
    steps = steps,
  }
end

local function rust_actions(root)
  local actions = {
    static_action("Build", { "cargo", "build" }),
    static_action("Test", { "cargo", "test" }),
  }
  if exists(vim.fs.joinpath(root, "src", "main.rs"), "file") then
    table.insert(actions, 1, static_action("Run (builds when needed)", { "cargo", "run" }))
  end
  return actions
end

local function go_actions()
  return {
    static_action("Run (builds when needed)", { "go", "run", "." }),
    static_action("Build", { "go", "build", "./..." }),
    static_action("Test", { "go", "test", "./..." }),
  }
end

local function package_scripts(root)
  local path = vim.fs.joinpath(root, "package.json")
  local ok, decoded = pcall(vim.json.decode, read_text(path))
  if not ok or type(decoded) ~= "table" or type(decoded.scripts) ~= "table" then
    return {}
  end
  return decoded.scripts
end

local function node_actions(root)
  local scripts = package_scripts(root)
  local actions, added = {}, {}
  local preferred = { "dev", "start", "build", "test", "preview" }
  local labels = {
    dev = "Run — dev",
    start = "Run — start",
    build = "Build — build",
    test = "Test — test",
    preview = "Run — preview",
  }

  for _, name in ipairs(preferred) do
    if scripts[name] then
      local needs_build = (name == "start" or name == "preview") and scripts.build
      if needs_build then
        actions[#actions + 1] = multi_action(labels[name] .. " (builds first)", {
          { args = { "npm", "run", "build" } },
          { args = { "npm", "run", name } },
        })
      else
        actions[#actions + 1] = static_action(labels[name], { "npm", "run", name })
      end
      added[name] = true
    end
  end

  local remaining = {}
  for name in pairs(scripts) do
    if not added[name] then
      remaining[#remaining + 1] = name
    end
  end
  table.sort(remaining)
  for _, name in ipairs(remaining) do
    actions[#actions + 1] = static_action("Script — " .. name, { "npm", "run", name })
  end
  return actions
end

local function python_scripts(root)
  local scripts, in_scripts = {}, false
  for _, line in ipairs(read_lines(vim.fs.joinpath(root, "pyproject.toml"))) do
    local section = line:match("^%s*%[([^]]+)%]%s*$")
    if section then
      in_scripts = section == "project.scripts"
    elseif in_scripts then
      local name = line:match('^%s*["\']?([%w_.-]+)["\']?%s*=')
      if name then
        scripts[#scripts + 1] = name
      end
    end
  end
  table.sort(scripts)
  return scripts
end

local function python_actions(root)
  local actions = {}
  for _, script in ipairs(python_scripts(root)) do
    actions[#actions + 1] = static_action("Run — " .. script, { "uv", "run", script })
  end
  if #actions == 0 and exists(vim.fs.joinpath(root, "main.py"), "file") then
    actions[#actions + 1] = static_action("Run — main.py", { "uv", "run", "main.py" })
  end
  if contains_text(vim.fs.joinpath(root, "pyproject.toml"), "%[build%-system%]") then
    actions[#actions + 1] = static_action("Build distributions", { "uv", "build" })
  end
  if exists(vim.fs.joinpath(root, "tests"), "directory") then
    actions[#actions + 1] = static_action("Test", { "uv", "run", "--with", "pytest", "pytest" })
  end
  return actions
end

local function maven_executable(root)
  local wrapper = vim.fs.joinpath(root, "mvnw")
  return exists(wrapper, "file") and wrapper or "mvn"
end

local function detect_main_class(root)
  local source_root = vim.fs.joinpath(root, "src", "main", "java")
  if not exists(source_root, "directory") then
    return nil
  end
  local files = vim.fs.find(function(name)
    return name:match("%.java$") ~= nil
  end, { path = source_root, type = "file", limit = 100 })
  table.sort(files)
  for _, path in ipairs(files) do
    if read_text(path):find("static%s+void%s+main%s*%(") then
      local relative = vim.fs.relpath(source_root, path)
      if relative then
        return relative:gsub("%.java$", ""):gsub("[/\\]", ".")
      end
    end
  end
end

local function maven_actions(root)
  local mvn = maven_executable(root)
  return {
    {
      label = "Run main class (builds first)",
      resolve = function(done)
        vim.ui.input({
          prompt = "Fully qualified main class: ",
          default = detect_main_class(root),
        }, function(main_class)
          main_class = main_class and vim.trim(main_class) or ""
          if main_class == "" then
            return
          end
          if not main_class:match("^[A-Za-z_$][A-Za-z0-9_$.]*$") then
            notify("Enter a fully qualified Java class name.", vim.log.levels.ERROR)
            return
          end
          done({
            {
              args = {
                mvn,
                "compile",
                "exec:java",
                "-Dexec.mainClass=" .. main_class,
              },
            },
          })
        end)
      end,
    },
    static_action("Build package (skip tests)", { mvn, "package", "-DskipTests" }),
    static_action("Test", { mvn, "test" }),
  }
end

local function flutter_actions(root)
  local actions = {
    static_action("Run (builds when needed)", { "flutter", "run" }),
    static_action("Test", { "flutter", "test" }),
  }
  local system = uv.os_uname().sysname
  local targets = {}
  local candidates = {
    { dir = "android", target = "apk", label = "Android APK" },
    { dir = "android", target = "appbundle", label = "Android App Bundle" },
    { dir = "web", target = "web", label = "Web" },
    { dir = "ios", target = "ios", label = "iOS", systems = { Darwin = true } },
    { dir = "macos", target = "macos", label = "macOS", systems = { Darwin = true } },
    { dir = "linux", target = "linux", label = "Linux", systems = { Linux = true } },
    { dir = "windows", target = "windows", label = "Windows", systems = { Windows_NT = true } },
  }
  for _, candidate in ipairs(candidates) do
    local supported = candidate.systems == nil or candidate.systems[system]
    if supported and exists(vim.fs.joinpath(root, candidate.dir), "directory") then
      targets[#targets + 1] = candidate
    end
  end
  if #targets > 0 then
    actions[#actions + 1] = {
      label = "Build release…",
      resolve = function(done)
        vim.ui.select(targets, {
          prompt = "Flutter build target: ",
          format_item = function(item)
            return item.label
          end,
        }, function(target)
          if target then
            done({ { args = { "flutter", "build", target.target } } })
          end
        end)
      end,
    }
  end
  return actions
end

local function cmake_uses_dev_preset(root)
  for _, filename in ipairs({ "CMakeUserPresets.json", "CMakePresets.json" }) do
    local path = vim.fs.joinpath(root, filename)
    if exists(path, "file") and contains_text(path, '"name"%s*:%s*"dev"') then
      return true
    end
  end
  return false
end

local function cmake_has_run_target(root)
  for _, path in ipairs({
    vim.fs.joinpath(root, "CMakeLists.txt"),
    vim.fs.joinpath(root, "cmake", "dev-mode.cmake"),
  }) do
    if contains_text(path, "run_exe") then
      return true
    end
  end
  return false
end

local function cmake_steps(root)
  if cmake_uses_dev_preset(root) then
    return {
      { args = { "cmake", "--preset=dev" } },
      { args = { "cmake", "--build", "build" } },
    }
  end
  return {
    { args = { "cmake", "-S", ".", "-B", "build" } },
    { args = { "cmake", "--build", "build" } },
  }
end

local function cmake_actions(root)
  local build = cmake_steps(root)
  local actions = {
    multi_action("Build (configure first)", build),
    multi_action("Test (build first)", vim.list_extend(vim.deepcopy(build), {
      { args = { "ctest", "--test-dir", "build", "--output-on-failure" } },
    })),
  }
  if cmake_has_run_target(root) then
    table.insert(actions, 1, multi_action("Run executable (builds first)", {
      build[1],
      { args = { "cmake", "--build", "build", "-t", "run_exe" } },
    }))
  end
  return actions
end

local project_types = {
  { id = "rust", label = "Rust", marker = "Cargo.toml", actions = rust_actions },
  { id = "node", label = "Node / TypeScript", marker = "package.json", actions = node_actions },
  { id = "python", label = "Python", marker = "pyproject.toml", actions = python_actions },
  { id = "go", label = "Go", marker = "go.mod", actions = go_actions },
  { id = "maven", label = "Java — Maven", marker = "pom.xml", actions = maven_actions },
  { id = "flutter", label = "Flutter", marker = "pubspec.yaml", actions = flutter_actions },
  { id = "cmake", label = "C / C++ — CMake", marker = "CMakeLists.txt", actions = cmake_actions },
}

local function starting_directory()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" then
    local stat = uv.fs_stat(name)
    if stat and stat.type == "file" then
      return vim.fs.dirname(name)
    end
    if stat and stat.type == "directory" then
      return name
    end
  end
  return vim.fn.getcwd()
end

local function detected_projects()
  local start = starting_directory()
  local candidates, nearest_length = {}, 0
  for _, project_type in ipairs(project_types) do
    local marker = vim.fs.find(project_type.marker, { path = start, upward = true, type = "file" })[1]
    if marker then
      local root = vim.fs.dirname(marker)
      local length = #root
      if length > nearest_length then
        candidates = {}
        nearest_length = length
      end
      if length == nearest_length then
        candidates[#candidates + 1] = vim.tbl_extend("force", project_type, { root = root })
      end
    end
  end
  return candidates
end

local function choose_project(done)
  local projects = detected_projects()
  if #projects == 0 then
    notify("No supported project marker found above the current buffer.", vim.log.levels.WARN)
    return
  end
  if #projects == 1 then
    done(projects[1])
    return
  end
  vim.ui.select(projects, {
    prompt = "Project type: ",
    format_item = function(project)
      return project.label
    end,
  }, done)
end

local function select_action(project)
  local actions = project.actions(project.root)
  if #actions == 0 then
    notify("No runnable actions were detected for this project.", vim.log.levels.WARN)
    return
  end
  vim.ui.select(actions, {
    prompt = string.format("%s action: ", project.label),
    format_item = function(action)
      return action.label
    end,
  }, function(action)
    if not action then
      return
    end
    local function launch(steps)
      if steps and #steps > 0 then
        start_task(project, action.label, steps)
      end
    end
    if action.resolve then
      action.resolve(launch)
    else
      launch(action.steps)
    end
  end)
end

local function choose_and_run()
  choose_project(select_action)
end

function M.open()
  if not job_running() then
    choose_and_run()
    return
  end
  vim.ui.select({ "Focus running task", "Stop and choose another task", "Cancel" }, {
    prompt = "A project task is already running: ",
  }, function(choice)
    if choice == "Focus running task" then
      focus_terminal()
    elseif choice == "Stop and choose another task" then
      local job = terminal.job
      terminal.job = nil
      vim.fn.jobstop(job)
      vim.schedule(choose_and_run)
    end
  end)
end

return M
