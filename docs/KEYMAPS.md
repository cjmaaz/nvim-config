# Keymaps

Custom shortcuts defined by this config. `<leader>` is **Space** (see `init.lua`).

Only maps we actually set are listed here. Built-in Vim/Neovim keys (`hjkl`, `:w`, `gt` / `gT`, …) are omitted unless we remapped them.

`vim.keymap.set(mode, lhs, rhs, opts?)` — **mode** = when; **lhs** = keys you press; **rhs** = action; **opts** = usually `{ desc = "…" }`.

---

## Leaders

| Key | Meaning |
| --- | --- |
| `<Space>` (`mapleader`) | Global leader prefix for custom maps |
| `\` (`maplocalleader`) | Buffer-local leader (unused so far; reserved) |

Defined in `init.lua`.

---

## Buffers & windows

Defined in `lua/config/keymaps.lua`. **Buffers ≠ tabpages** — `gt` / `gT` stay as real Vim tab keys.

### Buffers

| Key | Mode | Action |
| --- | --- | --- |
| `<S-h>` | n | Previous buffer (`:bprevious`) |
| `<S-l>` | n | Next buffer (`:bnext`) |
| `<leader>bd` | n | Delete current buffer (`:bdelete`) |

Commented alternates in config: `]b`/`[b`, force delete (`bdelete!`), `<leader>c`, wipeout.

### Windows (splits)

| Key | Mode | Action |
| --- | --- | --- |
| `<C-h>` | n | Focus left window |
| `<C-l>` | n | Focus right window |
| `<C-j>` | n | Focus lower window |
| `<C-k>` | n | Focus upper window |

### Search

| Key | Mode | Action |
| --- | --- | --- |
| `<Esc>` | n | Clear search highlight (`:nohlsearch`) |

---

## Git (gitsigns)

Defined in `lua/plugins/git.lua` → `on_attach` (buffer-local; only in files gitsigns attaches to).

### Navigate hunks

| Key | Mode | Action |
| --- | --- | --- |
| `]c` | n | Next git hunk (in a `:diff` window, uses Vim’s builtin `]c`) |
| `[c` | n | Previous git hunk (same `:diff` caveat) |

Commented alternate in config: `]h` / `[h` if you want to leave `]c`/`[c` for diffs only.

### Hunk / buffer actions (`<leader>h…`)

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>hs` | n | Stage hunk |
| `<leader>hr` | n | Reset hunk (discard hunk changes in the working tree) |
| `<leader>hs` | v | Stage selected lines |
| `<leader>hr` | v | Reset selected lines |
| `<leader>hS` | n | Stage entire buffer |
| `<leader>hR` | n | Reset entire buffer |
| `<leader>hp` | n | Preview hunk (float) |
| `<leader>hb` | n | Blame line (full) |
| `<leader>hd` | n | Diff this file against the index |

Commented alternates in config: `<leader>g…` prefix, inline preview (`hi`), diff vs `~` (`hD`), quickfix (`hq`/`hQ`), toggle blame/word-diff (`tb`/`tw`).

### Text object

| Key | Mode | Action |
| --- | --- | --- |
| `ih` | o, x | Select the hunk under the cursor (e.g. `vah`, `cih`) |

---

## UI notes (no custom keys yet)

| Area | How you use it today |
| --- | --- |
| Statusline (lualine) | Always visible — mode, branch, diff, filename, diagnostics, location |
| Colorscheme | Set at startup (`noctis_bordo`); change in `lua/plugins/colorscheme.lua` |
| Plugin manager | `:Lazy` — UI for install/update/profile |

---

## Growing this doc

When you add keymaps in a later slice (bufferline, which-key, telescope, LSP), append a section here in the same table style and link the defining file.
