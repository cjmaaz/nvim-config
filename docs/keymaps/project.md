# Project scaffolding

Defined in `lua/config/project_scaffold.lua` and opened from `lua/config/keymaps.lua`. It uses Neovim’s built-in inputs plus the existing Telescope `vim.ui.select` interface; no scaffolding plugin or copied framework templates are installed.

Nav: [index](./README.md) · [core](./core.md) · [telescope](./telescope.md) · [explorer](./explorer.md) · [TOOLS](../TOOLS.md)

---

## Create a project

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>pn` | n | Select and generate a new project |

`<leader>` is **Space**, so press `Space`, `p`, `n`.

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

The command runs as an argument list through `vim.system`; project names and paths are not interpolated into a shell command. Output is captured asynchronously. On failure, the last output lines are shown and any partially generated directory is left for inspection.

Install only the generators you use; missing executables produce a focused error. See [TOOLS.md](../TOOLS.md#project-generators).

---

## Extending the menu

The `generators` registry in `lua/config/project_scaffold.lua` keeps project-specific details together:

- label, icon, executable, and install hint;
- name validation and extra prompts;
- argument-list builder;
- entry file to open after generation.

Future generators such as `cargo new`, `npm create`, or `meson init` can be added without changing the picker workflow.

---

Nav: [index](./README.md) · [core](./core.md) · [telescope](./telescope.md) · [explorer](./explorer.md) · [TOOLS](../TOOLS.md)
