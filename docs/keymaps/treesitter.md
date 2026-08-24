# Treesitter, indent guides, autopairs

No custom leader maps. Behavior comes from plugins.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

| Piece | File | What you get |
| --- | --- | --- |
| Treesitter | `lua/plugins/treesitter.lua` | Syntax highlight, indentexpr, expr folds (`foldlevel` 99 = open). Parsers include Lua/web, **Java** (`java`, `xml`, `properties`, `groovy`), **Salesforce** (`apex`, `soql`, `sosl`, `sflog`), **rust** / **cpp**. Autotag closes/renames HTML/JSX tags. |
| Indent guides | `lua/plugins/indent.lua` | Passive/active in-code glyphs hidden; active scope uses a muted line-number gutter; Apex via `scope.include.node_type.apex`. |
| Rainbow brackets | `lua/plugins/rainbow.lua` | Depth-colored `()` / `[]` / `{}`; active gutter derives its tint from the enclosing bracket |
| Autopairs | `lua/plugins/autopairs.lua` | Auto-close brackets/quotes in insert; `check_ts` when Treesitter is on |

**Scope look:** lines in the current treesitter scope receive a muted, bracket-depth-matched line-number color. No passive or active vertical/horizontal guides are drawn inside the code.

Host tools: Neovim **0.12+**, `tree-sitter` CLI, C compiler — [TOOLS.md](../TOOLS.md). After install: `:Lazy sync`, then `:checkhealth nvim-treesitter`.

Folds: `za` toggle, `zo`/`zc` open/close — see `:help fold`.

LSP / format (separate): [lsp.md](./lsp.md).

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
