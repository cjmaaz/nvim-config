# Neovim Anki keymap deck

Import [`neovim-keymaps.tsv`](./neovim-keymaps.tsv) into Anki to study this repository’s active mappings alongside practical native Vim/Neovim commands.

## Contents

- **729 Basic notes**
- **292 config cards:** global mappings plus curated Telescope, Neo-tree, Yazi, Trouble, Git, LSP, Salesforce, picker, and terminal-local controls
- **437 native cards:** modes, motions, operators, text objects, practical editing recipes, registers, search, marks, windows, buffers, folds, quickfix, macros, terminal use, and useful Ex commands
- Config overrides and collisions are called out explicitly rather than teaching the stock behavior as active.

## Import

1. In Anki, choose **File → Import** and select `neovim-keymaps.tsv`.
2. The file headers request:
   - separator: **Tab**
   - note type: **Basic**
   - deck: **Neovim::Keymaps**
   - columns: **Front**, **Back**, **Tags**
3. Check the preview shows three columns, then import.

If your Anki version does not apply a header automatically, select tab separation, map columns 1–2 to Front/Back, and map column 3 to Tags.

## Study by tag

- `config` — only mappings active in this repository
- `native` — practical stock Vim/Neovim behavior
- `config::salesforce`, `config::telescope`, `config::neo-tree`, etc. — one configured feature
- `native::motions`, `native::text_objects`, `native::windows`, etc. — one native topic
- `config::override` — stock keys whose behavior is replaced or qualified here
- `mode::normal`, `mode::insert`, `mode::visual`, etc. — filter by mode

The deck is intentionally key-to-action. Fronts include scope and mode so repeated keys such as `<CR>`, `q`, or `<C-d>` remain distinct.
