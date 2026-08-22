# Telescope (search / pickers)

Defined in `lua/plugins/telescope.lua`. Fuzzy UI over files, text, buffers, help, and more.

**Host tools:** `rg` (live grep) and `fd` (find files) — see [TOOLS.md](../TOOLS.md). Optional: `make` so `telescope-fzf-native` can compile (faster sorting).

Pinned to Telescope **`master`** (not frozen `0.1.x`) so preview highlighting works with nvim-treesitter **`main`** / Neovim 0.12. Fallback if needed: `defaults.preview.treesitter = false` in `telescope.lua`.

Config also shims `telescope.utils.if_nil` when missing (Nvim 0.12 + Telescope master can leave it nil, which breaks `vim.ui.select` / org picker via ui-select).

Panel chrome uses Monokai Pro accents over the warm charcoal palette in `lua/config/ui_chrome.lua`: subtle borders, a raised active row, and vivid accents matching the bars, which-key, and neo-tree. Normal pickers use a responsive 90% × 85% horizontal grid with separately rounded prompt/results/preview boxes, the prompt at the bottom, and the selected file or symbol in the preview title. File rows and picker markers use Nerd Font icons when available, with plain-text fallbacks.

**Ignore globs** (extra noise beyond `.gitignore`): `node_modules/`, `.git/`, `.sfdx/`, `.sf/`, `target/`, `dist/`, `build/`, `*.class`/`*.jar`, lockfiles, `*.min.js`/`*.min.css` — see `file_ignore_patterns` in `telescope.lua`.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [qol](./qol.md) · [which-key](./which-key.md)

---

## Open a picker (normal mode unless noted)

`<leader>` is **Space**. Press `Space` then `s` — which-key shows the **Search** group ([which-key.md](./which-key.md)).

| Key | Mode | What it does |
| --- | --- | --- |
| `<leader>sf` | n | **Find files** in the project (respects `.gitignore` via `fd`/`rg` when available) |
| `<leader>sg` | n | **Live grep** — type text; results update as you type (`rg`) |
| `<leader>sm` | n | **Live multi-grep** — type `pattern`, then **two spaces**, then a glob (e.g. `TODO  *.lua`) or a shortcut (`TODO  l`) |
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
| `<leader>sp` | n | Find files under **lazy.nvim plugin packages** (`stdpath("data")/lazy`) |

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

## Live multi-grep (`<leader>sm`)

Custom picker from [TJ’s Advanced Telescope scripting](https://www.youtube.com/watch?v=xdXE1tOT-qg) — `lua/config/telescope/multigrep.lua`.

Content mode:

1. Type a ripgrep **pattern** (can include spaces).
2. Type **two spaces**, then a **glob** (or a one-letter shortcut).
3. Results update live via `rg -e pattern -g glob`.

File mode starts the prompt with **two spaces**, followed by one ripgrep path glob. It uses `rg --files`; no file contents are searched. The glob portion in **both content and file modes** follows smart case: all lowercase uses case-insensitive `--iglob`, while any uppercase letter switches to case-sensitive `-g`.

Examples:

| Prompt | Effect |
| --- | --- |
| `function` | Grep for `function` everywhere (same idea as live_grep) |
| `function  *.lua` | Only `*.lua` |
| `TODO  l` | Shortcut `l` → `*.lua` |
| `Account  a` | Shortcut `a` → `*.{cls,trigger,apex}` |
| `useState  j` | Shortcut `j` → `*.{js,jsx,ts,tsx}` |
| `gginglevel  **/classes/**/*logg*` | Case-insensitive text + file glob; finds `LoggingLevel` in `Logger.cls` |
| `  *xyz*` | Files containing any case of `xyz` / `XYZ`, at any depth |
| `  *Xyz*` | Files containing the exact-case spelling `Xyz` |
| `  **/abc/**/*xyz*` | Matching files beneath any directory named `abc` |
| `  force-app/**/*.cls` | Apex class files below `force-app` |

The two leading spaces in file-mode examples are significant. File mode expects an explicit glob, not a fuzzy query; shell characters are passed as an argv value rather than evaluated by a shell. Content shortcuts (`l` `v` `n` `c` `r` `g` `j` `a` `h` `p` `m`) live in `multigrep.lua` and do not expand in file mode. Stock `<leader>sg` stays plain live_grep.

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
