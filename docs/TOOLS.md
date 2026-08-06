# External tools

Things outside this repo that make the config work well. Install on the **host** (your machine / terminal), not inside the Neovim config tree.

**Hosts:** macOS (**Homebrew**) and Arch Linux (**pacman**). Commands below list both where a package exists.

| Doc | Purpose |
| --- | --- |
| [keymaps/](./keymaps/README.md) | Shortcuts this config defines (split by topic) |
| [diagnostics/](./diagnostics/README.md) | Where diagnostics show, settings, Java FAQ + [example](./examples/java-maven-minimal/) |
| [COMMITIZEN.md](./COMMITIZEN.md) | Optional conventional-commit helper (`cz`) |

---

## Required for a good experience

| Tool | Why | Check | Install |
| --- | --- | --- | --- |
| **Neovim** 0.12+ | Treesitter `main` + modern APIs; older Nvim needs frozen treesitter `master` | `nvim --version` | `brew install neovim` · `sudo pacman -S neovim` · or [neovim.io](https://neovim.io/) |
| **Git** | lazy.nvim bootstrap, gitsigns, lockfile | `git --version` | `brew install git` · `sudo pacman -S git` |
| **Nerd Font** (patched) | Statusline / gitsigns glyphs (`vim.g.have_nerd_font = true`) | Glyphs render in the terminal | [nerdfonts.com](https://www.nerdfonts.com/) — set that font in the terminal app (`brew install --cask font-jetbrains-mono-nerd-font` is one option) |

If you skip a Nerd Font, set `vim.g.have_nerd_font = false` in `init.lua` and prefer the ASCII gitsigns block in `lua/plugins/git.lua`.

---

## Strongly recommended (Telescope / Treesitter / Salesforce pickers)

| Tool | Why | Check | Install |
| --- | --- | --- | --- |
| **ripgrep** (`rg`) | Telescope live grep (`<leader>sg`, `<leader>sw`) | `rg --version` | `brew install ripgrep` · `sudo pacman -S ripgrep` |
| **fd** | Telescope find files (`<leader>sf`) when available | `fd --version` | `brew install fd` · `sudo pacman -S fd` |
| **fzf** | **fzf-lua** binary (sf.nvim metadata lists `<leader>Sm` / `Sk`) | `fzf --version` | `brew install fzf` · `sudo pacman -S fzf` |
| **make** | Builds `telescope-fzf-native` (faster sorter); optional | `make --version` | Xcode CLT / `brew install make` · `sudo pacman -S make` (or `base-devel`) |
| **tree-sitter CLI** | Compiles parsers for `nvim-treesitter` (`main`) | `tree-sitter --version` | `brew install tree-sitter` · `sudo pacman -S tree-sitter` (need **0.26.1+**) |
| **C compiler** | Builds tree-sitter parser `.so` files | `clang --version` / `gcc --version` | Xcode CLT · `sudo pacman -S base-devel` (or `clang`) |
| **curl** | sf.nvim SObject refresh (`<leader>Ss`) talks to the org API | `curl --version` | `brew install curl` · `sudo pacman -S curl` (usually preinstalled) |

Without `rg` / `fd`, some Telescope pickers fall back to slower builtins or fail — install both.  
Without **`fzf`**, fzf-lua aborts (`'fzf' is not a valid executable`) — Salesforce metadata pickers won’t open.  
Without `tree-sitter` + a C compiler, `:TSUpdate` / parser install will fail.

> Note: **Telescope** uses `telescope-fzf-native` (compiled C sorter) — that is *not* the `fzf` binary. **sf.nvim** / **fzf-lua** *do* need the host `fzf` executable.

---

## Optional

| Tool | Why | Check | Install |
| --- | --- | --- | --- |
| **Commitizen** (`cz`) | Interactive conventional commits | [COMMITIZEN.md](./COMMITIZEN.md) | `npm i -g commitizen` (same on both; see that doc) |
| **lazygit** | Full-screen Git TUI (`<leader>gg` / `gf`) | `lazygit --version` | `brew install lazygit` · `sudo pacman -S lazygit` · [upstream](https://github.com/jesseduffield/lazygit) |
| **Java (JDK)** | `apex_ls` / `jdtls` on the JVM | `java -version` | `brew install openjdk` · `sudo pacman -S jdk-openjdk` |
| **Node.js** | Some Mason LSPs / prettierd / optional `sf` install path | `node --version` | `brew install node` · `sudo pacman -S nodejs npm` |
| **Salesforce CLI (`sf`)** | `sf.nvim` org/deploy/test/metadata | `sf --version` | [CLI setup](https://developer.salesforce.com/tools/salesforcecli) (npm / installer; not a brew/pacman first-class package on all hosts) |
| **universal-ctags** | Optional Apex jump enhancement (`<leader>Sc`) | `ctags --version` | `brew install universal-ctags` · `sudo pacman -S ctags` |

---

## Config ↔ tools map

| Config area | Relies on |
| --- | --- |
| `lua/config/lazy.lua` | `git`, network (first clone of lazy.nvim) |
| `lua/plugins/statusline.lua` | Nerd Font (icons) when `have_nerd_font` |
| `lua/plugins/git.lua` | `git` repo + Nerd Font signs (or ASCII fallback) |
| `lua/plugins/lazygit.lua` | host **`lazygit`** (`brew` / `pacman`) |
| `lua/plugins/explorer.lua` | Nerd Font icons (optional) |
| `lua/plugins/telescope.lua` | `rg`, `fd`; optional `make` for fzf-native |
| `lua/plugins/treesitter.lua` | Neovim 0.12+, `tree-sitter` CLI 0.26.1+, C compiler |
| `lua/plugins/indent.lua` | (none beyond Neovim) |
| `lua/plugins/autopairs.lua` | Treesitter optional (`check_ts`) |
| `lua/plugins/lsp.lua` | network (Mason), JDK for Apex; `:Mason` for on-demand servers |
| `lua/plugins/formatting.lua` | Mason formatters (`stylua` + `prettierd` auto; others as needed); FoS allowlist |
| `lua/plugins/linting.lua` | Mason linters lazy-by-ft (`eslint_d`, `ruff`, …); skip until binary on PATH; npm `min-release-age` can block installs — [quiet.md](./diagnostics/quiet.md#example-no-eslint-diagnostics--mason-eslint_d-failed) |
| `lua/plugins/completion.lua` | optional `make` for LuaSnip jsregexp |
| `lua/plugins/salesforce.lua` | `sf` CLI; host **`fzf`** (fzf-lua); `curl` for SObject refresh; optional ctags |
