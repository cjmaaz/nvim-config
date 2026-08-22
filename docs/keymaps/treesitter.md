# Treesitter, indent guides, autopairs

No custom leader maps. Behavior comes from plugins.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

| Piece | File | What you get |
| --- | --- | --- |
| Treesitter | `lua/plugins/treesitter.lua` | Syntax highlight, indentexpr, expr folds (`foldlevel` 99 = open). Parsers include Lua/web, **Java** (`java`, `xml`, `properties`, `groovy`), **Salesforce** (`apex`, `soql`, `sosl`, `sflog`), **rust** / **cpp**. Autotag closes/renames HTML/JSX tags. |
| Indent guides | `lua/plugins/indent.lua` | Dim passive + non-bold scope both use hairline `│` (`▏` remains the previous alternate); no horizontal caps; Apex via `scope.include.node_type.apex`. Palette: `lua/config/rainbow_palette.lua`. |
| Rainbow brackets | `lua/plugins/rainbow.lua` | Depth-colored `()` / `[]` / `{}` (shared palette with indent scope) |
| Autopairs | `lua/plugins/autopairs.lua` | Auto-close brackets/quotes in insert; `check_ts` when Treesitter is on |

**Scope look:** under the cursor’s block you get a single brighter, depth-colored hairline with no top/bottom underlines. Restore the commented caps or switch to a single `IblScope` color in `indent.lua`.

Host tools: Neovim **0.12+**, `tree-sitter` CLI, C compiler — [TOOLS.md](../TOOLS.md). After install: `:Lazy sync`, then `:checkhealth nvim-treesitter`.

Folds: `za` toggle, `zo`/`zc` open/close — see `:help fold`.

LSP / format (separate): [lsp.md](./lsp.md).

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
