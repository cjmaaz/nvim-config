# QoL polish (sessions, Trouble, surround, flash, undotree)

Extra quality-of-life plugins beyond the core edit/LSP loop. Dropbar stays parked (navic already in the statusline).

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

Label-jump (`folke/flash.nvim`). Mapped on **`gs`/`gS`** so stock `s` (substitute) and neo-tree `s` (vsplit) stay free.

| Key | Mode | Action |
| --- | --- | --- |
| `gs` | n, x, o | Flash **jump** (type labels) |
| `gS` | n, x, o | Flash **treesitter** node |
| `r` | o | **Remote** Flash (operator-pending) |
| `R` | o, x | Treesitter **search** |
| `<C-s>` | c | Toggle Flash in **command-line** search |

---

## Undotree (`lua/plugins/undotree.lua`)

Visual undo history. Needs `opt.undofile = true` (already on in `options.lua`).

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>u` | n | Toggle Undotree |

---

## Related (not in this file)

| Feature | Where |
| --- | --- |
| Inline **git blame** toggle | [`<leader>tb`](./git.md) |
| SF **org/coverage** in statusline | [salesforce.md](./salesforce.md) · `statusline.lua` |
| Telescope **ignore** globs | [telescope.md](./telescope.md) |

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [telescope](./telescope.md) · [which-key](./which-key.md)
