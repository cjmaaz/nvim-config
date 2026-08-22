# Git (gitsigns + lazygit)

Gitsigns: `lua/plugins/git.lua` → `on_attach` (buffer-local).  
Lazygit: `lua/plugins/lazygit.lua` (needs host `lazygit`).

Nav: [index](./README.md) · [core](./core.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

## Navigate hunks

| Key | Mode | Action |
| --- | --- | --- |
| `]c` | n | Next git hunk (in a `:diff` window, uses Vim’s builtin `]c`) |
| `[c` | n | Previous git hunk (same `:diff` caveat) |

Commented alternate in config: `]h` / `[h` if you want to leave `]c`/`[c` for diffs only.

---

## Hunk / buffer actions (`<leader>h…`)

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
| `<leader>tb` | n | Toggle **inline** current-line blame |

Commented alternates in config: `<leader>g…` prefix, inline preview (`hi`), diff vs `~` (`hD`), quickfix (`hq`/`hQ`), toggle word-diff (`tw`).

which-key group: **Git hunk** under `<leader>h` — [which-key.md](./which-key.md). Toggle group also lists `tb`.

Neo-tree keeps Git status badges in its filesystem view, but its separate Git source is disabled; use LazyGit for browsing changes.

---

## Lazygit (`lua/plugins/lazygit.lua`)

Needs host **`lazygit`** — [TOOLS.md](../TOOLS.md).

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>gg` | n | Open LazyGit (float) |
| `<leader>gf` | n | LazyGit filtered to the current file |

`:LazyGit` / `:LazyGitCurrentFile` also work. Hunk maps above stay for in-buffer work; LazyGit is the full TUI.

---

## Text object

| Key | Mode | Action |
| --- | --- | --- |
| `ih` | o, x | Select the hunk under the cursor (e.g. `vah`, `cih`) |

---

Nav: [index](./README.md) · [core](./core.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
