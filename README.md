# nvim-config

```text
nvim-config/
├── docs/                 # project notes
├── init.lua              # entry: loader, leaders, require config.*
├── lazy-lock.json        # pinned plugin commits (commit this)
└── lua/
    ├── config/           # editor core — load before plugins
    │   ├── options.lua   # statusline-related options (expand later)
    │   └── lazy.lua      # bootstrap lazy.nvim + import plugins/
    └── plugins/          # one plugin (or small family) per file
        ├── init.lua      # empty list; keeps `import = "plugins"` valid
        ├── statusline.lua
        └── git.lua
```
