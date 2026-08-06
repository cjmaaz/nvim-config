# Treesitter, indent guides, autopairs

No custom leader maps. Behavior comes from plugins.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

| Piece | File | What you get |
| --- | --- | --- |
| Treesitter | `lua/plugins/treesitter.lua` | Syntax highlight, indentexpr, expr folds (`foldlevel` 99 = open). Parsers include Lua/web, **Java** (`java`, `xml`, `properties`, `groovy`), **Salesforce** (`apex`, `soql`, `sosl`, `sflog`), **rust** / **cpp**. Autotag closes/renames HTML/JSX tags. |
| Indent guides | `lua/plugins/indent.lua` | Vertical `│` guides + current scope (ibl) |
| Autopairs | `lua/plugins/autopairs.lua` | Auto-close brackets/quotes in insert; `check_ts` when Treesitter is on |

Host tools: Neovim **0.12+**, `tree-sitter` CLI, C compiler — [TOOLS.md](../TOOLS.md). After install: `:Lazy sync`, then `:checkhealth nvim-treesitter`.

Folds: `za` toggle, `zo`/`zc` open/close — see `:help fold`.

LSP / format (separate): [lsp.md](./lsp.md).

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
