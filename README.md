# nvim-config

From-scratch Neovim config (lazy.nvim). Built one slice at a time.

## Docs

| Doc | Contents |
| --- | --- |
| [docs/KEYMAPS.md](docs/KEYMAPS.md) | Custom shortcuts (leaders, Telescope, diagnostics, neo-tree, …) |
| [docs/TOOLS.md](docs/TOOLS.md) | Host tools: Neovim, fonts, `rg` / `fd`, … |
| [docs/COMMITIZEN.md](docs/COMMITIZEN.md) | Optional conventional-commit CLI |

## Layout

```text
nvim-config/
├── docs/
│   ├── KEYMAPS.md        # shortcuts defined by this config
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
        ├── git.lua       # gitsigns signs + hunk keymaps
        └── which-key.lua # leader popup / group labels
```

## Quick start

1. Install host tools from [docs/TOOLS.md](docs/TOOLS.md) (Neovim **0.12+**, Git, a Nerd Font, **`rg` + `fd`**, **tree-sitter CLI** + C compiler).
2. Point Neovim at this config (symlink, `NVIM_APPNAME`, or clone as your `~/.config/nvim`).
3. Open Neovim once — lazy.nvim bootstraps and installs plugins from `lazy-lock.json` (Treesitter may compile parsers on first use).
4. Skim [docs/KEYMAPS.md](docs/KEYMAPS.md) — start with `<leader>sf` / `<leader>sg` and neo-tree `<leader>fe`.
