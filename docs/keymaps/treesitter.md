# Treesitter, text objects, indentation, autopairs

Structural objects use operator-pending / Visual mappings rather than leader keys.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

| Piece | File | What you get |
| --- | --- | --- |
| Treesitter | `lua/plugins/treesitter.lua` | Syntax highlight, indentexpr, expr folds (`foldlevel` 99 = open). Parsers include Lua/web, **Java** (`java`, `xml`, `properties`, `groovy`), **Salesforce** (`apex`, `soql`, `sosl`, `sflog`), **rust** / **cpp**. Autotag closes/renames HTML/JSX tags. |
| Structural text objects | `lua/plugins/treesitter.lua` | Function, class, and parameter/call-argument objects from `nvim-treesitter-textobjects` `main`, including Apex and Java queries. |
| Indent detection | `lua/plugins/guess-indent.lua` | Samples opened files and sets buffer-local tab/space widths; `.editorconfig` wins, while `options.lua` remains the two-space fallback. |
| Indent guides | `lua/plugins/indent.lua` | In-code glyphs hidden; active scope colors line numbers; explicit `class_body` restores outer Java/JS/TS classes; Apex has a custom scope map. |
| Rainbow brackets | `lua/plugins/rainbow.lua` + `queries/apex/rainbow-delimiters.scm` | Depth-colored `()` / `[]` / `{}` including Apex; active gutter reuses the enclosing bracket’s exact color |
| Autopairs | `lua/plugins/autopairs.lua` | Auto-close brackets/quotes in insert; `check_ts` when Treesitter is on |

**Scope look:** lines in the current treesitter scope receive the enclosing bracket’s original depth color in the number gutter. No passive or active vertical/horizontal guides are drawn inside the code.

Host tools: Neovim **0.12+**, `tree-sitter` CLI, C compiler — [TOOLS.md](../TOOLS.md). After install: `:Lazy sync`, then `:checkhealth nvim-treesitter`.

Autopairs handles context-aware bracket/quote insertion, paired `<BS>`, pair-aware `<CR>`, and insert-mode `<M-e>` fast-wrap.

Folds: `za` toggle, `zo`/`zc` open/close — see `:help fold`.

## Structural text objects

| Object | Around | Inside |
| --- | --- | --- |
| Function / method / constructor | `af` | `if` |
| Class | `ac` | `ic` |
| Parameter or call argument | `aa` | `ia` |

Use these after an operator (`daf`, `cic`, `yaa`) or in Visual mode (`vaf`). Outer functions/classes select whole lines; inner bodies and arguments stay characterwise. Lookahead can select the next matching object when the cursor is just before it. Neovim 0.12’s built-in `an` / `in` incremental-selection mappings are untouched.

Manual indentation re-scan: `:GuessIndent`. Empty/new files and inconclusive samples retain the two-space defaults from `options.lua`.

LSP / format (separate): [lsp.md](./lsp.md).

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
