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
| Telescope | [telescope.md](./telescope.md) |
| Treesitter / indent / autopairs | [treesitter.md](./treesitter.md) |
| LSP / completion / formatting / lint | [lsp.md](./lsp.md) |
| Salesforce (sf.nvim) | [salesforce.md](./salesforce.md) |
| Comment / TODO / breadcrumbs | [comment.md](./comment.md) |
| QoL (sessions, Trouble, surround, flash, undotree) | [qol.md](./qol.md) |
| which-key | [which-key.md](./which-key.md) |
| UI cheat sheet | [below](#ui-notes) |

---

## Leaders

| Key | Meaning |
| --- | --- |
| `<Space>` (`mapleader`) | Global leader prefix for custom maps |
| `\` (`maplocalleader`) | Buffer-local leader (unused so far; reserved) |

Defined in `init.lua`.

---

## UI notes

| Area | How you use it today |
| --- | --- |
| Statusline (lualine) | Dark Bordo mode caps with clean spacing; branch, diff, smart path, diagnostics, LSP, location |
| Bufferline | Matching Bordo active-buffer treatment; cycle with `<S-h>` / `<S-l>` — [core.md](./core.md) |
| neo-tree | `<leader>fe` · `<leader>fE` · `<leader>ge` — [explorer.md](./explorer.md) |
| Lazygit | `<leader>gg` · `<leader>gf` — [git.md](./git.md) |
| Telescope | `<leader>sf` · `<leader>sg` · `<leader><leader>` — [telescope.md](./telescope.md) |
| Diagnostics | `]d`/`[d` · `<leader>e` · Trouble `<leader>xx` — [core.md](./core.md#diagnostics) · [qol.md](./qol.md) · [diagnostics/](../diagnostics/README.md) |
| Treesitter / indent / pairs | Highlight, folds, guides, autopairs — [treesitter.md](./treesitter.md) |
| LSP / format / blink | `gd`/`K`/`gr` · `<leader>cf` · `<C-y>` — [lsp.md](./lsp.md) |
| Lint (nvim-lint) | `<leader>cl` · `<leader>tl` toggle auto · lazy Mason — [lsp.md](./lsp.md#linting-luapluginslintinglua) |
| Salesforce | `<leader>S…` (capital S) · deploy `<leader>Sp` · cancel `<leader>Sx` — [salesforce.md](./salesforce.md) |
| Comment / TODO / crumbs | `gcc` · `]t`/`[t` · `<leader>st` · dropbar `<leader>;` — [comment.md](./comment.md) |
| QoL | sessions · Trouble · surround · flash · undotree · yanky · dial · rainbow · colorizer · space dots — [qol.md](./qol.md) |
| Colorscheme | `noctis_bordo` — `lua/plugins/colorscheme.lua` |
| which-key | `<Space>` then wait — [which-key.md](./which-key.md) |
| Plugin manager | `:Lazy` |

---

## Growing these docs

When you add keymaps in a later slice:

1. Put them in the matching file under `docs/keymaps/` (or add a new file and link it from this index).
2. Update the [UI notes](#ui-notes) row if it’s a new surface.
3. Uncomment matching `spec` groups in `lua/plugins/which-key.lua` when those prefixes exist.

---

Nav: [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [salesforce](./salesforce.md) · [comment](./comment.md) · [which-key](./which-key.md)
