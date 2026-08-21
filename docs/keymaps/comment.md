# Comment / TODO / breadcrumbs

Polish: toggle comments, highlight TODO-style notes, and navigate a clickable winbar.

| Plugin | File |
| --- | --- |
| Comment.nvim (+ context-commentstring) | `lua/plugins/comment.lua` |
| todo-comments.nvim | `lua/plugins/todo-comments.lua` |
| dropbar.nvim (breadcrumbs) | `lua/plugins/breadcrumbs.lua` |

Nav: [index](./README.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

## Comment.nvim

Defaults (no custom leader maps):

| Key | Mode | Action |
| --- | --- | --- |
| `gcc` | n | Toggle **line** comment |
| `gc{motion}` | n | Comment motion (e.g. `gcip` inner paragraph) |
| `gbc` | n | Toggle **block** comment |
| `gb{motion}` | n | Block-comment motion |
| `gc` / `gb` | v | Comment visual selection (line / block) |

Uses Treesitter **context-commentstring** so JSX/TSX/HTML injections get the right `//` vs `{/* */}`.

---

## todo-comments

Highlights `TODO`, `FIXME`, `HACK`, `NOTE`, … in the buffer and gutter.

| Key | Mode | Action |
| --- | --- | --- |
| `]t` | n | Next TODO-style comment |
| `[t` | n | Previous TODO-style comment |
| `<leader>st` | n | Search TODOs via **TodoTelescope** (Search group) |

Also: `:TodoQuickFix` · `:TodoLocList` · `:TodoTelescope`.

---

## Breadcrumbs (dropbar.nvim)

Shows the file path and current symbol chain (e.g. `Class › method`) in the **winbar**. Symbols come from LSP, Treesitter, or Markdown; path navigation works without an LSP.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>;` | n | Enter pick mode, then press the displayed key for a winbar component |
| `[;` | n | Go to the start of the current symbol context |
| `];` | n | Select the next symbol context |

Click a winbar component to open its sibling menu; click an entry to jump. In a menu, `i` starts fuzzy filtering, `<CR>` selects, and `q` / `<Esc>` closes it. Hover previews are enabled, and menu chrome follows the shared Rosé Pine panel palette.

---

Nav: [index](./README.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
