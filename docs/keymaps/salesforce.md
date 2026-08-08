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
| `<leader>SF` | n | Fetch authenticated orgs, resolve the default target, then refresh common metadata |
| `<leader>So` | n | Set the **local target** org, then refresh common metadata |
| `<leader>SO` | n | Set the **global target** org (no automatic metadata refresh) |
| `<leader>Sb` | n | Open target org in browser |
| `<leader>SB` | n | Open current metadata in org |
| `<leader>Sr` | n | Retrieve current file from org |
| `<leader>Sp` | n | **Save and deploy** current file |
| `<leader>Sx` | n | **Cancel** active SF terminal/background actions, even when their float is unfocused/hidden |
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
| `<leader>Su` | n | Open the cached multi-select metadata browser |
| `<leader>SU` | n | Update **Common** or **All** metadata inventory |
| `<leader>Ss` | n | Refresh SObject definitions (helps `apex_ls`) |
| `<leader>Sc` | n | Create Apex ctags (needs `universal-ctags`) |

---

## Metadata browser (`<leader>Su`)

Inventory is project-local under `sf_cache/`. `SF` and `So` automatically refresh the same configured common types as `SM`; `SU` lets you choose **Common** or **All enabled types**. The All path can take several minutes and also traverses Report, Dashboard, Document, and EmailTemplate folders.

The browser renders paths as `Type / folder / member`, so fzf patterns can match any level. Selected entries appear in the preview above the filter.

| Key | macOS key | Action |
| --- | --- | --- |
| `<Tab>` | `Tab` | Toggle the current metadata member |
| `<Alt-a>` | `⌥A` (Option-A) | Toggle all filtered entries |
| `<CR>` | `Return` | Retrieve selected members; on an uncached type row, fetch that type |
| `<Alt-d>` | `⌥D` (Option-D) | Deploy matching local metadata after confirmation |
| `<Alt-x>` | `⌥X` (Option-X) | Remote-only delete: dry-run, typed `DELETE`, then final confirmation |
| `<Alt-u>` | `⌥U` (Option-U) | Refresh the current metadata type |

On macOS, **Alt = Option (`⌥`)**. Control is `⌃` / `^`, which is different. Your terminal must send Option as **Alt/Meta (Esc+)**; otherwise Option-letter may insert symbols such as `∂` instead of triggering these actions.

Deploy never adds ignore-conflict/error/warning flags automatically. Remote delete uses temporary `package.xml` / `destructiveChangesPost.xml` files below `sf_cache/metadata-browser/`, preserves local source, and does not purge the org recycle bin.

`sf_cache/` is generated project data. Add it to each Salesforce project’s `.gitignore`; this config deliberately does not modify arbitrary project repositories.

---

## Notes

- **Org flow:** `<leader>SF` refreshes orgs and common metadata for the CLI-default target. `<leader>So` selects a local target and then refreshes common metadata. `<leader>SO` changes only the global target.
- **SFTerm** (float after deploy/retrieve/metadata): stays open so you can read output. **`Esc`** hides it even when focus was restored to the source window; focused `q` and `<leader>Se` also hide it. The job keeps running and the float may reappear when it finishes.
- **Cancel:** `<leader>Sx` sends Ctrl-C to running SFTerm channels and stops background inventory processes without requiring `<C-w>w`. Focused terminal-mode `<C-c>` remains native. Cancellation is best-effort after Salesforce has accepted a server-side deploy job.
- **fzf-lua** is installed for metadata pickers only; everyday file search remains **Telescope** (`<leader>sf` / `sg`). Needs host **`fzf`** (`brew install fzf` · `sudo pacman -S fzf`) — see [TOOLS.md](../TOOLS.md).
- Coverage signs appear after a **coverage** test run (`ST` / `SA`) when `auto_display_code_sign` is on.
- Optional statusline: target org + coverage appear in lualine once `sf.nvim` is loaded (`statusline.lua` / CodeOSS-style).
- Custom objects / `__mdt` “Invalid type” in `apex_ls`: set target org, then `<leader>Ss` (needs `curl`) to refresh SObject stubs under `.sfdx/tools/sobjects/`.
- **Note:** modern `sf org display --json` **redacts** `accessToken`. Upstream sf.nvim still feeds that into curl → HTTP 401 on `<leader>Ss` even when retrieve/deploy work. `salesforce.lua` wraps `vim.system` and splices a real token from `sf org auth show-access-token` (config-side; survives `:Lazy sync`).

Nav: [index](./README.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
