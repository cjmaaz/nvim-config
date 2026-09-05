# which-key

Defined in `lua/plugins/which-key.lua`. Discovers pending keys after a prefix; does **not** add maps by itself (labels come from each map’s `desc` plus `spec` groups).

Popup: **classic** full-width strip with a rounded neutral border and charcoal Catppuccin surface bg from `lua/config/ui_chrome.lua` (shared across bars and panels), max height **50%** of the screen. The strip may cover the editor cursor row; while it is visible, the real blinking cursor is hidden and its exact `guicursor` setting is restored on close. Columns have no forced maximum width, so long descriptions stay intact rather than being ellipsized.

Icons (when `vim.g.have_nerd_font`): **color = related-action family**, not the whole leader group. Similar/paired maps share a color with different glyphs (e.g. SF tests `a`/`A`/`t`/`T` green; retrieve/metadata azure; `<leader>c` format/lint/action each their own color). `]a`/`A`/`b`/`B` (and `[` twins) are mapped in `keymaps.lua` with buffer=cyan / argument=azure.

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [project](./project.md) · [markdown](./markdown.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [salesforce](./salesforce.md) · [comment](./comment.md) · [qol](./qol.md)

---

| Action | How |
| --- | --- |
| See leader groups | Press `<Space>`, wait ~300ms (`delay`) |
| Open a group | Press the next key (`h` = Git hunk, `b` = Buffer, `f` = File/Find, …) |
| Scroll popup | `Ctrl-d` / `Ctrl-u`; those mappings are filtered from which-key’s tree but still recenter-scroll normal buffers when the popup is closed |
| Leave the popup | `<Esc>` |

| Group prefix | Label in popup | Maps live in | Doc |
| --- | --- | --- | --- |
| `<leader>b` | Buffer | `lua/config/keymaps.lua` (`bd`, `bo`, `bi`) | [core.md](./core.md) |
| `<leader>h` | Git hunk | `lua/plugins/git.lua` `on_attach` | [git.md](./git.md) |
| `<leader>f` | File/Find | Neo-tree `fe`/`fE`; optional Yazi `fy`/`fY`/`fr` | [explorer.md](./explorer.md) |
| `<leader>g` | Git | `lazygit.lua` (`gg`, `gf`) | [git.md](./git.md) |
| `<leader>m` | Markdown | `markdown.lua` (`mr`, `mp`) | [markdown.md](./markdown.md) |
| `<leader>d` | Delete (black hole) | `keymaps.lua` (`d`, `D`); `x` also black-hole | [core.md](./core.md) |
| `<leader>s` | Search | `telescope.lua` (`sf`, `sg`, `sm`, lowercase `sr` resume); Grug Far uppercase `sR`; TODO `st` | [telescope.md](./telescope.md) · [comment.md](./comment.md) |
| `<leader>S` | Salesforce | `lua/plugins/salesforce.lua` (`Sp`, `Sx`, …) | [salesforce.md](./salesforce.md) |
| `<leader>c` | Code | Neogen docs `cn`; format `cf`; lint `cl`; LSP action `ca` | [comment.md](./comment.md) · [lsp.md](./lsp.md) |
| `<leader>p` | Project | `project_scaffold.lua` (`pn`); `project_runner.lua` (`pr`) | [project.md](./project.md) |
| `<leader>t` | Toggle | `tw` wrap · `td` inline diagnostics · `tf` FoS · `tl` lint · `th` inlays · `tb` blame · `tg`/`tG` Gremlins | [core.md](./core.md) · [lsp.md](./lsp.md) · [git.md](./git.md) · [qol.md](./qol.md) |
| `<leader>q` | Session | `persistence.lua` (`qs`, `qS`, `ql`, `qd`) | [qol.md](./qol.md) |
| `<leader>x` | Trouble | diagnostics `xx`/`xX`; TODO tree `xt` | [qol.md](./qol.md) · [comment.md](./comment.md) |
| `<leader>u` | Undotree | `undotree.lua` | [qol.md](./qol.md) |
| `gc` / `gb` | Comment line / block | `lua/plugins/comment.lua` | [comment.md](./comment.md) |
| `gs` / `gS` | Flash jump / treesitter | `lua/plugins/flash.lua` | [qol.md](./qol.md) |
| `s` | Split / window | `ss`/`sv` · `sh`/`sj`/`sk`/`sl` | [core.md](./core.md) |

Commented optional: `<leader>?` to show buffer-local maps only.

Pairs with `vim.opt.timeoutlen = 300` in `lua/config/options.lua`.

---

Nav: [index](./README.md) · [core](./core.md) · [git](./git.md) · [explorer](./explorer.md) · [project](./project.md) · [markdown](./markdown.md) · [telescope](./telescope.md) · [treesitter](./treesitter.md) · [lsp](./lsp.md) · [salesforce](./salesforce.md) · [comment](./comment.md) · [qol](./qol.md)
