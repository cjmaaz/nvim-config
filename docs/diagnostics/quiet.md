# Quieting and controlling diagnostics

Nav: [index](./README.md) · [display](./display.md) · [java](./java.md) · [example](../examples/java-maven-minimal/)

Diagnostics are **recomputed** by the language server or linter. There is usually no permanent “dismiss this squiggle” unless you change code, tool config, or Neovim filters.

---

## Severity levels

| Level | Typical meaning |
| --- | --- |
| `ERROR` | Broken / won’t compile / definite failure |
| `WARN` | Suspicious or degraded mode (e.g. Java running without a project root) |
| `INFO` | Informational |
| `HINT` | Style / suggestion |

In Lua: `vim.diagnostic.severity.ERROR` (and `WARN`, `INFO`, `HINT`).

Use severity on **global** `severity`, or per channel (`virtual_text`, `underline`, `signs`, `float`) — see [display.md](./display.md).

---

## Identify the source

Open the float (`<leader>e` or after `]d`). Note the **source** field when present, for example:

- `jdtls` — Java LSP
- `lua_ls` — Lua LSP
- `eslint_d` / `ruff` / `sqlfluff` — `nvim-lint`

That tells you whether to fix the **project**, the **linter/LSP settings**, or only the **UI**.

---

## Ways to quiet noise

| Goal | Approach |
| --- | --- |
| Hide UI for a moment | `:lua vim.diagnostic.hide()` · show again: `vim.diagnostic.show()` |
| Turn off one channel | e.g. `virtual_text = false` in [display.md](./display.md) |
| Show fewer severities | `severity = { min = … }` or per-channel `severity` |
| Stop auto-lint | `<leader>tl` or comment a filetype in `lua/plugins/linting.lua` |
| Stop a language server | `:LspStop` · or adjust on-demand list in `lua/plugins/lsp.lua` |
| Fix root cause | Project layout (e.g. [java.md](./java.md)), dependencies, code |
| Suppress in **source** | Language/tool specific (below) |
| Filter one message in Neovim | Custom handler / namespace (not wired in this config yet) |

### Per-buffer / session

| Scope | Example |
| --- | --- |
| Global (config file) | Change `vim.diagnostic.config` in `keymaps.lua` |
| This Neovim session | `:lua vim.diagnostic.config({ virtual_text = false })` |
| Lint this buffer | `:lua vim.b.disable_autolint = true` |
| Format this buffer | `vim.b.disable_autoformat` (conform) |

---

## Suppress in the tool / language (examples)

These are **not** Neovim-specific; they travel with the repo. Prefer fixing the project or shared config over scattering one-off comments.

| Ecosystem | In-source suppress (examples) | Project / tool config | Notes |
| --- | --- | --- | --- |
| **Java (`jdtls`)** | `@SuppressWarnings("unchecked")` · `@SuppressWarnings({"deprecation","unchecked"})` | Fix project root (`pom.xml` / Gradle) so “non-project” goes away · IDE/compiler `-Xlint` | “Non-project file” is fixed by layout, not `@SuppressWarnings` — see [java.md](./java.md) |
| **JavaScript / TypeScript (ESLint)** | `// eslint-disable-next-line no-unused-vars` · `/* eslint-disable … */` … `/* eslint-enable */` · `// eslint-disable-line` | `.eslintrc.*` · `eslint.config.js` · `package.json` `eslintConfig` · overrides per `files` | Our lint uses `eslint_d` when present |
| **TypeScript (compiler)** | `// @ts-ignore` · `// @ts-expect-error` · `// @ts-nocheck` (file) | `tsconfig.json` `compilerOptions` · skipLibCheck, strict flags | LSP (`ts_ls`) vs ESLint are different sources — check the float |
| **Vue** | Same ESLint / TS patterns in `<script>` | `eslint` + `vue-eslint-parser` · `tsconfig` / `vitest` as needed | Often same `eslint_d` pipeline as JS/TS |
| **Python (Ruff)** | `# noqa` · `# noqa: F401` · `# ruff: noqa: …` (file) | `ruff.toml` · `[tool.ruff]` in `pyproject.toml` · `extend-per-file-ignores` | Ruff lint ≠ `ruff_format` (conform) |
| **Python (other)** | `# type: ignore` · `# type: ignore[attr-defined]` (mypy/pyright) | `pyrightconfig.json` · `mypy.ini` · `pyproject.toml` | basedpyright/pyright diagnostics are LSP, not Ruff |
| **Lua (LuaLS / LSP)** | `---@diagnostic disable: undefined-global` · `---@diagnostic disable-next-line: …` | `.luarc.json` / `.luarc.jsonc` · workspace library | Common for Neovim `vim` global (we also set `diagnostics.globals` in `lsp.lua`) |
| **Lua (Selene)** | `-- selene: allow(…)` | `selene.toml` | Only if you enable `selene` in `linting.lua` |
| **Lua (Luacheck)** | `-- luacheck: ignore` · `-- luacheck: globals vim` | `.luacheckrc` | Only if you enable `luacheck` |
| **CSS / SCSS (Stylelint)** | `/* stylelint-disable-next-line … */` · `/* stylelint-disable … */` | `.stylelintrc.*` · `stylelint.config.js` | Our lint maps `css` / `scss` → `stylelint` |
| **Shell (ShellCheck)** | `# shellcheck disable=SC2086` · `# shellcheck source=…` | `.shellcheckrc` · `disable=` directives | Mapped for `sh` / `bash` in `linting.lua` |
| **SQL (SQLFluff)** | `-- noqa: …` · `-- noqa` | `.sqlfluff` · `pyproject.toml` `[tool.sqlfluff]` · dialect | We default dialect `postgres` in lint config — override in project |
| **Markdown (markdownlint)** | `<!-- markdownlint-disable MD013 -->` · `<!-- markdownlint-disable-next-line -->` | `.markdownlint.json` / `.markdownlint.yaml` · `markdownlint-cli2` config | Easy to over-disable; prefer line-length rules in config |
| **Rust (`rustc` / rust-analyzer)** | `#[allow(dead_code)]` · `#[allow(clippy::…)]` · `#[expect(…)]` (edition dependent) | `Cargo.toml` · `clippy.toml` · workspace lints | Clippy vs rustc are different lint sets |
| **C / C++ (`clangd`)** | `// NOLINTNEXTLINE` · `// NOLINT` · `NOLINT(…)` | `.clang-tidy` · `.clangd` · compile_commands.json | Often need a compilation database for full IQ |
| **JSON / YAML** | Rarely in-file; fix schema or data | SchemaStore / `yaml.schemas` · `.yamllint` if enabled | `yamllint` is commented optional in `linting.lua` |
| **Dockerfile (Hadolint)** | `# hadolint ignore=DLxxxx` | `.hadolint.yaml` | Optional — uncomment `dockerfile` in `linting.lua` |
| **Apex / Salesforce** | Limited in-source suppress vs platform rules | Project `sfdx-project.json` · org/pmd/eslint packs · Apex PMD rulesets | `apex_ls` is LSP; CLI/static analysis may be separate (e.g. later `sf.nvim`) |
| **Prettier / formatters** | N/A (format, not diagnostics) | `.prettierrc` · `prettierignore` · conform `formatters_by_ft` | Wrong tool for “suppress error” — use `<leader>cf` / FoS allowlist instead |

**How to use the table:** read the diagnostic **source** in the float, then pick the matching row. If the source is an LSP (`jdtls`, `ts_ls`, `lua_ls`, …), in-source comments and that server’s config apply; if the source is a linter (`eslint_d`, `ruff`, …), use that linter’s disable syntax.

Prefer fixing the project or config over scattering suppress comments.

---

## Example: no ESLint diagnostics / Mason `eslint_d` failed

JS/TS/Vue lint in this config comes from **`eslint_d`** via `nvim-lint` (source in the float: `eslint_d`). If nothing appears, or neo-tree briefly errored with `ENOENT`, the binary is usually missing or still installing.

### 1. Install with Mason

```vim
:MasonInstall eslint_d
```

Or open `:Mason`, find `eslint_d`, install. First open of a matching filetype also **lazy-installs** it (you may see “Installing eslint_d…”). Auto-lint skips until the cmd is on PATH.

Check: `:echo executable('eslint_d')` → `1`, or `~/.local/share/nvim/mason/bin/eslint_d`.

### 2. If install fails with `ETARGET` / “date before …”

Mason uses **npm**. A host `~/.npmrc` with supply-chain delay can block a brand-new Mason pin:

```ini
min-release-age=7
```

That refuses packages newer than N days. Example: Mason wants `eslint_d@15.0.3` published yesterday → npm error `notarget … with a date before …`.

**Fix (keep the policy, allow this tool):**

```ini
# ~/.npmrc
min-release-age=7
min-release-age-exclude[]=eslint_d
```

Then `:MasonInstall eslint_d` again.

**Alts:** wait until the package is old enough · temporarily `npm config delete min-release-age` · install · restore.

Also, if npm says the cache is root-owned:

```bash
sudo chown -R "$(id -u):$(id -g)" ~/.npm
```

### 3. After install

Re-open the buffer or `<leader>cl`. You still need a project ESLint config (`eslint.config.*` / `.eslintrc.*`) for useful rules — missing config ≠ Mason failure.

---

## Checklist

1. Source? → float `<leader>e`
2. UI too busy? → [display.md](./display.md) layouts B–E
3. Java “non-project”? → [java.md](./java.md) + [example](../examples/java-maven-minimal/)
4. Nothing at all? → `:LspInfo` · `:Mason` · is the buffer modifiable? · did lint run (`<leader>cl`)? · for ESLint: [Mason / npmrc above](#example-no-eslint-diagnostics--mason-eslint_d-failed)

Nav: [index](./README.md) · [display](./display.md) · [java](./java.md) · [example](../examples/java-maven-minimal/)
