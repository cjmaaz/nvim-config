# Explorer (neo-tree)

Defined in `lua/plugins/explorer.lua`. Sidebar file tree (not netrw / oil). Focus stays on learning the keys below; press `?` inside the tree for neo-tree’s own help.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)

---

## Open / close from any normal buffer

| Key | Action | Notes |
| --- | --- | --- |
| `<leader>fe` | Toggle filesystem tree (left) | Same key again closes it |
| `<leader>fE` | Reveal the current file in the tree | Opens the tree and jumps to this buffer’s path |
| `<leader>ge` | Toggle **git status** view | Changed/untracked files in a float |

`<leader>` is **Space**, so e.g. `Space` then `f` then `e`. which-key shows groups **File/Find** (`f`) and **Git** (`g`) — [which-key.md](./which-key.md).

Fuzzy find without the tree: [telescope.md](./telescope.md) (`<leader>sf`).

---

## Inside the neo-tree window

Focus must be **in** the tree (click it or move with `<C-h>` if it’s on the left — [core.md](./core.md#windows-splits)). These are neo-tree defaults we keep (except Space — disabled so it doesn’t fight `<leader>`).

### Navigate & open

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
| `R` | Refresh the tree from disk |
| `i` | Show file details |
| `?` | Show neo-tree help (mapping list) |
| `<` / `>` | Previous / next neo-tree **source** (filesystem, buffers, git_status, …) |

---

## Settings we chose (why)

| Setting | Value | Why |
| --- | --- | --- |
| `hijack_netrw_behavior` | `open_default` | Opening a directory uses neo-tree instead of netrw |
| `follow_current_file` | on | Tree tracks the file you’re editing |
| `use_libuv_file_watcher` | on | Auto-refresh when files change outside Neovim |
| `hide_dotfiles` / `hide_gitignored` | **true** | Dotfiles & gitignored are filtered by default; **`H`** shows them (dimmed). Always-show: `.gitignore`, `.forceignore`, `.sfdx`, `.sf`. `never_show`: `.DS_Store` / `thumbs.db` (H won’t reveal those). |
| `window.mappings["<space>"]` | `none` | Space is `<leader>` — don’t toggle nodes with Space |
| Width | 34 | Comfortable sidebar without eating the editor |

Full option reference: `:help neo-tree` and `:help neo-tree-mappings`.

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
