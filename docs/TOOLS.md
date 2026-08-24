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

## Noctis screenshot-style typography (free setup)

The original screenshot used Hasklig regular text with commercial Cartograph italics. The free practical replacement is:

- Regular/bold: [Cascadia Code](https://github.com/microsoft/cascadia-code/releases) — already installed on the current hosts
- Cursive italic/bold-italic: [Victor Mono](https://rubjo.github.io/victor-mono/) — free under the [SIL Open Font License](https://github.com/rubjo/victor-mono/blob/master/LICENSE)

Victor Mono provides the flowing cursive italics needed by the active Noctis typography. Neovim only emits `bold` / `italic` attributes; the terminal chooses these font faces.

For statusline icons, use the patched families **CaskaydiaCove Nerd Font Mono** and **VictorMono Nerd Font Mono**:

```sh
# macOS
brew install --cask font-caskaydia-cove-nerd-font font-victor-mono-nerd-font

# Arch Linux
sudo pacman -S ttf-cascadia-code-nerd ttf-victor-mono-nerd
```

Other Linux distributions can download `CascadiaCode` and `VictorMono` archives from [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases), copy the font files into `~/.local/share/fonts`, then refresh the cache:

```sh
fc-cache -fv
fc-list : family style | rg -i 'Cascadia|Caskaydia|Victor'
```

### Alacritty (recommended mixed-family setup)

Alacritty supports separate families per style. In `alacritty.toml`, use the family names reported by `fc-list`:

```toml
[font.normal]
family = "CaskaydiaCove Nerd Font Mono"
style = "Regular"

[font.bold]
family = "CaskaydiaCove Nerd Font Mono"
style = "Bold"

[font.italic]
family = "VictorMono Nerd Font Mono"
style = "Italic"

[font.bold_italic]
family = "VictorMono Nerd Font Mono"
style = "Bold Italic"
```

Use `family = "Cascadia Code"` for normal/bold if the existing unpatched installation already gets Nerd glyphs through font fallback.

### iTerm2 (macOS)

iTerm2 selects one ASCII family and automatically uses that same family’s italic face; it cannot combine Cascadia regular with Victor italic.

1. Open **Settings → Profiles → Text**.
2. Select **VictorMono Nerd Font Mono** for the closest free all-in-one cursive result, or keep **Cascadia Code** when its regular design is more important.
3. Enable **Draw italic text in italic font**.
4. Optionally set **Non-ASCII Font** to **CaskaydiaCove Nerd Font Mono** for private-use glyphs.

### Konsole (Linux)

Konsole also selects one primary family rather than separate regular/italic families. Under **Settings → Edit Current Profile → Appearance → Font**, choose:

- **VictorMono Nerd Font Mono** for cursive italics and icons, or
- **CaskaydiaCove Nerd Font Mono** to retain Cascadia’s design.

Use Alacritty for the exact Cascadia-regular/Victor-italic pairing.

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
| **Vlocity Build Tool** | Managed-package DataPack retrieval (`<leader>SV`) | `vlocity --version` | Node 18+ · `npm install --global vlocity` |
| **universal-ctags** | Optional Apex jump enhancement (`<leader>Sc`) | `ctags --version` | `brew install universal-ctags` · `sudo pacman -S ctags` |

---

## Project generators

`<leader>pn` only needs the CLI for the project type you select. `<leader>pr` needs the detected project’s CLI. Neovim checks executables before starting work.

| Project type | Tools | Check | Install |
| --- | --- | --- | --- |
| **Java — Maven** | JDK + Maven | `java -version` · `mvn --version` | `brew install openjdk maven` · `sudo pacman -S jdk-openjdk maven` |
| **Flutter app** | Flutter SDK | `flutter --version` | [Official Flutter installation](https://docs.flutter.dev/get-started/install) |
| **C++ — CMake** | CMake + `cmake-init` 0.41+ | `cmake --version` · `cmake-init --version` | CMake: `brew install cmake` · `sudo pacman -S cmake`; generator: `pipx install cmake-init` |
| **Rust** | Rust toolchain + Cargo | `cargo --version` | [rustup](https://rustup.rs/) · install `rustup`, then run `rustup default stable` |
| **Node / Vite TypeScript** | Node.js + npm (Vite needs Node 20.19+ or 22.12+) | `node --version` · `npm --version` | `brew install node` · `sudo pacman -S nodejs npm` |
| **Python** | `uv` | `uv --version` | `brew install uv` · `sudo pacman -S uv` · [uv installation](https://docs.astral.sh/uv/getting-started/installation/) |
| **Go** | Go toolchain | `go version` | `brew install go` · `sudo pacman -S go` |

For an isolated `cmake-init` install, install `pipx` first with `brew install pipx` or `sudo pacman -S python-pipx`.

---

## Config ↔ tools map

| Config area | Relies on |
| --- | --- |
| `lua/config/lazy.lua` | `git`, network (first clone of lazy.nvim) |
| `lua/plugins/statusline.lua` | Nerd Font icons; optional Cascadia/Victor terminal pairing above; SF org once sf.nvim loaded |
| `lua/plugins/git.lua` | `git` repo + Nerd Font signs (or ASCII fallback) |
| `lua/plugins/lazygit.lua` | host **`lazygit`** (`brew` / `pacman`) |
| `lua/plugins/persistence.lua` | (none beyond Neovim state dir) |
| `lua/plugins/trouble.lua` | (none) |
| `lua/plugins/surround.lua` | (none) |
| `lua/plugins/flash.lua` | (none) |
| `lua/plugins/undotree.lua` | `undofile` on (already in `options.lua`) |
| `lua/plugins/yanky.lua` | (none; uses ShaDa for ring) |
| `lua/plugins/dial.lua` | (none) |
| `lua/plugins/rainbow.lua` | treesitter parsers for the language |
| `lua/plugins/colorizer.lua` | (none) |
| `lua/plugins/explorer.lua` | Nerd Font icons (optional) |
| `lua/plugins/markdown.lua` | no external runtime; existing Treesitter Markdown parsers |
| `lua/plugins/telescope.lua` | `rg`, `fd`; optional `make` for fzf-native |
| `lua/plugins/treesitter.lua` | Neovim 0.12+, `tree-sitter` CLI 0.26.1+, C compiler |
| `lua/plugins/indent.lua` | (none beyond Neovim) |
| `lua/plugins/autopairs.lua` | Treesitter optional (`check_ts`) |
| `lua/plugins/lsp.lua` | network (Mason), JDK for Apex; `:Mason` for on-demand servers |
| `lua/plugins/formatting.lua` | Mason formatters (`stylua` + `prettierd` auto; others as needed); FoS allowlist |
| `lua/plugins/linting.lua` | Mason linters lazy-by-ft (`eslint_d`, `ruff`, …); skip until binary on PATH; npm `min-release-age` can block installs — [quiet.md](./diagnostics/quiet.md#example-no-eslint-diagnostics--mason-eslint_d-failed) |
| `lua/plugins/completion.lua` | optional `make` for LuaSnip jsregexp |
| `lua/plugins/salesforce.lua` | `sf` CLI; host **`fzf`**; `curl` for Apex SObject stubs; npm `vlocity` for managed-package DataPacks; optional ctags |
| `lua/config/salesforce/schema.lua` | `sf sobject list/describe`; no separate SOQL language server |
| `lua/config/gremlins.lua` | (none; native Neovim diagnostics) |
| `lua/config/project_scaffold.lua` | per-generator CLI: `mvn`, `flutter`, `cmake-init`, `cargo`, `npm`, `uv`, or `go` |
| `lua/config/project_runner.lua` | detected project CLI; shell + native terminal for live task output |
