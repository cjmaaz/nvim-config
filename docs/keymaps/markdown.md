# Markdown rendering

Defined in `lua/plugins/markdown.lua` using `render-markdown.nvim`. Rendering happens inside Neovim; no browser, Node process, or preview server is required.

The plugin loads only for `markdown` / `markdown.mdx`, reuses the existing Treesitter parsers and Nerd Font icons, and keeps this config’s soft-wrap behavior. Markdown indent guides are disabled so they do not compete with rendered headings, lists, quotes, tables, and code blocks.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>mr` | n | Toggle the current buffer between rendered and raw Markdown |
| `<leader>mp` | n | Open or close a live rendered side preview |

`<leader>` is **Space**, so use `Space`, `m`, `r` or `Space`, `m`, `p`.

Commands: `:RenderMarkdown toggle` · `:RenderMarkdown preview`.

Wide Markdown tables still follow Neovim’s normal wrapping behavior; the renderer does not reflow individual table cells.

Nav: [index](./README.md) · [core](./core.md) · [qol](./qol.md) · [which-key](./which-key.md)
