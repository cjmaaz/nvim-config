# nvim-config

```text
nvim-config/
├── docs/                 # project notes
├── init.lua              # tiny entry: require bootstrap only (planned)
└── lua/
    ├── config/           # editor core — load before plugins (planned)
    │   ├── options/      # or a single options.lua
    │   ├── keymaps/
    │   ├── autocmds/
    │   └── lazy/         # bootstrap + lazy.setup only
    └── plugins/          # one plugin (or small family) per file
```
