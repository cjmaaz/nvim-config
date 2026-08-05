# nvim-config

```text
nvim-config/
├── docs/                 # project notes
├── init.lua              # entry: loader, leaders, require config.*
└── lua/
    ├── config/           # editor core — load before plugins
    │   ├── options.lua   # statusline-related options (expand later)
    │   └── lazy.lua      # bootstrap lazy.nvim + import plugins/
    └── plugins/          # one plugin (or small family) per file
        └── init.lua      # empty spec list until plugins are added
```
