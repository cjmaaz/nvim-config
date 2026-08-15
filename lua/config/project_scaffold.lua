--------------------------------------------------------------------------------
-- Project scaffolding — one picker over each ecosystem's maintained CLI.
-- Generates Maven, Flutter, CMake, Rust, Python, Node/Vite, and Go projects
-- without storing stale framework templates in this config.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local title = "Project scaffold"
local running = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = title })
end

local function validate_project_name(value)
  if value == "" then
    return false, "Project name cannot be empty."
  end
  if value == "." or value == ".." or not value:match("^[A-Za-z0-9_][A-Za-z0-9_.-]*$") then
    return false, "Use letters, numbers, `_`, `-`, or `.`; do not include a path."
  end
  return true
end

local function validate_flutter_name(value)
  if not value:match("^[a-z][a-z0-9_]*$") then
    return false, "Flutter names must use lowercase_with_underscores."
  end
  return true
end

local function validate_cmake_name(value)
  if not value:match("^[A-Za-z0-9_][A-Za-z0-9_-]*$") then
    return false, "cmake-init names may contain letters, numbers, `_`, or `-`."
  end
  return true
end

local function validate_package_name(value)
  if not value:match("^[A-Za-z0-9_][A-Za-z0-9_-]*$") then
    return false, "Use letters, numbers, `_`, or `-`; do not include a path."
  end
  return true
end

local function validate_package_id(value)
  if value == "" or value:sub(1, 1) == "." or value:sub(-1) == "." or value:find("..", 1, true) then
    return false, "Use a dotted identifier such as `com.example`."
  end
  for segment in value:gmatch("[^.]+") do
    if not segment:match("^[A-Za-z_][A-Za-z0-9_]*$") then
      return false, "Every package segment must be a valid Java-style identifier."
    end
  end
  return true
end

local function validate_go_module(value)
  if value == "" or value:find("%s") or value:sub(1, 1) == "/" or value:sub(-1) == "/" then
    return false, "Use a Go module path such as `example.com/user/project`."
  end
  if value:find("//", 1, true) or not value:match("^[A-Za-z0-9._~/%-]+$") then
    return false, "Go module paths cannot contain spaces or shell characters."
  end
  return true
end

local function prepare_directory(path)
  local ok, result = pcall(vim.fn.mkdir, path, "p")
  if not ok or result == 0 then
    return false, "Could not create target directory: " .. path
  end
  return true
end

local function write_lines(path, lines)
  local ok, result = pcall(vim.fn.writefile, lines, path)
  if not ok or result ~= 0 then
    return false, "Could not write starter file: " .. path
  end
  return true
end

local function normalize_parent(value)
  local expanded = vim.fn.expand(value)
  return vim.fs.normalize(vim.fn.fnamemodify(expanded, ":p"))
end

local function validate_parent(value)
  local stat = uv.fs_stat(value)
  if not stat or stat.type ~= "directory" then
    return false, "Parent directory does not exist: " .. value
  end
  return true
end

local function display_command(args)
  return table.concat(
    vim.tbl_map(function(arg)
      return vim.fn.shellescape(arg)
    end, args),
    " "
  )
end

local function failure_output(result)
  local output = vim.trim(table.concat({ result.stdout or "", result.stderr or "" }, "\n"))
  if output == "" then
    return string.format("Generator exited with code %d.", result.code)
  end

  local lines = vim.split(output, "\n", { plain = true })
  if #lines > 12 then
    lines = vim.list_slice(lines, #lines - 11, #lines)
  end
  return table.concat(lines, "\n")
end

local generators = {
  {
    id = "maven",
    label = "Java — Maven quickstart",
    icon = vim.g.have_nerd_font and " " or "",
    executable = "mvn",
    install_hint = "Install Maven (`brew install maven` / `sudo pacman -S maven`).",
    default_name = "my-app",
    entry = "pom.xml",
    fields = {
      {
        key = "group_id",
        prompt = "Maven group/package ID: ",
        default = "com.example",
        validate = validate_package_id,
      },
    },
    command = function(context)
      return {
        "mvn",
        "--batch-mode",
        "archetype:generate",
        "-DgroupId=" .. context.group_id,
        "-DartifactId=" .. context.name,
        "-DarchetypeGroupId=org.apache.maven.archetypes",
        "-DarchetypeArtifactId=maven-archetype-quickstart",
        "-DarchetypeVersion=1.5",
        "-DinteractiveMode=false",
      }
    end,
  },
  {
    id = "flutter",
    label = "Flutter — App",
    icon = vim.g.have_nerd_font and " " or "",
    executable = "flutter",
    install_hint = "Install the Flutter SDK and put `flutter` on PATH.",
    default_name = "my_app",
    validate_name = validate_flutter_name,
    entry = vim.fs.joinpath("lib", "main.dart"),
    fields = {
      {
        key = "organization",
        prompt = "Flutter organization ID: ",
        default = "com.example",
        validate = validate_package_id,
      },
    },
    command = function(context)
      return {
        "flutter",
        "create",
        "--template=app",
        "--org=" .. context.organization,
        "--project-name=" .. context.name,
        context.target,
      }
    end,
  },
  {
    id = "cmake",
    label = "C++ — CMake executable",
    icon = vim.g.have_nerd_font and " " or "",
    executable = "cmake-init",
    install_hint = "Install CMake and `cmake-init` 0.41+ (`pipx install cmake-init`).",
    default_name = "my_project",
    validate_name = validate_cmake_name,
    entry = "CMakeLists.txt",
    command = function(context)
      return { "cmake-init", "create", context.target, "-e" }
    end,
  },
  {
    id = "rust-bin",
    label = "Rust — Binary",
    icon = vim.g.have_nerd_font and " " or "",
    executable = "cargo",
    install_hint = "Install Rust with rustup so `cargo` is available on PATH.",
    default_name = "my_rust_app",
    validate_name = validate_package_name,
    entry = vim.fs.joinpath("src", "main.rs"),
    command = function(context)
      return { "cargo", "new", context.target, "--bin" }
    end,
  },
  {
    id = "rust-lib",
    label = "Rust — Library",
    icon = vim.g.have_nerd_font and " " or "",
    executable = "cargo",
    install_hint = "Install Rust with rustup so `cargo` is available on PATH.",
    default_name = "my_rust_lib",
    validate_name = validate_package_name,
    entry = vim.fs.joinpath("src", "lib.rs"),
    command = function(context)
      return { "cargo", "new", context.target, "--lib" }
    end,
  },
  {
    id = "python-app",
    label = "Python — Packaged app",
    icon = vim.g.have_nerd_font and "󰌠 " or "",
    executable = "uv",
    install_hint = "Install uv (`brew install uv` / `sudo pacman -S uv`).",
    default_name = "my-python-app",
    validate_name = validate_package_name,
    entry = "pyproject.toml",
    command = function(context)
      return { "uv", "init", "--package", context.target }
    end,
  },
  {
    id = "python-lib",
    label = "Python — Library",
    icon = vim.g.have_nerd_font and "󰌠 " or "",
    executable = "uv",
    install_hint = "Install uv (`brew install uv` / `sudo pacman -S uv`).",
    default_name = "my-python-lib",
    validate_name = validate_package_name,
    entry = "pyproject.toml",
    command = function(context)
      return { "uv", "init", "--lib", context.target }
    end,
  },
  {
    id = "node-ts",
    label = "Node — TypeScript CLI",
    icon = vim.g.have_nerd_font and "󰎙 " or "",
    executable = "npm",
    install_hint = "Install Node.js and npm (`brew install node` / `sudo pacman -S nodejs npm`).",
    default_name = "my-node-app",
    validate_name = validate_package_name,
    entry = vim.fs.joinpath("src", "index.ts"),
    prepare = function(context)
      local ok, message = prepare_directory(vim.fs.joinpath(context.target, "src"))
      if not ok then
        return false, message
      end
      ok, message = write_lines(vim.fs.joinpath(context.target, "src", "index.ts"), {
        string.format('console.log("Hello from %s!");', context.name),
      })
      if not ok then
        return false, message
      end
      return write_lines(vim.fs.joinpath(context.target, "tsconfig.json"), {
        "{",
        '  "compilerOptions": {',
        '    "target": "ES2022",',
        '    "module": "NodeNext",',
        '    "moduleResolution": "NodeNext",',
        '    "rootDir": "src",',
        '    "outDir": "dist",',
        '    "strict": true,',
        '    "esModuleInterop": true,',
        '    "skipLibCheck": true',
        "  },",
        '  "include": ["src"]',
        "}",
      })
    end,
    steps = function(context)
      return {
        { args = { "npm", "init", "--yes" }, cwd = context.target },
        {
          args = { "npm", "install", "--save-dev", "typescript", "tsx", "@types/node" },
          cwd = context.target,
        },
        {
          args = {
            "npm",
            "pkg",
            "set",
            "type=module",
            "scripts.dev=tsx src/index.ts",
            "scripts.build=tsc",
            "scripts.start=node dist/index.js",
          },
          cwd = context.target,
        },
      }
    end,
  },
  {
    id = "vite-ts",
    label = "Vite — Vanilla TypeScript",
    icon = vim.g.have_nerd_font and "󰎙 " or "",
    executable = "npm",
    install_hint = "Install Node.js and npm (`brew install node` / `sudo pacman -S nodejs npm`).",
    default_name = "my-vite-app",
    validate_name = validate_package_name,
    entry = vim.fs.joinpath("src", "main.ts"),
    steps = function(context)
      return {
        {
          args = {
            "npm",
            "create",
            "vite@latest",
            context.name,
            "--",
            "--template",
            "vanilla-ts",
            "--no-interactive",
          },
          cwd = context.parent,
          env = { npm_config_yes = "true" },
        },
        { args = { "npm", "install" }, cwd = context.target },
      }
    end,
  },
  {
    id = "go",
    label = "Go — Application",
    icon = vim.g.have_nerd_font and " " or "",
    executable = "go",
    install_hint = "Install Go (`brew install go` / `sudo pacman -S go`).",
    default_name = "my-go-app",
    validate_name = validate_package_name,
    entry = "main.go",
    fields = {
      {
        key = "module_path",
        prompt = "Go module path: ",
        default = function(context)
          return "example.com/" .. context.name
        end,
        validate = validate_go_module,
      },
    },
    prepare = function(context)
      local ok, message = prepare_directory(context.target)
      if not ok then
        return false, message
      end
      return write_lines(vim.fs.joinpath(context.target, "main.go"), {
        "package main",
        "",
        'import "fmt"',
        "",
        "func main() {",
        string.format('\tfmt.Println("Hello from %s!")', context.name),
        "}",
      })
    end,
    steps = function(context)
      return {
        { args = { "go", "mod", "init", context.module_path }, cwd = context.target },
        { args = { "go", "fmt", "./..." }, cwd = context.target },
      }
    end,
  },
}

local function steps_for(generator, context)
  if generator.steps then
    return generator.steps(context)
  end
  return {
    {
      args = generator.command(context),
      cwd = context.parent,
    },
  }
end

local function display_steps(steps)
  return table.concat(
    vim.tbl_map(function(step)
      return string.format("(%s) %s", step.cwd, display_command(step.args))
    end, steps),
    "\n"
  )
end

local function run_steps(steps, index, done)
  local step = steps[index]
  if not step then
    done(true)
    return
  end

  local started, process_or_error = pcall(vim.system, step.args, {
    cwd = step.cwd,
    env = step.env,
    text = true,
  }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        done(false, string.format("%s\n%s", display_command(step.args), failure_output(result)))
        return
      end
      run_steps(steps, index + 1, done)
    end)
  end)

  if not started then
    done(false, "Could not start generator:\n" .. tostring(process_or_error))
  end
end

local function fields_for(generator)
  local fields = {
    {
      key = "name",
      prompt = "Project name: ",
      default = generator.default_name,
      validate = generator.validate_name or validate_project_name,
    },
    {
      key = "parent",
      prompt = "Parent directory: ",
      default = function()
        return vim.fn.getcwd()
      end,
      transform = normalize_parent,
      validate = validate_parent,
    },
  }
  vim.list_extend(fields, generator.fields or {})
  return fields
end

local function prompt_fields(fields, index, context, done)
  local field = fields[index]
  if not field then
    done(context)
    return
  end

  local default = type(field.default) == "function" and field.default(context) or field.default
  vim.ui.input({ prompt = field.prompt, default = default }, function(value)
    if value == nil then
      return
    end

    value = vim.trim(value)
    if field.transform then
      value = field.transform(value)
    end

    local valid, message = field.validate(value, context)
    if not valid then
      notify(message, vim.log.levels.ERROR)
      vim.schedule(function()
        prompt_fields(fields, index, context, done)
      end)
      return
    end

    context[field.key] = value
    vim.schedule(function()
      prompt_fields(fields, index + 1, context, done)
    end)
  end)
end

local function open_generated_project(generator, context)
  local stat = uv.fs_stat(context.target)
  if not stat or stat.type ~= "directory" then
    notify("Generator succeeded but did not create " .. context.target, vim.log.levels.ERROR)
    return
  end

  local ok, error_message = pcall(vim.api.nvim_set_current_dir, context.target)
  if not ok then
    notify("Created project, but could not change directory:\n" .. tostring(error_message), vim.log.levels.WARN)
    return
  end

  local entry = vim.fs.joinpath(context.target, generator.entry)
  if uv.fs_stat(entry) then
    local opened, open_error = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(entry))
    if not opened then
      notify("Created project, but could not open its entry file:\n" .. tostring(open_error), vim.log.levels.WARN)
      return
    end
  end

  notify("Created " .. generator.label .. "\n" .. context.target)
end

local function run_generator(generator, context)
  if running then
    notify("Another project generator is already running.", vim.log.levels.WARN)
    return
  end

  context.target = vim.fs.joinpath(context.parent, context.name)
  if uv.fs_stat(context.target) then
    notify("Target already exists: " .. context.target, vim.log.levels.ERROR)
    return
  end

  local steps = steps_for(generator, context)
  notify("Command preview:\n" .. display_steps(steps))
  vim.ui.select({ "Create project", "Cancel" }, {
    prompt = string.format("Create %s in %s?", generator.label, context.parent),
  }, function(choice)
    if choice ~= "Create project" then
      return
    end

    running = true
    notify("Creating " .. context.name .. "…")
    if generator.prepare then
      local prepared, ok, message = pcall(generator.prepare, context)
      if not prepared or not ok then
        running = false
        local error_message = prepared and message or ok
        notify(tostring(error_message or "Could not prepare project files."), vim.log.levels.ERROR)
        return
      end
    end

    run_steps(steps, 1, function(ok, message)
      running = false
      if not ok then
        notify(message, vim.log.levels.ERROR)
        return
      end
      open_generated_project(generator, context)
    end)
  end)
end

function M.open()
  vim.ui.select(generators, {
    prompt = "Project type: ",
    format_item = function(generator)
      return generator.icon .. generator.label
    end,
  }, function(generator)
    if not generator then
      return
    end
    if vim.fn.executable(generator.executable) ~= 1 then
      notify(generator.install_hint, vim.log.levels.ERROR)
      return
    end

    prompt_fields(fields_for(generator), 1, {}, function(context)
      run_generator(generator, context)
    end)
  end)
end

return M
