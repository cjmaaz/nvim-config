# File managers (Neo-tree + optional Yazi)

Defined in `lua/plugins/explorer.lua`. Neo-tree is now a filesystem-only sidebar (not netrw / oil) with auto-expanding width for long names. Buffer selection stays on `<leader><leader>` and Git browsing stays in LazyGit; filesystem Git badges remain enabled. Neo-tree, bufferline, and the statusline language corner share `nvim-web-devicons`; `lua/plugins/icons.lua` forces the Salesforce cloud for Apex `.cls`, `.trigger`, and `.apex` files on every surface. Press `?` inside the tree for neo-tree’s own help. Shared neutral Catppuccin chrome matches bufferline, lualine, which-key, and Telescope.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

## Open / close from any normal buffer

| Key | Action | Notes |
| --- | --- | --- |
| `<leader>fe` | Toggle filesystem tree (left) | Same key again closes it |
| `<leader>fE` | Reveal the current file in the tree | Opens the tree and jumps to this buffer’s path |

`<leader>` is **Space**, so e.g. `Space` then `f` then `e`. which-key shows groups **File/Find** (`f`) and **Git** (`g`) — [which-key.md](./which-key.md).

Fuzzy find without the tree: [telescope.md](./telescope.md) (`<leader>sf`).

## Optional Yazi file manager

`lua/plugins/yazi.lua` adds a transient floating file manager only when the host `yazi` executable exists at startup. Neo-tree remains the persistent sidebar, keeps directory-opening ownership, and is the fallback when Yazi is absent.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>fy` | n, v | Open Yazi at the current file or visually selected path |
| `<leader>fY` | n | Open Yazi at Neovim’s current working directory |
| `<leader>fr` | n | Resume/toggle the last Yazi session |

Inside Yazi, `<F1>` shows integration help; `<C-v>` / `<C-x>` / `<C-t>` open in vertical split / horizontal split / tabpage, `<C-s>` greps through Telescope, `<C-g>` sends the current directory or selected paths to Grug Far, `<Tab>` cycles open buffers, and `<C-q>` sends selections to quickfix. Yazi’s `<C-\>` cwd action is disabled so Neovim’s terminal escape prefix remains available, and dependency-specific `<C-y>`/`<C-o>` actions stay off until grealpath/snacks.picker are added.

The integration does not hijack directory buffers or change Neovim’s cwd on close. It refuses to open from the command-line window (`q:` / `q/`); close that window first. If terminal input ever feels stuck, press `<Esc><Esc>` to enter Normal mode in the Yazi buffer, then `q` to ask Yazi to quit cleanly. After installing Yazi, restart Neovim and run `:checkhealth yazi`.

---

## Inside the neo-tree window

Focus must be **in** the tree (click it or move with `<C-h>` if it’s on the left — [core.md](./core.md#windows-splits)). These are neo-tree defaults we keep (except Space — disabled so it doesn’t fight `<leader>`).

### Navigate & open

| Key | Action |
| --- | --- |
| `j` / `k` | Move down / up |
| `h` or `C` | Collapse folder / close node |
| `l` or `<CR>` | Expand folder **or** open file in the last used editor window |
| `<BS>` | Move the tree root **up one directory** |
| `.` | Set the selected directory as the new tree **root** |
| `za`-style: expander glyphs | Click / toggle via open |
| `z` | Close all nodes |
| `S` | Open file in a **horizontal** split |
| `s` | Open file in a **vertical** split |
| `t` | Open file in a **new tabpage** |
| `P` | Toggle **preview** float of the file under the cursor |
| `q` | Close the neo-tree window |
| `<Esc>` | Cancel preview / floating prompt |

### Create / rename / delete / clipboard

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

### Visibility & search in the tree

| Key | Action |
| --- | --- |
| `H` | Toggle **hidden** / filtered items (dotfiles + gitignored) — shown dimmed when on |
| `/` | Fuzzy find files in the tree |
| `D` | Fuzzy find **directories** |
| `[g` / `]g` | Previous / next **Git-modified** file |
| `o` | Open the **order-by** menu (`on` name, `om` modified, `og` Git status, …) |
| `e` | Toggle automatic width expansion; off returns to the base width |
| `R` | Refresh the tree from disk |
| `i` | Show file details |
| `?` | Show neo-tree help (mapping list) |

---

## Settings we chose (why)

| Setting | Value | Why |
| --- | --- | --- |
| `hijack_netrw_behavior` | `open_default` | Opening a directory uses neo-tree instead of netrw |
| `follow_current_file` | on | Tree tracks the file you’re editing |
| `use_libuv_file_watcher` | on | Auto-refresh when files change outside Neovim |
| Active sources | filesystem only | Buffer picker and LazyGit replace the redundant Buffer/Git source views |
| Source selector | off | No single-item Files tab consumes winbar space |
| Opened-file markers | all | Files represented by open buffers use `NeoTreeFileNameOpened` styling |
| Fuzzy filter reset | on file open | Reopening the tree does not retain a stale `/` filter |
| `git_status_scope_to_path` | **true** | Faster when a monorepo worktree is above the displayed root; set the commented `false` alternate in `explorer.lua` if scoped results do not suit you |
| `hide_dotfiles` / `hide_gitignored` | **true** | Dotfiles & gitignored are filtered by default; **`H`** shows them (dimmed). Always-show: `.gitignore`, `.forceignore`, `.sfdx`, `.sf`. `never_show`: `.DS_Store` / `thumbs.db` (H won’t reveal those). |
| `window.mappings["<space>"]` | `none` | Space is `<leader>` — don’t toggle nodes with Space |
| Width | 34 base + auto-expand | Long visible names grow the sidebar instead of fading; `e` toggles back to the base width |

Full option reference: `:help neo-tree` and `:help neo-tree-mappings`.

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
