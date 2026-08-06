# Telescope (search / pickers)

Defined in `lua/plugins/telescope.lua`. Fuzzy UI over files, text, buffers, help, and more.

**Host tools:** `rg` (live grep) and `fd` (find files) — see [TOOLS.md](../TOOLS.md). Optional: `make` so `telescope-fzf-native` can compile (faster sorting).

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

## Open a picker (normal mode unless noted)

`<leader>` is **Space**. Press `Space` then `s` — which-key shows the **Search** group ([which-key.md](./which-key.md)).

| Key | Mode | What it does |
| --- | --- | --- |
| `<leader>sf` | n | **Find files** in the project (respects `.gitignore` via `fd`/`rg` when available) |
| `<leader>sg` | n | **Live grep** — type text; results update as you type (`rg`) |
| `<leader>sw` | n, x | Grep for the **word under cursor** / visual selection |
| `<leader>s.` | n | **Recent files** (oldfiles) |
| `<leader><leader>` | n | List open **buffers** (pick one to jump) |
| `<leader>/` | n | Fuzzy search **inside the current buffer** only (dropdown, no preview) |
| `<leader>s/` | n | Live grep limited to **already-open files** |
| `<leader>sh` | n | Search **help** tags (`:help`) |
| `<leader>sk` | n | Search **keymaps** (great for discovering `<leader>…`) |
| `<leader>sc` | n | Search **Ex commands** |
| `<leader>ss` | n | List **Telescope builtins** (meta-picker) |
| `<leader>sd` | n | Search **diagnostics** (useful once LSP is on; empty before that) |
| `<leader>st` | n | Search **TODO / FIXME** comments (todo-comments) |
| `<leader>sr` | n | **Resume** the last Telescope picker |
| `<leader>sn` | n | Find files under your **Neovim config** dir (`stdpath("config")`) |

Sidebar tree instead: [explorer.md](./explorer.md) (`<leader>fe`). Diagnostics jump keys: [core.md](./core.md#diagnostics).

---

## Inside a Telescope window

You start in **insert** mode in the prompt (type to filter).

| Key | Mode | Action |
| --- | --- | --- |
| Type text | i | Narrow results |
| `<C-j>` / `<C-k>` | i | Move selection down / up (our custom maps) |
| `<CR>` | i/n | Open the selected item |
| `<C-x>` | i | Open in horizontal split (Telescope default) |
| `<C-v>` | i | Open in vertical split (default) |
| `<C-t>` | i | Open in new tabpage (default) |
| `<C-q>` | i | Send results to the **quickfix** (default) |
| `<C-u>` / `<C-d>` | i | Scroll preview up / down (default) |
| `<Esc>` | i | Leave insert → normal in the picker, or close depending on setup; often `<C-c>` closes |
| `?` | n | Show Telescope help for mappings (when in normal mode in the picker) |

Tip: `<leader>sr` reopens whatever you just closed — handy after a mis-click.

---

## Extensions we load

| Extension | Role |
| --- | --- |
| `fzf` | Native fuzzy sorter (`telescope-fzf-native`; needs `make` on first install) |
| `ui-select` | Routes Neovim `vim.ui.select` menus through Telescope (dropdown) |

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
