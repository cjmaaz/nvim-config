# Context-aware localleader

`<localleader>` is backslash (`\`). Unlike global Space mappings, these mappings exist only when the current file or project provides the corresponding action.

Nav: [index](./README.md) · [project](./project.md) · [salesforce](./salesforce.md) · [which-key](./which-key.md)

---

## Stable project actions

| Key | Action |
| --- | --- |
| `<localleader>p` (`\p`) | Show every action available for the current file/project |
| `<localleader>r` (`\r`) | Run; executes one candidate or opens a focused picker when several exist |
| `<localleader>b` (`\b`) | Build; Salesforce metadata uses save-and-deploy |
| `<localleader>t` (`\t`) | Test; SOQL intentionally overrides this with Tooling API query |

Unavailable actions are not mapped. An unnamed buffer, help, terminal, prompt, Neo-tree, or ordinary file outside a supported project keeps the normal `\` behavior.

which-key labels the prefix with the current providers—for example **Local · Java — Maven**, **Local · Salesforce + Node / TypeScript**, or **Local · SOQL + Salesforce**. Press `\`, then pause to discover only the actions valid in that buffer.

---

## Supported project detection

The current file is the starting point. Detection walks upward and keeps only the nearest supported project root.

| Project | Marker | Direct actions |
| --- | --- | --- |
| Rust | `Cargo.toml` | run for binaries · build · test |
| Node / Vite | `package.json` | preferred run scripts (`dev`, `start`, `preview`) · `build` · `test` |
| Python | `pyproject.toml` | console script or `main.py` · package build · pytest when `tests/` exists |
| Go | `go.mod` | run · build · test |
| Java — Maven | `pom.xml` | prompted/detected main class · package · test |
| Flutter | `pubspec.yaml` | run · release target picker · test |
| C / C++ — CMake | `CMakeLists.txt` | configured run target when available · build · test |

Every other detected script/action remains available in `\p`. If multiple ecosystems share the same nearest root, their menus merge; a direct key opens a scoped picker when equal-priority candidates compete.

Tasks reuse the existing bottom project terminal. `<leader>pr` remains the global project action entry point and uses the same runner implementation.

---

## Domain precedence

Providers merge their menu actions but compete deterministically for direct keys:

1. SOQL file actions
2. Salesforce metadata actions
3. General project actions

Examples:

- A normal Node file uses `\r` dev/start, `\b` build, and `\t` test.
- An LWC JavaScript file can show both Salesforce and Node actions in `\p`; Salesforce save-and-deploy owns `\b`, while Node still owns `\r` and `\t`.
- An ordinary Salesforce-project script such as `scripts/setup.ts` keeps Node’s `\b`; cloud file actions are limited to Apex and recognized Aura/LWC/Visualforce/static-resource paths.
- An Apex file uses `\b` for save-and-deploy and `\t` for the test under the cursor.
- A SOQL draft preserves `\f` fields, `\o` SObject, `\r` standard query, and `\t` Tooling query.

Mappings are buffer-local and re-evaluated after entering, renaming, or changing the file/project. The registry removes only mappings it owns; a foreign buffer-local mapping is preserved and reported instead of overwritten.
