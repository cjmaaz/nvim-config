# Core keymaps

Buffers, windows, motion, terminal, diagnostics.

Defined mainly in `lua/config/keymaps.lua`. **Buffers ≠ tabpages** — `gt` / `gT` stay as real Vim tab keys.

Nav: [index](./README.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

## Buffers

| Key | Mode | Action |
| --- | --- | --- |
| `<S-h>` | n | Previous buffer (`:bprevious`) |
| `<S-l>` | n | Next buffer (`:bnext`) |
| `<leader>bd` | n | Delete current buffer (`:bdelete`) |

Commented alternates in config: `]b`/`[b`, force delete (`bdelete!`), `<leader>c`, wipeout.

### Bufferline (UI)

Defined in `lua/plugins/bufferline.lua`. Visual bar of **buffers** (`mode = "buffers"`). Cycle still uses `<S-h>` / `<S-l>` above — not `gt` / `gT` (those remain tabpages). Close with `<leader>bd` (close icons are off).

Optional later: enable `diagnostics = "nvim_lsp"` after LSP; Craftzdog-style `mode = "tabs"` is intentionally not used.

---

## Windows (splits)

| Key | Mode | Action |
| --- | --- | --- |
| `<C-h>` | n | Focus left window |
| `<C-l>` | n | Focus right window |
| `<C-j>` | n | Focus lower window |
| `<C-k>` | n | Focus upper window |

---

## Search highlight

| Key | Mode | Action |
| --- | --- | --- |
| `<Esc>` | n | Clear search highlight (`:nohlsearch`) |

Project search lives in [telescope.md](./telescope.md) (`<leader>sg`, …).

---

## Motion comfort

| Key | Mode | Action |
| --- | --- | --- |
| `n` | n | Next search match, then center (`nzzzv`) |
| `N` | n | Previous search match, then center |
| `<C-d>` | n | Half page down, then center |
| `<C-u>` | n | Half page up, then center |

---

## Visual line move

| Key | Mode | Action |
| --- | --- | --- |
| `J` | v | Move selection down (overrides visual join) |
| `K` | v | Move selection up (overrides visual keyword lookup) |

---

## Terminal

Interactive shell buffer (not `:!`):

| Command / key | Action |
| --- | --- |
| `:terminal` | Open a terminal in the current window |
| `:split \| terminal` / `:vsplit \| terminal` | Terminal in a split |
| `<Esc><Esc>` | **t** — leave terminal-job mode → normal mode in that buffer (`<C-\><C-n>`) |

`:!cmd` only runs a one-shot shell command and returns; it does **not** enter terminal mode.

---

## hjkl training

| Key | Mode | Action |
| --- | --- | --- |
| `<left>` / `<right>` / `<up>` / `<down>` | n | Echo “Use h/l/k/j to move!” (no cursor move) |

---

## Diagnostics

Defined in `lua/config/keymaps.lua` (`vim.diagnostic.config` + maps). Works before LSP; maps are no-ops until a server or linter reports issues. Jump opens a float via `jump.on_jump` (not the deprecated `float = true` jump opt).

| Key | Mode | Action |
| --- | --- | --- |
| `]d` | n | Next diagnostic (float on jump) |
| `[d` | n | Previous diagnostic (float on jump) |
| `<leader>e` | n | Show diagnostic float at cursor |

**Lists:** use [Trouble](./qol.md#trouble-luapluginstroublelua) (`<leader>xx` / `xX` / `xl`) instead of the old `<leader>q` loclist. `<leader>q…` is now [sessions](./qol.md#sessions-luapluginspersistencelua).

Display: virtual text on, underline from WARN+, severity-sorted, Nerd Font / ASCII signs. Commented alts in config: `virtual_lines`, full underline.

**Deeper guide** (display settings, quieting noise, Java non-project): [diagnostics/](../diagnostics/README.md).

Also: Telescope [`<leader>sd`](./telescope.md) searches diagnostics once they exist. LSP attach maps: [lsp.md](./lsp.md).

---

Nav: [index](./README.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [qol](./qol.md) · [which-key](./which-key.md)
