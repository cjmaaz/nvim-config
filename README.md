# nvim-config

From-scratch Neovim config (lazy.nvim). Built one slice at a time.

## Docs

| Doc | Contents |
| --- | --- |
| [docs/keymaps/](docs/keymaps/README.md) | Custom shortcuts (split by topic; start at README) |
| [docs/diagnostics/](docs/diagnostics/README.md) | Diagnostic UI, settings, Java non-project FAQ |
| [docs/TOOLS.md](docs/TOOLS.md) | Host tools: Neovim, fonts, `rg` / `fd`, … |
| [docs/COMMITIZEN.md](docs/COMMITIZEN.md) | Optional conventional-commit CLI |

## Layout

```text
nvim-config/
├── docs/
│   ├── keymaps/          # shortcut cheatsheets (interlinked)
│   │   ├── README.md     # index, leaders, UI notes
│   │   ├── core.md       # buffers, windows, diagnostics keys, …
│   │   ├── git.md
│   │   ├── explorer.md
│   │   ├── telescope.md
│   │   ├── treesitter.md
│   │   ├── lsp.md        # LSP, blink, format, lint
│   │   ├── salesforce.md # sf.nvim <leader>S…
│   │   ├── comment.md    # Comment / TODO / breadcrumbs
│   │   └── which-key.md
│   ├── diagnostics/      # where diagnostics show + settings + Java FAQ
│   │   ├── README.md
│   │   ├── display.md
│   │   ├── quiet.md
│   │   └── java.md
│   ├── examples/
│   │   └── java-maven-minimal/  # sample Maven tree for jdtls
│   ├── KEYMAPS.md        # stub → docs/keymaps/
│   ├── DIAGNOSTICS.md    # stub → docs/diagnostics/
│   ├── TOOLS.md          # external prerequisites / optional tools
│   └── COMMITIZEN.md     # optional cz helper
├── init.lua              # entry: loader, leaders, require config.*
├── lazy-lock.json        # pinned plugin commits (commit this)
└── lua/
    ├── config/           # editor core — load before plugins
    │   ├── options.lua   # everyday editing options
    │   ├── keymaps.lua   # non-plugin maps (buffers, windows, diagnostics, …)
    │   ├── autocmds.lua  # yank, trim, final newline (Apex exempt), filetypes
    │   └── lazy.lua      # bootstrap lazy.nvim + import plugins/
    └── plugins/          # one plugin (or small family) per file
        ├── init.lua      # empty list; keeps `import = "plugins"` valid
        ├── colorscheme.lua # noctis_bordo + highlight overlays
        ├── statusline.lua  # lualine + web-devicons
        ├── bufferline.lua # visual buffer bar (not tabpages)
        ├── explorer.lua  # neo-tree file / git explorer
        ├── telescope.lua # fuzzy find / grep / buffers
        ├── treesitter.lua # parsers, highlight, folds, autotag
        ├── indent.lua    # indent-blankline (ibl) guides
        ├── autopairs.lua # auto (), {}, quotes
        ├── lsp.lua       # Mason + language servers (lua always; others on demand)
        ├── completion.lua # blink.cmp + LuaSnip
        ├── formatting.lua # conform; <leader>cf / tf
        ├── linting.lua   # nvim-lint; <leader>cl / tl; lazy Mason
        ├── salesforce.lua # sf.nvim + fzf-lua; <leader>S… (Sp push, Sx cancel)
        ├── comment.lua   # Comment.nvim + context-commentstring
        ├── todo-comments.lua # TODO/FIXME highlight + ]t / <leader>st
        ├── breadcrumbs.lua # dropbar clickable winbar + symbol menus
        ├── git.lua       # gitsigns signs + hunk keymaps
        └── which-key.lua # leader popup / group labels
```

## Quick start

1. Install host tools from [docs/TOOLS.md](docs/TOOLS.md) (Neovim **0.12+**, Git, a Nerd Font, **`rg` + `fd`**, **tree-sitter CLI** + C compiler; **JDK** if you edit Apex; **`sf` CLI** for Salesforce projects).
2. Point Neovim at this config (symlink, `NVIM_APPNAME`, or clone as your `~/.config/nvim`).
3. Open Neovim once — lazy.nvim bootstraps and installs plugins from `lazy-lock.json` (Treesitter/Mason may download on first use).
4. Skim [docs/keymaps/](docs/keymaps/README.md) — `<leader>sf` / `<leader>cf` / `gd` / neo-tree `<leader>fe` / Salesforce `<leader>S`.
