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
│   │   ├── project.md     # multi-ecosystem scaffolds + task runner
│   │   ├── markdown.md    # inline render + side preview
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
├── queries/
│   └── apex/
│       └── rainbow-delimiters.scm # missing upstream Apex rainbow query
└── lua/
    ├── config/           # editor core — load before plugins
    │   ├── options.lua   # everyday editing options
    │   ├── keymaps.lua   # non-plugin maps (buffers, windows, diagnostics, …)
    │   ├── project_scaffold.lua # CLI-backed new-project picker
    │   ├── project_runner.lua # project-aware run / build / test terminal
    │   ├── project_context.lua # lightweight Salesforce root gate
    │   ├── gremlins.lua  # invisible/confusable Unicode diagnostics
    │   ├── autocmds.lua  # yank, trim, final newline (Apex exempt), filetypes
    │   ├── winbar.lua    # non-overlapping file + LSP context row
    │   ├── lazy.lua      # bootstrap lazy.nvim + import plugins/
    │   ├── telescope/
    │   │   └── multigrep.lua # content grep + raw file-glob mode
    │   └── salesforce/
    │       ├── process.lua # shared safe CLI/SFTerm/cancellation helpers
    │       ├── metadata.lua # org inventory, sf_cache, manifests, actions
    │       ├── browser.lua # fzf metadata hierarchy + multi-select
    │       ├── manifests.lua # search/retrieve/deploy project manifests
    │       ├── vlocity.lua # managed-package DataPack retrieval
    │       ├── schema.lua # org-scoped SObject describe cache
    │       ├── completion.lua # Blink SOQL completion source
    │       └── query.lua # SOQL builder and SFTerm runner
    └── plugins/          # one plugin (or small family) per file
        ├── init.lua      # empty list; keeps `import = "plugins"` valid
        ├── colorscheme.lua # default Noctis + retained background/alternates
        ├── statusline.lua  # ordered dark bubble footer
        ├── bufferline.lua # matching buffer bar (not tabpages)
        ├── cursor.lua     # calm smear animation across buffers/windows
        ├── explorer.lua  # filesystem-only neo-tree
        ├── markdown.lua  # rendered Markdown + side preview
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
        ├── breadcrumbs.lua # disabled Dropbar alternate
        ├── git.lua       # gitsigns signs + hunk keymaps
        └── which-key.lua # leader popup / group labels
```

## Quick start

1. Install host tools from [docs/TOOLS.md](docs/TOOLS.md) (Neovim **0.12+**, Git, a Nerd Font, **`rg` + `fd`**, **tree-sitter CLI** + C compiler; **JDK** if you edit Apex; **`sf` CLI** for Salesforce projects).
2. Point Neovim at this config (symlink, `NVIM_APPNAME`, or clone as your `~/.config/nvim`).
3. Open Neovim once — lazy.nvim bootstraps and installs plugins from `lazy-lock.json` (Treesitter/Mason may download on first use).
4. Skim [docs/keymaps/](docs/keymaps/README.md) — `<leader>sf` / project `<leader>pn`/`pr` / `<leader>cf` / `gd` / neo-tree `<leader>fe` / Salesforce `<leader>S`.
