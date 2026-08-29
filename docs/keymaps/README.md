# Keymaps

Custom shortcuts defined by this config. `<leader>` is **Space** (see `init.lua`).

Only maps we actually set are listed. Built-in Vim/Neovim keys (`hjkl`, `:w`, `gt` / `gT`, …) are omitted unless we remapped them.

`vim.keymap.set(mode, lhs, rhs, opts?)` — **mode** = when (`n` normal, `i` insert, `v` visual, `t` terminal, …); **lhs** = keys you press; **rhs** = action; **opts** = usually `{ desc = "…" }`.

**Also:** [TOOLS.md](../TOOLS.md) · [diagnostics/](../diagnostics/README.md) · [COMMITIZEN.md](../COMMITIZEN.md) · [repo README](../../README.md)

---

## Index

| Topic | File |
| --- | --- |
| Leaders | [below](#leaders) |
| Buffers, windows, motion, diagnostics | [core.md](./core.md) |
| Git (gitsigns) | [git.md](./git.md) |
| Explorer (neo-tree) | [explorer.md](./explorer.md) |
| Project scaffolding and tasks | [project.md](./project.md) |
| Markdown rendering | [markdown.md](./markdown.md) |
| Telescope | [telescope.md](./telescope.md) |
| Treesitter / indent / autopairs | [treesitter.md](./treesitter.md) |
| LSP / completion / formatting / lint | [lsp.md](./lsp.md) |
| Salesforce (sf.nvim) | [salesforce.md](./salesforce.md) |
| Comment / TODO / window context | [comment.md](./comment.md) |
| QoL (sessions, Trouble, surround, flash, undotree) | [qol.md](./qol.md) |
| which-key | [which-key.md](./which-key.md) |
| UI cheat sheet | [below](#ui-notes) |

---

## Leaders

| Key | Meaning |
| --- | --- |
| `<Space>` (`mapleader`) | Global leader prefix for custom maps |
| `\` (`maplocalleader`) | Buffer-local leader (SOQL drafts use `\f` / `\o` / `\r` / `\t`) |

Defined in `init.lua`.

---

## UI notes

| Area | How you use it today |
| --- | --- |
| Statusline (lualine) | 40%-lightened palette, darker Visual mode, SF/LSP/language/encoding info |
| Bufferline | Filetype icon + filename only; dirty state moved to footer — [core.md](./core.md) |
| neo-tree | Filesystem only: `<leader>fe` · `<leader>fE` — [explorer.md](./explorer.md) |
| Project workflows | `<leader>pn` scaffold · `<leader>pr` run/build/test — [project.md](./project.md) |
| Markdown | `<leader>mr` inline render · `<leader>mp` side preview — [markdown.md](./markdown.md) |
| Lazygit | `<leader>gg` · `<leader>gf` — [git.md](./git.md) |
| Telescope | Rounded prompt/results/preview grid with icons; `<leader>sf` · `<leader>sg` · `<leader><leader>` — [telescope.md](./telescope.md) |
| Floating windows | Retained rounded charcoal/pastel frame; plugin-specific windows may override it |
| Diagnostics | `]d`/`[d` · `<leader>e` · `<leader>td` inline toggle · Trouble `<leader>xx` — [core.md](./core.md#diagnostics) · [qol.md](./qol.md) · [diagnostics/](../diagnostics/README.md) |
| Treesitter / indent / pairs | Highlight, folds, guides, autopairs — [treesitter.md](./treesitter.md) |
| LSP / format / blink | `gd`/`K`/`gr` · `<leader>cf` · `<C-y>` — [lsp.md](./lsp.md) |
| Lint (nvim-lint) | `<leader>cl` · `<leader>tl` toggle auto · lazy Mason — [lsp.md](./lsp.md#linting-luapluginslintinglua) |
| Salesforce | `<leader>S…` · Vlocity `SV` · SOQL `SQ`/`Sq` · metadata `Su` · cancel `Sx` — [salesforce.md](./salesforce.md) |
| Comment / TODO / context | `gcc` · `]t`/`[t` · `<leader>st`; native context winbar retained but disabled — [comment.md](./comment.md) |
| QoL | Gremlins · sessions · Trouble · surround · flash · undotree · yanky · dial · rainbow · colorizer — [qol.md](./qol.md) |
| Colorscheme | Noctis Bordo on `#18181B`; italic comments/keywords/types/properties and bold control flow/parameters |
| which-key | `<Space>` then wait — [which-key.md](./which-key.md) |
| Plugin manager | `:Lazy` |

The previous footer looked rectangular because both lualine separator sets were explicitly empty. The current `` / `` Nerd Font Powerline glyphs draw curved transitions by using each neighboring section’s foreground/background colors.

---

## Growing these docs

When you add keymaps in a later slice:

1. Put them in the matching file under `docs/keymaps/` (or add a new file and link it from this index).
2. Update the [UI notes](#ui-notes) row if it’s a new surface.
3. Uncomment matching `spec` groups in `lua/plugins/which-key.lua` when those prefixes exist.

---

Nav: [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [project](./project.md) · [markdown](./markdown.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [salesforce](./salesforce.md) · [comment](./comment.md) · [which-key](./which-key.md)
