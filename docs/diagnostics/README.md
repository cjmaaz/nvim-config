# Diagnostics

How Neovim shows problems from **LSP** and **linters** (`nvim-lint`), which settings control each surface, and how to quiet noise.

Config: `lua/config/keymaps.lua` (`vim.diagnostic.config` + jump maps).

**Also:** [TOOLS.md](../TOOLS.md) · [keymaps/](../keymaps/README.md) · [repo README](../../README.md)

---

## Index

| Topic | File |
| --- | --- |
| Where diagnostics appear + settings | [display.md](./display.md) |
| Severity, hide, suppress, filters | [quiet.md](./quiet.md) |
| Mason `eslint_d` / `~/.npmrc` `min-release-age` | [quiet.md § example](./quiet.md#example-no-eslint-diagnostics--mason-eslint_d-failed) |
| Java / `jdtls` “non-project file” | [java.md](./java.md) |
| Minimal Maven example (copy or open) | [../examples/java-maven-minimal/](../examples/java-maven-minimal/) |

---

## Quick keys (this config)

| Key | Action |
| --- | --- |
| `]d` / `[d` | Next / previous (opens a float on jump) |
| `<leader>e` | Float at cursor |
| `<leader>xx` | Trouble diagnostics panel |
| `<leader>xl` | Location list in Trouble (`<leader>q…` is session management) |
| `<leader>sd` | Telescope diagnostics |

Defaults today: **signs** + **underline** (WARN+) + **virtual text** (end of line) + float on jump. Colors follow your **colorscheme** (not a fixed “brown”).

---

## Growing these docs

When we add toggles, filters, or `nvim-jdtls`, update the matching page here and the [examples](../examples/) tree if needed.

Nav: [display](./display.md) · [quiet](./quiet.md) · [java](./java.md) · [example](../examples/java-maven-minimal/)
