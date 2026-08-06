# Keymaps

Custom shortcuts defined by this config. `<leader>` is **Space** (see `init.lua`).

Only maps we actually set are listed here. Built-in Vim/Neovim keys (`hjkl`, `:w`, `gt` / `gT`, …) are omitted unless we remapped them.

`vim.keymap.set(mode, lhs, rhs, opts?)` — **mode** = when (`n` normal, `i` insert, `v` visual, `t` terminal, …); **lhs** = keys you press; **rhs** = action; **opts** = usually `{ desc = "…" }`.

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

### Bufferline (UI)

Defined in `lua/plugins/bufferline.lua`. Visual bar of **buffers** (`mode = "buffers"`). Cycle still uses `<S-h>` / `<S-l>` above — not `gt` / `gT` (those remain tabpages). Close with `<leader>bd` (close icons are off).

Optional later: enable `diagnostics = "nvim_lsp"` after LSP; Craftzdog-style `mode = "tabs"` is intentionally not used.

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

### Motion comfort

| Key | Mode | Action |
| --- | --- | --- |
| `n` | n | Next search match, then center (`nzzzv`) |
| `N` | n | Previous search match, then center |
| `<C-d>` | n | Half page down, then center |
| `<C-u>` | n | Half page up, then center |

### Visual line move

| Key | Mode | Action |
| --- | --- | --- |
| `J` | v | Move selection down (overrides visual join) |
| `K` | v | Move selection up (overrides visual keyword lookup) |

### Terminal

Interactive shell buffer (not `:!`):

| Command / key | Action |
| --- | --- |
| `:terminal` | Open a terminal in the current window |
| `:split \| terminal` / `:vsplit \| terminal` | Terminal in a split |
| `<Esc><Esc>` | **t** — leave terminal-job mode → normal mode in that buffer (`<C-\><C-n>`) |

`:!cmd` only runs a one-shot shell command and returns; it does **not** enter terminal mode.

### hjkl training

| Key | Mode | Action |
| --- | --- | --- |
| `<left>` / `<right>` / `<up>` / `<down>` | n | Echo “Use h/l/k/j to move!” (no cursor move) |

### Diagnostics

Defined in `lua/config/keymaps.lua` (`vim.diagnostic.config` + maps). Works before LSP; maps are no-ops until a server or linter reports issues. Jump opens a float via `jump.on_jump` (not the deprecated `float = true` jump opt).

| Key | Mode | Action |
| --- | --- | --- |
| `]d` | n | Next diagnostic (float on jump) |
| `[d` | n | Previous diagnostic (float on jump) |
| `<leader>e` | n | Show diagnostic float at cursor |
| `<leader>q` | n | Fill **location list** with buffer diagnostics (`:lopen` / `:lclose`) |

Display: virtual text on, underline from WARN+, severity-sorted, Nerd Font / ASCII signs. Commented alts in config: `virtual_lines`, full underline, `setqflist` instead of loclist.

Also: Telescope `<leader>sd` searches diagnostics once they exist.

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

## Explorer (neo-tree)

Defined in `lua/plugins/explorer.lua`. Sidebar file tree (not netrw / oil). Focus stays on learning the keys below; press `?` inside the tree for neo-tree’s own help.

### Open / close from any normal buffer

| Key | Action | Notes |
| --- | --- | --- |
| `<leader>fe` | Toggle filesystem tree (left) | Same key again closes it |
| `<leader>fE` | Reveal the current file in the tree | Opens the tree and jumps to this buffer’s path |
| `<leader>ge` | Toggle **git status** view | Changed/untracked files in a float |

`<leader>` is **Space**, so e.g. `Space` then `f` then `e`. which-key shows groups **File/Find** (`f`) and **Git** (`g`).

### Inside the neo-tree window

Focus must be **in** the tree (click it or move with `<C-h>` if it’s on the left). These are neo-tree defaults we keep (except Space — disabled so it doesn’t fight `<leader>`).

#### Navigate & open

| Key | Action |
| --- | --- |
| `j` / `k` | Move down / up |
| `h` or `C` | Collapse folder / close node |
| `l` or `<CR>` | Expand folder **or** open file in the last used editor window |
| `za`-style: expander glyphs | Click / toggle via open |
| `z` | Close all nodes |
| `S` | Open file in a **horizontal** split |
| `s` | Open file in a **vertical** split |
| `t` | Open file in a **new tabpage** |
| `P` | Toggle **preview** float of the file under the cursor |
| `q` | Close the neo-tree window |
| `<Esc>` | Cancel preview / floating prompt |

#### Create / rename / delete / clipboard

| Key | Action |
| --- | --- |
| `a` | **Add** a file (prompts for name; supports `foo/{a,b}.lua` brace expansion) |
| `A` | **Add** a directory |
| `d` | **Delete** (confirms) |
| `r` | **Rename** (full name) |
| `b` | Rename **basename** only |
| `y` | Copy node to neo-tree clipboard |
| `x` | Cut node to clipboard |
| `p` | Paste from clipboard |
| `c` | **Copy** to a path you type |
| `m` | **Move** to a path you type |
| `<C-r>` | Clear neo-tree clipboard |

#### Visibility & search in the tree

| Key | Action |
| --- | --- |
| `H` | Toggle **hidden** / filtered items |
| `/` | Fuzzy find files in the tree |
| `D` | Fuzzy find **directories** |
| `R` | Refresh the tree from disk |
| `i` | Show file details |
| `?` | Show neo-tree help (mapping list) |
| `<` / `>` | Previous / next neo-tree **source** (filesystem, buffers, git_status, …) |

### Settings we chose (why)

| Setting | Value | Why |
| --- | --- | --- |
| `hijack_netrw_behavior` | `open_default` | Opening a directory uses neo-tree instead of netrw |
| `follow_current_file` | on | Tree tracks the file you’re editing |
| `use_libuv_file_watcher` | on | Auto-refresh when files change outside Neovim |
| `hide_dotfiles` / `hide_gitignored` | false | SF / tooling often needs dotfiles visible; use `H` to tidy |
| `window.mappings["<space>"]` | `none` | Space is `<leader>` — don’t toggle nodes with Space |
| Width | 34 | Comfortable sidebar without eating the editor |

Full option reference: `:help neo-tree` and `:help neo-tree-mappings`.

---

## Telescope (search / pickers)

Defined in `lua/plugins/telescope.lua`. Fuzzy UI over files, text, buffers, help, and more.

**Host tools:** `rg` (live grep) and `fd` (find files) — see [TOOLS.md](./TOOLS.md). Optional: `make` so `telescope-fzf-native` can compile (faster sorting).

### Open a picker (normal mode unless noted)

`<leader>` is **Space**. Press `Space` then `s` — which-key shows the **Search** group.

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
| `<leader>sr` | n | **Resume** the last Telescope picker |
| `<leader>sn` | n | Find files under your **Neovim config** dir (`stdpath("config")`) |

### Inside a Telescope window

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

### Extensions we load

| Extension | Role |
| --- | --- |
| `fzf` | Native fuzzy sorter (`telescope-fzf-native`; needs `make` on first install) |
| `ui-select` | Routes Neovim `vim.ui.select` menus through Telescope (dropdown) |

---

## which-key

Defined in `lua/plugins/which-key.lua`. Discovers pending keys after a prefix; does **not** add maps by itself (labels come from each map’s `desc` plus `spec` groups).

| Action | How |
| --- | --- |
| See leader groups | Press `<Space>`, wait ~300ms (`delay`) |
| Open a group | Press the next key (`h` = Git hunk, `b` = Buffer, `f` = File/Find, …) |
| Leave the popup | `<Esc>` |

| Group prefix | Label in popup | Maps live in |
| --- | --- | --- |
| `<leader>b` | Buffer | `lua/config/keymaps.lua` (`bd`, …) |
| `<leader>h` | Git hunk | `lua/plugins/git.lua` `on_attach` |
| `<leader>f` | File/Find | `lua/plugins/explorer.lua` (`fe`, `fE`) |
| `<leader>g` | Git | `lua/plugins/explorer.lua` (`ge`); expand later |
| `<leader>s` | Search | `lua/plugins/telescope.lua` (`sf`, `sg`, …) |

Commented optional: `<leader>?` to show buffer-local maps only; future groups for toggle/LSP.

Pairs with `vim.opt.timeoutlen = 300` in `lua/config/options.lua`.

---

## UI notes

| Area | How you use it today |
| --- | --- |
| Statusline (lualine) | Always visible — mode, branch, diff, filename, diagnostics, location |
| Bufferline | Top bar of open buffers; cycle with `<S-h>` / `<S-l>` |
| neo-tree | `<leader>fe` toggle · `<leader>fE` reveal · `<leader>ge` git status |
| Telescope | `<leader>sf` files · `<leader>sg` grep · `<leader><leader>` buffers · … |
| Diagnostics | `]d`/`[d` · `<leader>e` float · `<leader>q` loclist |
| Colorscheme | Set at startup (`noctis_bordo`); change in `lua/plugins/colorscheme.lua` |
| which-key | `<Space>` then wait — see leader groups above |
| Plugin manager | `:Lazy` — UI for install/update/profile |

---

## Growing this doc

When you add keymaps in a later slice (LSP), append a section here in the same table style and link the defining file. Uncomment matching `spec` groups in `which-key.lua` when those prefixes exist.
