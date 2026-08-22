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
| `]b` / `[b` | n | Next / previous buffer |
| `]B` / `[B` | n | Last / first buffer |
| `]a` / `[a` | n | Next / previous argument (`:next` / `:previous`) |
| `]A` / `[A` | n | Last / first argument |
| `<leader>bd` | n | Delete current buffer (`:bdelete`) |

Commented alternates in config: force delete (`bdelete!`), `<leader>c` as buffer-delete, wipeout.

### Bufferline (UI)

Defined in `lua/plugins/bufferline.lua`. Visual bar of **buffers** (`mode = "buffers"`). Entries show only the filetype icon and filename; the modified/dirty marker moved to lualine. Cycle still uses `<S-h>` / `<S-l>` above — not `gt` / `gT` (those remain tabpages). Close with `<leader>bd` (close icons are off).

Optional later: enable `diagnostics = "nvim_lsp"` after LSP; Craftzdog-style `mode = "tabs"` is intentionally not used.

### Statusline (UI)

`lua/plugins/statusline.lua` keeps this exact left-to-right order: mode bubble (Vim or terminal icon), workspace bubble, Git-branch bubble, dirty flag, left-truncated relative file path plus nvim-navic method/property context, plain error/warning counts, a shared `line:column` + progress bubble, then one right bubble containing available Salesforce org/coverage, LSP client names, and the language icon.

Left-side bubbles use a right curve (``); right-side bubbles use a left curve (``). Mode, workspace/file, and final SF/LSP/language use Tigerlily `#E75B45`; position remains Indigo `#5570D2`; Git remains pale olive `#A8D866`. The unboxed relative path uses darkened Tigerlily `#C44D3B`.

---

## Windows (splits)

| Key | Mode | Action |
| --- | --- | --- |
| `<C-h>` / `<C-l>` / `<C-j>` / `<C-k>` | n | Focus left / right / lower / upper |
| `ss` | n | **Horizontal** split |
| `sv` | n | **Vertical** split |
| `sh` / `sl` / `sj` / `sk` | n | Focus left / right / lower / upper (Craftzdog letters) |

`<C-hjkl>` and `s`+hjkl do the same focus — pick one muscle memory. `ss`/`sv` may delay one-key `s` (substitute) by `timeoutlen` (300 ms).

---

## Black-hole delete

Deletes that **don’t** overwrite the default yank register (`"_`).

| Key | Mode | Action |
| --- | --- | --- |
| `x` | n | Delete char → black hole |
| `<leader>d` | n, v | Delete → black hole |
| `<leader>D` | n | Delete to EOL → black hole |

Stock `d`/`c` still use registers. Yank history: [qol.md](./qol.md#yank-history-luapluginsyankylua).

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
