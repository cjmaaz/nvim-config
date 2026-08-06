# which-key

Defined in `lua/plugins/which-key.lua`. Discovers pending keys after a prefix; does **not** add maps by itself (labels come from each map’s `desc` plus `spec` groups).

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md)

---

| Action | How |
| --- | --- |
| See leader groups | Press `<Space>`, wait ~300ms (`delay`) |
| Open a group | Press the next key (`h` = Git hunk, `b` = Buffer, `f` = File/Find, …) |
| Leave the popup | `<Esc>` |

| Group prefix | Label in popup | Maps live in | Doc |
| --- | --- | --- | --- |
| `<leader>b` | Buffer | `lua/config/keymaps.lua` (`bd`, …) | [core.md](./core.md) |
| `<leader>h` | Git hunk | `lua/plugins/git.lua` `on_attach` | [git.md](./git.md) |
| `<leader>f` | File/Find | `lua/plugins/explorer.lua` (`fe`, `fE`) | [explorer.md](./explorer.md) |
| `<leader>g` | Git | `lua/plugins/explorer.lua` (`ge`); expand later | [explorer.md](./explorer.md) |
| `<leader>s` | Search | `lua/plugins/telescope.lua` (`sf`, `sg`, …) | [telescope.md](./telescope.md) |
| `<leader>c` | Code | `formatting.lua` (`cf`); `linting.lua` (`cl`); LSP `ca` | [lsp.md](./lsp.md) |
| `<leader>t` | Toggle | `formatting.lua` (`tf`); `linting.lua` (`tl`); LSP `th` inlays | [lsp.md](./lsp.md) |

Commented optional: `<leader>?` to show buffer-local maps only.

Pairs with `vim.opt.timeoutlen = 300` in `lua/config/options.lua`.

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md)
