# Diagnostic display — where and what settings

Nav: [index](./README.md) · [quiet](./quiet.md) · [java](./java.md) · [example](../examples/java-maven-minimal/)

Edit these in `vim.diagnostic.config({ ... })` inside `lua/config/keymaps.lua`.  
Session tryout: `:lua vim.diagnostic.config({ virtual_text = false })`.

Appearance (colors, icon glyphs) comes from your **theme** + Nerd Font / ASCII fallbacks — do not rely on a specific color name.

---

## Map: where each channel shows up

```text
┌─ gutter (signcolumn) ─┐  ┌─ buffer text ──────────────────────────┐
│  sign icon            │  │  code here……… virtual_text (eol)        │
│  (E/W/I/H or glyph)   │  │  ~~~~~~~~~~ underline on the span       │
│                       │  │  (optional) virtual_lines below the line │
└───────────────────────┘  └─────────────────────────────────────────┘
         │
         ├─ float popup ……… <leader>e or after ]d / [d
         ├─ Trouble panel …… <leader>xx (workspace) / xX (buffer) / xl (loclist)
         ├─ Telescope ……… <leader>sd
         └─ statusline ……… lualine diagnostics counts
```

| Channel | UI location | Typical content | Our default |
| --- | --- | --- | --- |
| **signs** | Sign column (left of line numbers) | Severity icon / letter | On |
| **underline** | Under the diagnostic span in the buffer | Theme underline / undercurl | WARN and above |
| **virtual_text** | End of the **same** line as the issue | Short message (+ optional source/prefix) | `true` (all severities that exist) |
| **virtual_lines** | Extra screen line(s) **under** the code | Full-ish message | Off (commented alt) |
| **float** | Floating window | Message, source, code, related info | On jump + `<leader>e` |
| **Trouble** | Sticky side/bottom panel | Filterable diagnostics / lists | Via `<leader>xx` — [qol.md](../keymaps/qol.md) |
| **Telescope** | Picker UI | Searchable list (often workspace/buffer) | Via `<leader>sd` |
| **statusline** | lualine (usually right side) | Counts by severity | On |

You can enable several channels at once (e.g. signs + virtual text + float).

---

## Settings reference (`vim.diagnostic.config`)

Values below are the ones we care about day to day. Full API: `:help vim.diagnostic.Opts`.

### Global / timing

| Option | Meaning | Useful values |
| --- | --- | --- |
| `update_in_insert` | Refresh while typing in insert | `false` (default here) · `true` (noisier) |
| `severity_sort` | Sort lists/floats by severity | `true` · `false` |
| `severity` | Minimum severity to **show at all** | `{ min = vim.diagnostic.severity.WARN }` · `ERROR` · omit = all |

Severity enum: `ERROR` · `WARN` · `INFO` · `HINT` (see [quiet.md](./quiet.md)).

### `virtual_text`

| Value | Effect |
| --- | --- |
| `false` | No end-of-line messages |
| `true` | Show for diagnostics that pass other filters |
| `{ severity = { min = … } }` | Only that severity and up, as virtual text |
| `{ prefix = "●", source = "if_many", spacing = 2 }` | Tweak look (prefix, when to show source, spacing) |

### `virtual_lines`

| Value | Effect |
| --- | --- |
| `false` / omit | Off |
| `true` | Show under-line virtual lines |
| `{ severity = { min = … } }` | Restrict which severities use virtual lines |

Often used **instead of** virtual text (`virtual_text = false`, `virtual_lines = true`).

### `underline`

| Value | Effect |
| --- | --- |
| `false` | No underlines |
| `true` | Underline every severity |
| `{ severity = { min = … } }` | e.g. only WARN+ (our default) |

### `signs`

| Value | Effect |
| --- | --- |
| `false` | No gutter signs |
| `true` / table | Show signs; `text = { [severity.ERROR] = "…", … }` sets glyphs |

### `float`

Passed through to open-float (and our jump `on_jump` helper):

| Field | Meaning | Examples |
| --- | --- | --- |
| `border` | Float border style | `"rounded"` · `"single"` · `"none"` |
| `source` | Show diagnostic source | `true` · `false` · `"if_many"` |
| `header` / `prefix` | Float chrome | see `:help vim.diagnostic.Opts.Float` |
| `severity` | Filter float contents | `{ min = ERROR }` |

### `jump`

| Field | Meaning |
| --- | --- |
| `on_jump` | Callback after `vim.diagnostic.jump` (we open a float) |

Prefer `on_jump` over deprecated `float = true` on jump opts.

---

## Example layouts (copy into `keymaps.lua`)

**A. Current style — end-of-line text + signs**

```lua
virtual_text = true,
underline = { severity = { min = vim.diagnostic.severity.WARN } },
-- virtual_lines = false,
```

**B. Quiet buffer — signs + float only**

```lua
virtual_text = false,
virtual_lines = false,
underline = { severity = { min = vim.diagnostic.severity.WARN } },
```

**C. Virtual lines instead of eol text**

```lua
virtual_text = false,
virtual_lines = true,
```

**D. Virtual text for errors only** (warnings still in signs/float unless you also set global `severity`)

```lua
virtual_text = {
  severity = { min = vim.diagnostic.severity.ERROR },
},
```

**E. Hide everything below ERROR**

```lua
severity = { min = vim.diagnostic.severity.ERROR },
```

---

## Related UI outside `vim.diagnostic.config`

| Feature | Where configured |
| --- | --- |
| Statusline counts | `lua/plugins/statusline.lua` → `"diagnostics"` |
| Bufferline LSP badges | `lua/plugins/bufferline.lua` → `diagnostics` (off until you enable) |
| neo-tree diagnostic marks | `lua/plugins/explorer.lua` → `enable_diagnostics` |
| Lint vs LSP sources | [quiet.md](./quiet.md) · [keymaps/lsp.md](../keymaps/lsp.md) |

Nav: [index](./README.md) · [quiet](./quiet.md) · [java](./java.md) · [example](../examples/java-maven-minimal/)
