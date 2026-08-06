# LSP, completion, formatting

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [which-key](./which-key.md)

Related: diagnostics without a server — [core.md](./core.md#diagnostics). Host tools (JDK for Apex, Mason) — [TOOLS.md](../TOOLS.md).

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

**Always on:** `lua_ls` (+ `stylua` via Mason).

**On demand:** first time you open a matching filetype, Mason installs the server then enables it — Python (`basedpyright`), JS/TS (`ts_ls`), HTML/CSS, Java (`jdtls`), Rust, C/C++ (`clangd`), JSON/YAML, **Apex** (`apex_ls` / `apex-language-server`). Needs **Java** on PATH for Apex. Optional: `$APEX_LS_JAR`.

UI: `:Mason`, fidget progress. Lua Neovim APIs: lazydev.

which-key: **Code** (`<leader>c`) / **Toggle** (`<leader>t`) — [which-key.md](./which-key.md).

---

## Completion (`lua/plugins/completion.lua`)

blink.cmp + LuaSnip. **Accept with `<C-y>`** (Kickstart / `:help ins-completion`). Tab/S-Tab/Enter accept is commented in the plugin file if you prefer CodeOSS-style.

| Key (insert, menu open) | Action |
| --- | --- |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<C-y>` | Accept |
| `<C-e>` | Cancel |
| `<C-space>` | Open menu / docs |

---

## Formatting (`lua/plugins/formatting.lua`)

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>cf` | n, x | Format buffer (conform; LSP fallback) |
| `<leader>tf` | n | Toggle format-on-save disable flag |

**Format-on-save is off** until you uncomment filetypes in `formatting.lua` (`java`, `javascript`, `html`, `css`, …). Manual `<leader>cf` always works. Install formatters via `:Mason` (`prettierd`, `google-java-format`, …) as needed — only `stylua` is auto-installed.

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [which-key](./which-key.md)
