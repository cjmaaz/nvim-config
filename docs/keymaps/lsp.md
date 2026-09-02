# LSP, completion, formatting, linting

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [which-key](./which-key.md)

Related: diagnostics without a server — [core.md](./core.md#diagnostics). Full guide — [diagnostics/](../diagnostics/README.md). Host tools (JDK for Apex/Java, Mason) — [TOOLS.md](../TOOLS.md).

---

## LSP (`lua/plugins/lsp.lua`)

Buffer-local maps appear only after a language server attaches (`LspAttach`).

| Key | Mode | Action |
| --- | --- | --- |
| `K` | n | Hover documentation |
| `gd` | n | Go to definition |
| `gD` | n | Go to declaration |
| `gI` | n | Go to implementation |
| `gr` | n | References ([Telescope](./telescope.md)) |
| `<leader>D` | n | Type definition |
| `<leader>rn` | n | Rename symbol |
| `<leader>ca` | n, x | Code action |
| `<leader>ds` | n | Document symbols (Telescope) |
| `<leader>ws` | n | Workspace symbols (Telescope) |
| `<leader>th` | n | Toggle inlay hints (if server supports) |

**Inlay hints** are non-editing virtual text supplied by the attached LSP: inferred types, parameter names, return types, and similar context. `<leader>th` toggles them only for the current buffer and never changes the file. If nothing appears, that server/file has no enabled hints. This is separate from `ts_ls` semantic-token highlighting.

**Always on:** `lua_ls` (+ `stylua` via Mason).

**On demand:** first time you open a matching filetype, Mason installs the server then enables it — Python (`basedpyright`), JS/TS (`ts_ls`), HTML/CSS, Java (`jdtls`), Rust, C/C++ (`clangd`), JSON/YAML, **Apex** (`apex_ls` / `apex-language-server`). Needs **Java** on PATH for Apex. Optional: `$APEX_LS_JAR`.

`ts_ls` semantic tokens and same-symbol document highlights are disabled in `on_init`: TypeScript Server 6 can lose file synchronization in large LWC workspaces and repeatedly raise `getEncodedSemanticClassifications` / `getDocumentHighlights: Could not find source file`. Treesitter highlighting remains active, and other LSPs keep document highlights; `lsp.lua` retains a commented plain `ts_ls = {}` alternate if the upstream issue is fixed later.

UI: `:Mason`, fidget progress. Lua Neovim APIs: lazydev.

which-key: **Code** (`<leader>c`) / **Toggle** (`<leader>t`) — [which-key.md](./which-key.md).

---

## Completion (`lua/plugins/completion.lua`)

blink.cmp + LuaSnip. **Accept with `<C-y>`** (Kickstart / `:help ins-completion`). Tab/S-Tab/Enter accept is commented in the plugin file if you prefer CodeOSS-style.

Blink and LuaSnip load on the first `InsertEnter`. LSP clients receive the same locked Blink completion capabilities from `lsp.lua` beforehand, so deferring the UI/snippet modules does not remove server snippets or completion edits.

| Key (insert, menu open) | Action |
| --- | --- |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<C-y>` | Accept |
| `<C-e>` | Cancel |
| `<C-space>` | Open menu / docs |

For `.soql` buffers, Blink adds a custom **SOQL** source backed by the selected org’s project-local schema cache. It completes SObjects, fields, relationships, keywords, functions, and date literals without contacting the org while typing. Refresh/populate the cache through the [SOQL builder](./salesforce.md#soql-builder-completion-and-runner).

---

## Formatting (`lua/plugins/formatting.lua`)

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>cf` | n, x | Format buffer (conform; LSP fallback) |
| `<leader>tf` | n | Toggle format-on-save disable flag |

**Format-on-save is on** for an allowlist in `formatting.lua`: `lua`, `python`, JS/TS (+react), `html`/`css`/`scss`, `json`/`jsonc`, `yaml`. Toggle off with `<leader>tf`. Manual `<leader>cf` always works. `stylua` + `prettierd` auto-install via mason-tool-installer; other formatters (`ruff`, `google-java-format`, …) via `:Mason` as needed.

---

## Linting (`lua/plugins/linting.lua`)

External linters (ESLint, Ruff, …) → same diagnostic UI as LSP (`]d`, `<leader>e`).

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>cl` | n | Lint current buffer now |
| `<leader>tl` | n | Toggle **auto**-lint (BufEnter / save / InsertLeave) |

**Auto-lint is on** by default. If it’s noisy or slow: `<leader>tl`, or comment the autocmd in `linting.lua` and use `<leader>cl` only.

**Lazy Mason:** first time you open a matching filetype, Neovim installs the tool (`eslint_d`, `ruff`, `sqlfluff`, `shellcheck`, `stylelint`, `markdownlint`, …). Auto-lint **skips** a linter until its binary is on PATH (avoids ENOENT / neo-tree `BufEnter` errors while Mason installs). Manual: `:MasonInstall eslint_d`. If npm fails with `ETARGET` / “date before …”, check `~/.npmrc` `min-release-age` — see [diagnostics/quiet.md](../diagnostics/quiet.md#example-no-eslint-diagnostics--mason-eslint_d-failed). Disable a language by commenting its line in `linters_by_ft` (same style as statusline options).

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [which-key](./which-key.md)
