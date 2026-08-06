# which-key

Defined in `lua/plugins/which-key.lua`. Discovers pending keys after a prefix; does **not** add maps by itself (labels come from each map’s `desc` plus `spec` groups).

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [salesforce](./salesforce.md) · [comment](./comment.md) · [qol](./qol.md)

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
| `<leader>g` | Git | `explorer.lua` (`ge`); `lazygit.lua` (`gg`, `gf`) | [explorer.md](./explorer.md) · [git.md](./git.md) |
| `<leader>s` | Search | `telescope.lua` (`sf`, `sg`, …); `todo-comments` (`st`) | [telescope.md](./telescope.md) · [comment.md](./comment.md) |
| `<leader>S` | Salesforce | `lua/plugins/salesforce.lua` (`Sp`, `Sx`, …) | [salesforce.md](./salesforce.md) |
| `<leader>c` | Code | `formatting.lua` (`cf`); `linting.lua` (`cl`); LSP `ca` | [lsp.md](./lsp.md) |
| `<leader>t` | Toggle | `tf` FoS · `tl` lint · `th` inlays · `tb` blame | [lsp.md](./lsp.md) · [git.md](./git.md) |
| `<leader>q` | Session | `persistence.lua` (`qs`, `qS`, `ql`, `qd`) | [qol.md](./qol.md) |
| `<leader>x` | Trouble | `trouble.lua` (`xx`, `xX`, …) | [qol.md](./qol.md) |
| `<leader>u` | Undotree | `undotree.lua` | [qol.md](./qol.md) |
| `gc` / `gb` | Comment line / block | `lua/plugins/comment.lua` | [comment.md](./comment.md) |
| `gs` / `gS` | Flash jump / treesitter | `lua/plugins/flash.lua` | [qol.md](./qol.md) |

Commented optional: `<leader>?` to show buffer-local maps only.

Pairs with `vim.opt.timeoutlen = 300` in `lua/config/options.lua`.

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [salesforce](./salesforce.md) · [comment](./comment.md) · [qol](./qol.md)
