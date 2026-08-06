# Comment / TODO / breadcrumbs

Polish: toggle comments, highlight TODO-style notes, LSP path in the statusline.

| Plugin | File |
| --- | --- |
| Comment.nvim (+ context-commentstring) | `lua/plugins/comment.lua` |
| todo-comments.nvim | `lua/plugins/todo-comments.lua` |
| nvim-navic (breadcrumbs) | `lua/plugins/breadcrumbs.lua` + lualine in `statusline.lua` |

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

## Breadcrumbs (nvim-navic)

Shows the LSP symbol path (e.g. `Class › method`) in **lualine** after the filename when a server supports `documentSymbol`.

No extra keys — move with normal LSP/`gd`. Empty until an LSP attaches. Heavier clickable winbar alternative: `dropbar.nvim` (not wired).

---

Nav: [index](./README.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
