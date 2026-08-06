# External tools

Things outside this repo that make the config work well. Install on the **host** (your machine / terminal), not inside the Neovim config tree.

| Doc | Purpose |
| --- | --- |
| [keymaps/](./keymaps/README.md) | Shortcuts this config defines (split by topic) |
| [COMMITIZEN.md](./COMMITIZEN.md) | Optional conventional-commit helper (`cz`) |

---

## Required for a good experience

| Tool | Why | Check | Install (examples) |
| --- | --- | --- | --- |
| **Neovim** 0.12+ | Treesitter `main` + modern APIs; older Nvim needs frozen treesitter `master` | `nvim --version` | [neovim.io](https://neovim.io/) / `brew install neovim` |
| **Git** | lazy.nvim bootstrap, gitsigns, lockfile | `git --version` | OS package manager |
| **Nerd Font** (patched) | Statusline / gitsigns glyphs (`vim.g.have_nerd_font = true`) | Glyphs render in the terminal | [nerdfonts.com](https://www.nerdfonts.com/) — set that font in the terminal app |

If you skip a Nerd Font, set `vim.g.have_nerd_font = false` in `init.lua` and prefer the ASCII gitsigns block in `lua/plugins/git.lua`.

---

## Strongly recommended (Telescope / Treesitter)

| Tool | Why | Check | Install (examples) |
| --- | --- | --- | --- |
| **ripgrep** (`rg`) | Telescope live grep (`<leader>sg`, `<leader>sw`) | `rg --version` | `brew install ripgrep` |
| **fd** | Telescope find files (`<leader>sf`) when available | `fd --version` | `brew install fd` |
| **make** | Builds `telescope-fzf-native` (faster sorter); optional | `make --version` | Xcode CLT / `brew install make` |
| **tree-sitter CLI** | Compiles parsers for `nvim-treesitter` (`main`) | `tree-sitter --version` | `brew install tree-sitter` (need **0.26.1+**) |
| **C compiler** | Builds tree-sitter parser `.so` files | `clang --version` / `gcc --version` | Xcode CLT |

Without `rg` / `fd`, some Telescope pickers fall back to slower builtins or fail — install both.
Without `tree-sitter` + a C compiler, `:TSUpdate` / parser install will fail.

---

## Optional

| Tool | Why | Doc |
| --- | --- | --- |
| **Commitizen** (`cz`) | Interactive conventional commits | [COMMITIZEN.md](./COMMITIZEN.md) |
| **lazygit** | Full-screen Git TUI (not wired yet) | [jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |
| **Java (JDK)** | Apex language server (`apex_ls`) runs on the JVM | `java -version` / `brew install openjdk` |
| **Node.js** | Some Mason LSPs / prettierd | `node --version` |

---

## Config ↔ tools map

| Config area | Relies on |
| --- | --- |
| `lua/config/lazy.lua` | `git`, network (first clone of lazy.nvim) |
| `lua/plugins/statusline.lua` | Nerd Font (icons) when `have_nerd_font` |
| `lua/plugins/git.lua` | `git` repo + Nerd Font signs (or ASCII fallback) |
| `lua/plugins/explorer.lua` | Nerd Font icons (optional) |
| `lua/plugins/telescope.lua` | `rg`, `fd`; optional `make` for fzf-native |
| `lua/plugins/treesitter.lua` | Neovim 0.12+, `tree-sitter` CLI 0.26.1+, C compiler |
| `lua/plugins/indent.lua` | (none beyond Neovim) |
| `lua/plugins/autopairs.lua` | Treesitter optional (`check_ts`) |
| `lua/plugins/lsp.lua` | network (Mason), JDK for Apex; `:Mason` for on-demand servers |
| `lua/plugins/formatting.lua` | Mason formatters (`stylua` auto; others as needed) |
| `lua/plugins/completion.lua` | optional `make` for LuaSnip jsregexp |
