# External tools

Things outside this repo that make the config work well. Install on the **host** (your machine / terminal), not inside the Neovim config tree.

| Doc | Purpose |
| --- | --- |
| [KEYMAPS.md](./KEYMAPS.md) | Shortcuts this config defines |
| [COMMITIZEN.md](./COMMITIZEN.md) | Optional conventional-commit helper (`cz`) |

---

## Required for a good experience

| Tool | Why | Check | Install (examples) |
| --- | --- | --- | --- |
| **Neovim** 0.10+ | This config targets modern APIs (`smoothscroll`, etc.) | `nvim --version` | [neovim.io](https://neovim.io/) / `brew install neovim` |
| **Git** | lazy.nvim bootstrap, gitsigns, lockfile | `git --version` | OS package manager |
| **Nerd Font** (patched) | Statusline / gitsigns glyphs (`vim.g.have_nerd_font = true`) | Glyphs render in the terminal | [nerdfonts.com](https://www.nerdfonts.com/) — set that font in the terminal app |

If you skip a Nerd Font, set `vim.g.have_nerd_font = false` in `init.lua` and prefer the ASCII gitsigns block in `lua/plugins/git.lua`.

---

## Strongly recommended (search / pickers later)

Install these early even before Telescope/fzf — many plugins shell out to them.

| Tool | Why | Check | Install (examples) |
| --- | --- | --- | --- |
| **ripgrep** (`rg`) | Fast project search (Telescope / future grep) | `rg --version` | `brew install ripgrep` |
| **fd** | Fast file find (Telescope / future finders) | `fd --version` | `brew install fd` |
| **tree-sitter CLI** | Optional; helps when debugging / installing parsers | `tree-sitter --version` | `brew install tree-sitter` |

---

## Optional

| Tool | Why | Doc |
| --- | --- | --- |
| **Commitizen** (`cz`) | Interactive conventional commits | [COMMITIZEN.md](./COMMITIZEN.md) |
| **lazygit** | Full-screen Git TUI (not wired yet) | [jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |

---

## Config ↔ tools map

| Config area | Relies on |
| --- | --- |
| `lua/config/lazy.lua` | `git`, network (first clone of lazy.nvim) |
| `lua/plugins/statusline.lua` | Nerd Font (icons) when `have_nerd_font` |
| `lua/plugins/git.lua` | `git` repo + Nerd Font signs (or ASCII fallback) |
| Future: Telescope / fzf | `rg`, `fd` |
| Future: Treesitter | parsers (and optionally tree-sitter CLI) |
