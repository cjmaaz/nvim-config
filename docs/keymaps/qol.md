# QoL polish

Extra quality-of-life beyond the core edit/LSP loop. Breadcrumb navigation now lives in **dropbar** — see [comment.md](./comment.md#breadcrumbs-dropbarnvim).

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [telescope](./telescope.md) · [which-key](./which-key.md)

---

## Sessions (`lua/plugins/persistence.lua`)

Restores open buffers for a cwd after restart (`folke/persistence.nvim`). Auto-saves on exit unless you stop it.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>qs` | n | Restore session for **current cwd** |
| `<leader>qS` | n | **Select** a saved session |
| `<leader>ql` | n | Restore the **last** session |
| `<leader>qd` | n | **Don't** save session on this exit |

Session files live under `stdpath("state")/sessions/`. `<leader>q` used to be diagnostic loclist — that moved to Trouble (`xx` / `xl`).

---

## Trouble (`lua/plugins/trouble.lua`)

Sticky panel for diagnostics and lists (richer than `:lopen`).

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>xx` | n | Workspace **diagnostics** (toggle) |
| `<leader>xX` | n | **Buffer** diagnostics only |
| `<leader>xs` | n | Document **symbols** |
| `<leader>xl` | n | **Location list** |
| `<leader>xq` | n | **Quickfix** |

Float at cursor remains [`<leader>e`](./core.md#diagnostics); Telescope [`<leader>sd`](./telescope.md) still searches diagnostics.

---

## Surround (`lua/plugins/surround.lua`)

`kylechui/nvim-surround` (vim-surround style). No leader maps — operator keys:

| Keys | Action | Example |
| --- | --- | --- |
| `ys{motion}{char}` | **Add** surround | `ysiw"` → `"word"` |
| `ds{char}` | **Delete** surround | `ds"` |
| `cs{target}{replacement}` | **Change** surround | `cs"'` |
| Visual `S{char}` | Surround selection | select → `S)` |

`:h nvim-surround` for more. Alt considered: Kickstart/CodeOSS `mini.surround` (`sa`/`sd`/`sr`).

---

## Flash (`lua/plugins/flash.lua`)

Label-jump (`folke/flash.nvim`). Mapped on **`gs`/`gS`** so stock `s` (substitute) stays usable; neo-tree’s own `s` (vsplit) is buffer-local.

| Key | Mode | Action |
| --- | --- | --- |
| `gs` | n, x, o | Flash **jump** (type labels) |
| `gS` | n, x, o | Flash **treesitter** node |
| `r` | o | **Remote** Flash (operator-pending) |
| `R` | o, x | Treesitter **search** |
| `<C-s>` | c | Toggle Flash in **command-line** search |

---

## Cursor animation (`lua/plugins/cursor.lua`)

`smear-cursor.nvim` animates long cursor jumps between buffers and windows in terminal Neovim. The calm preset keeps ordinary neighboring-line and insert-mode movement static; commented options in `cursor.lua` enable the full smear effect.

Command: `:SmearCursorToggle`. Neovide skips the plugin because it already has native cursor animation.

Terminal animation is character-cell based and can briefly obscure text while moving. `legacy_computing_symbols_support` stays off unless the active font supports U+1FB00–U+1FBFF.

---

## Undotree (`lua/plugins/undotree.lua`)

Visual undo history. Needs `opt.undofile = true` (already on in `options.lua`).

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>u` | n | Toggle Undotree |

---

## Yank history (`lua/plugins/yanky.lua`)

Remembers past yanks; `p`/`P` put from the ring (`gbprod/yanky.nvim`).

| Key | Mode | Action |
| --- | --- | --- |
| `p` / `P` | n, x | Put after / before (Yanky) |
| `gp` / `gP` | n, x | Put and leave cursor after |
| `<C-p>` / `<C-n>` | n | Cycle **previous** / **next** ring entry after a put |

---

## Dial (`lua/plugins/dial.lua`)

Smarter `<C-a>` / `<C-x>`: numbers, dates (`YYYY-MM-DD`), bools, `and`/`or`, `&&`/`||`, `let`/`const`.

| Key | Mode | Action |
| --- | --- | --- |
| `<C-a>` / `<C-x>` | n, v | Increment / decrement |
| `g<C-a>` / `g<C-x>` | v | Additive sequence across a visual block |

---

## Rainbow brackets (`lua/plugins/rainbow.lua`)

`rainbow-delimiters.nvim` — **10** high-contrast nesting colors. Shared palette: `lua/config/rainbow_palette.lua` (also drives the **indent scope** bar so brackets and the reverse-L line match by depth).

---

## Indent scope / reverse-L (`lua/plugins/indent.lua`)

Passive guides stay **dim**; the current treesitter scope uses the rainbow color for that depth, with `show_start` + `show_end` underlines (reverse-L). Vertical guides now use the thin **`▏`** glyph (shared by passive and active guides so the column doesn’t jump); thicker `▎` remains commented in `indent.lua`. Explicit `class_body` entries keep outer JS/TS classes visible, and custom Apex nodes fill ibl’s missing Apex scope map.

---

## Color highlighter (`lua/plugins/colorizer.lua`)

Paints `#hex` / `rgb()` / `hsl()` / Tailwind-ish classes in-buffer (`nvim-highlight-colors`).

---

## Space / listchars dots

In `lua/config/options.lua`: `list` + `listchars.space = "·"` (plus tab/trail/nbsp). Highlight `Whitespace` is dimmed in `autocmds.lua` so dots stay **very light**.

Toggle off: `vim.opt.list = false` or remove `space` from `listchars`.

---

## Related

| Feature | Where |
| --- | --- |
| Split / black-hole maps | [core.md](./core.md) |
| Inline **git blame** toggle | [`<leader>tb`](./git.md) |
| SF **org/coverage** in statusline | [salesforce.md](./salesforce.md) |
| Telescope **ignore** globs | [telescope.md](./telescope.md) |

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [telescope](./telescope.md) · [which-key](./which-key.md)
