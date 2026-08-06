# Salesforce (sf.nvim)

Org, retrieve/deploy, Apex tests/coverage, metadata list, and SF terminal — via Salesforce CLI.

Plugin: `lua/plugins/salesforce.lua`. Language intelligence stays in [lsp.md](./lsp.md) (`apex_ls`).

**Host:** `sf` CLI (`sf --version`) — [TOOLS.md](../TOOLS.md).  
**Project:** cwd or file under a folder with `sfdx-project.json` or `.forceignore`.  
**Check:** `:check sf` · `:lua require("sf.util").get_sf_root()`

Nav: [index](./README.md) · [lsp](./lsp.md) · [which-key](./which-key.md) · [telescope](./telescope.md)

---

## Discover maps

`<leader>` is **Space**. Press **`Space` then `S`** (capital **S**), wait ~300ms — which-key shows the **Salesforce** group.

Search stays on lowercase `<leader>s…` (Telescope).

Also: `:SF` then Tab for command categories.

---

## Keymaps

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>SF` | n | Fetch / refresh authenticated orgs (`:SF org fetchList`) |
| `<leader>So` | n | Set **target** org (local) — run `<leader>SF` first |
| `<leader>SO` | n | Set **global** target org — run `<leader>SF` first |
| `<leader>Sb` | n | Open target org in browser |
| `<leader>SB` | n | Open current metadata in org |
| `<leader>Sr` | n | Retrieve current file from org |
| `<leader>Sp` | n | **Save and deploy** current file |
| `<leader>Sx` | n | **Cancel** running SF command (deploy/test/…) |
| `<leader>Sd` | n | Diff current file vs target org |
| `<leader>Sl` | n | Pull debug log |
| `<leader>Se` | n | Toggle sf.nvim terminal |
| `<leader>St` | n | Run test under cursor |
| `<leader>ST` | n | Test under cursor **with coverage** |
| `<leader>Sa` | n | All tests in this file |
| `<leader>SA` | n | All tests in file **with coverage** |
| `<leader>SR` | n | Repeat last tests |
| `<leader>Sv` | n | Toggle coverage signs |
| `]v` / `[v` | n | Next / previous uncovered line |
| `<leader>Sq` | x | Run **visual** selection as SOQL |
| `<leader>SM` | n | Pull metadata inventory JSON |
| `<leader>Sm` | n | List metadata to retrieve (fzf-lua) |
| `<leader>SK` | n | Pull metadata **types** JSON |
| `<leader>Sk` | n | List metadata types (fzf-lua) |
| `<leader>Ss` | n | Refresh SObject definitions (helps `apex_ls`) |
| `<leader>Sc` | n | Create Apex ctags (needs `universal-ctags`) |

---

## Notes

- **Org flow:** `<leader>SF` (fetch) → then `<leader>So` / `SO` (pick target). Upstream’s “No orgs…” error wrongly says `:SF org list`; the real command is **`:SF org fetchList`** / `<leader>SF`.
- **fzf-lua** is installed for metadata pickers only; everyday file search remains **Telescope** (`<leader>sf` / `sg`). Needs host **`fzf`** (`brew install fzf` · `sudo pacman -S fzf`) — see [TOOLS.md](../TOOLS.md).
- Coverage signs appear after a **coverage** test run (`ST` / `SA`) when `auto_display_code_sign` is on.
- Cancel (`<leader>Sx`) aborts the in-flight sf.nvim terminal job (deploy, retrieve, tests, …).
- Optional statusline: `require("sf").get_target_org()` / `covered_percent()` — not wired in lualine yet.
- Custom objects / `__mdt` “Invalid type” in `apex_ls`: set target org, then `<leader>Ss` (needs `curl`) to refresh SObject stubs under `.sfdx/tools/sobjects/`.

Nav: [index](./README.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
