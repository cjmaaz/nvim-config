# nvim-config

From-scratch Neovim config (lazy.nvim). Built one slice at a time.

## Docs

| Doc | Contents |
| --- | --- |
| [docs/KEYMAPS.md](docs/KEYMAPS.md) | Custom shortcuts (leaders, buffers, gitsigns, which-key, …) |
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
    │   ├── keymaps.lua   # non-plugin maps (buffers, windows, …)
    │   ├── autocmds.lua  # yank, trim, final newline (Apex exempt), filetypes
    │   └── lazy.lua      # bootstrap lazy.nvim + import plugins/
    └── plugins/          # one plugin (or small family) per file
        ├── init.lua      # empty list; keeps `import = "plugins"` valid
        ├── colorscheme.lua
        ├── statusline.lua
        ├── bufferline.lua # visual buffer bar (not tabpages)
        ├── git.lua       # gitsigns signs + hunk keymaps
        └── which-key.lua # leader popup / group labels
```

## Quick start

1. Install host tools from [docs/TOOLS.md](docs/TOOLS.md) (Neovim, Git, a Nerd Font; ideally `rg` + `fd`).
2. Point Neovim at this config (symlink, `NVIM_APPNAME`, or clone as your `~/.config/nvim`).
3. Open Neovim once — lazy.nvim bootstraps and installs plugins from `lazy-lock.json`.
4. Skim [docs/KEYMAPS.md](docs/KEYMAPS.md) for `<leader>` (Space), buffers/bufferline, git hunks, and which-key.
