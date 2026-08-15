# Project scaffolding

Defined in `lua/config/project_scaffold.lua` and `lua/config/project_runner.lua`, with maps in `lua/config/keymaps.lua`. It uses Neovim’s built-in inputs plus the existing Telescope `vim.ui.select` interface; no scaffolding or task-runner plugin is installed.

Nav: [index](./README.md) · [core](./core.md) · [telescope](./telescope.md) · [explorer](./explorer.md) · [TOOLS](../TOOLS.md)

---

## Create a project

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>pn` | n | Select and generate a new project |
| `<leader>pr` | n | Detect the current project and select Run / Build / Test |

`<leader>` is **Space**, so use `Space`, `p`, `n` to create or `Space`, `p`, `r` for project actions.

The flow is:

1. Select the project type.
2. Enter a project name and existing parent directory.
3. Enter ecosystem-specific information such as a Maven group ID.
4. Review the exact command shown in the notification.
5. Confirm **Create project**.
6. On success, Neovim changes to the new project directory and opens its entry file.

Cancelling any picker/input leaves the filesystem unchanged. Existing target directories are rejected rather than overwritten.

---

## Available generators

| Picker item | Command | Entry opened |
| --- | --- | --- |
| **Java — Maven quickstart** | `mvn --batch-mode archetype:generate …` using Apache Quickstart 1.5 | `pom.xml` |
| **Flutter — App** | `flutter create --template=app …` | `lib/main.dart` |
| **C++ — CMake executable** | `cmake-init create <target> -e` | `CMakeLists.txt` |
| **Rust — Binary / Library** | `cargo new --bin/--lib` | `src/main.rs` / `src/lib.rs` |
| **Python — Packaged app / Library** | `uv init --package/--lib` | `pyproject.toml` |
| **Node — TypeScript CLI** | `npm init`, TypeScript/tsx install, scripts, starter source | `src/index.ts` |
| **Vite — Vanilla TypeScript** | `npm create vite@latest … --template vanilla-ts`, then `npm install` | `src/main.ts` |
| **Go — Application** | `go mod init`, `go fmt`, and a minimal `main.go` | `main.go` |

Generator steps run as argument lists through `vim.system`; project names and paths are not interpolated into a shell command. Output is captured asynchronously. On failure, the last output lines are shown and any partially generated directory is left for inspection.

Install only the generators you use; missing executables produce a focused error. See [TOOLS.md](../TOOLS.md#project-generators).

---

## Run, build, and test

`<leader>pr` starts from the current file (or current working directory), walks upward, and chooses the nearest supported marker:

| Project | Marker | Available actions |
| --- | --- | --- |
| Rust | `Cargo.toml` | `cargo run` when binary, build, test |
| Node / Vite | `package.json` | Every package script, with dev/start/build/test first |
| Python | `pyproject.toml` | Detected console scripts or `main.py`; build when packaged; pytest when `tests/` exists |
| Go | `go.mod` | run, build, test |
| Java — Maven | `pom.xml` | run a prompted/detected main class, package, test |
| Flutter | `pubspec.yaml` | run, test, and release-build target picker |
| C / C++ — CMake | `CMakeLists.txt` | configure + build, test, and cmake-init `run_exe` when detected |

When multiple marker types share the nearest root, another picker asks which ecosystem to use. **Run** actions compile first when required by that ecosystem.

Tasks open in a reusable bottom terminal with live and interactive output. Use `<Esc><Esc>` to leave terminal mode, then `q` to hide the task window without stopping its job. If a task is already running, `<leader>pr` offers to focus it, stop it and choose another task, or cancel.

Task chains are rendered from individually shell-escaped argv values and joined with `&&`, so later steps only run after earlier steps succeed.

---

## Extending the menu

The `generators` registry in `lua/config/project_scaffold.lua` keeps project-specific details together:

- label, icon, executable, and install hint;
- name validation and extra prompts;
- one or more argument-list steps plus optional starter-file preparation;
- entry file to open after generation.

Future generators such as `meson init` can be added without changing the picker workflow. Runner support lives in the `project_types` registry in `lua/config/project_runner.lua`.

---

Nav: [index](./README.md) · [core](./core.md) · [telescope](./telescope.md) · [explorer](./explorer.md) · [TOOLS](../TOOLS.md)
