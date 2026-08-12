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
| `<leader>SP` | n | Search package manifests under `manifest/` and its subdirectories |
| `<leader>Ss` | n | Refresh SObject definitions (helps `apex_ls`) |
| `<leader>Sc` | n | Create Apex ctags (needs `universal-ctags`) |

---

## Metadata browser (`<leader>Su`)

Inventory is project-local under `sf_cache/`. `SF` and `So` automatically refresh the same configured common types as `SM`; `SU` lets you choose **Common** or **All enabled types**. The All path can take several minutes and also traverses Report, Dashboard, Document, and EmailTemplate folders.

The browser uses three panes: focused-item audit details across the upper-left, searchable results below, and live selected-item summaries on the right. Member details include creator/date, modifier/date, metadata ID, file, namespace, and manageable state; category details show descriptor/cache fields. A selected category appears once in the right pane as `Type — all N cached members` with a distinct color rather than listing every child.

Categories start collapsed. Expand only the types you need; cached categories reload in place so the query and cursor stay put. Their members render as `Type / folder / member`, so fzf patterns can match any level. A query ending at `Type /` keeps that category row first for quick collapse or selection. On narrow windows/fullscreen, the right pane hides cleanly while details and results remain usable.

| Key | macOS key | Action |
| --- | --- | --- |
| `<Tab>` | `Tab` | Toggle the current member or an entire category |
| `<C-a>` | `⌃A` (Control-A) | Toggle all filtered entries |
| `<C-e>` | `⌃E` (Control-E) | Expand / collapse the current category; uncached categories fetch first |
| `<CR>` | `Return` | Retrieve selected members; a selected category retrieves all its cached members |
| `<C-g>` | `⌃G` (Control-G) | Generate `package.xml` from selected members/categories |
| `<C-d>` | `⌃D` (Control-D) | Deploy matching local metadata after confirmation |
| `<C-x>` | `⌃X` (Control-X) | Remote-only delete: dry-run, typed `DELETE`, then final confirmation |
| `<C-u>` | `⌃U` (Control-U) | Refresh the current metadata type |

On macOS, `<C-…>` means **Control (`⌃`)**, not Command (`⌘`). Terminal applications generally intercept Command themselves and do not send it to Neovim, so these browser actions use portable Control keys.

The in-picker two-line header uses compact caret notation (`^G` = `Ctrl-G`, `^E` = `Ctrl-E`, etc.) to avoid truncation on narrower windows.

Category-wide selection applies to retrieval and package generation. Deploy and remote delete intentionally require explicit member selections. Deploy never adds ignore-conflict/error/warning flags automatically. Remote delete uses temporary `package.xml` / `destructiveChangesPost.xml` files below `sf_cache/metadata-browser/`, preserves local source, and does not purge the org recycle bin.

`Ctrl-G` prompts for a filename, strips a supplied `.xml` suffix, and writes `manifest/shard/<name>_YYYYMMDD_HHMMSS.xml` using the project API version. Empty names, path traversal, and separators are rejected.

`sf_cache/` is generated project data. Add it to each Salesforce project’s `.gitignore`; this config deliberately does not modify arbitrary project repositories.

---

## Package manifest picker (`<leader>SP`)

Opens a single-select fzf search over XML files anywhere beneath `manifest/` (including `manifest/shard/` and other subdirectories), with the manifest content in the preview.

| Key | macOS key | Action |
| --- | --- | --- |
| `<CR>` | `Return` | Retrieve the selected manifest from the target org |
| `<C-d>` | `⌃D` (Control-D) | Confirm, then deploy the selected manifest to the target org |

Both actions run in SFTerm. Toggle the float with `<leader>Se`; cancel with `Esc` or focus-independent `<leader>Sx`.

---

## Notes

- **Org flow:** `<leader>SF` refreshes orgs and common metadata for the CLI-default target. `<leader>So` selects a local target and then refreshes common metadata. `<leader>SO` changes only the global target.
- **SFTerm** (float after deploy/retrieve/metadata): stays open so you can read output. `<leader>Se` toggles it; focused `q` also hides it. `Esc` is a cancel key, not a visibility toggle.
- **Cancel:** `Esc` and `<leader>Sx` send Ctrl-C to running SFTerm channels and stop background inventory processes without requiring `<C-w>w`, whether the float is focused, unfocused, hidden, or absent. With nothing running, normal-mode `Esc` still clears search highlighting. Focused terminal-mode `<C-c>` remains native. Cancellation is best-effort after Salesforce has accepted a server-side deploy job.
- **fzf-lua** is installed for metadata pickers only; everyday file search remains **Telescope** (`<leader>sf` / `sg`). Needs host **`fzf`** (`brew install fzf` · `sudo pacman -S fzf`) — see [TOOLS.md](../TOOLS.md).
- Coverage signs appear after a **coverage** test run (`ST` / `SA`) when `auto_display_code_sign` is on.
- Optional statusline: target org + coverage appear in lualine once `sf.nvim` is loaded (`statusline.lua` / CodeOSS-style).
- Custom objects / `__mdt` “Invalid type” in `apex_ls`: set target org, then `<leader>Ss` (needs `curl`) to refresh SObject stubs under `.sfdx/tools/sobjects/`.
- **Note:** modern `sf org display --json` **redacts** `accessToken`. Upstream sf.nvim still feeds that into curl → HTTP 401 on `<leader>Ss` even when retrieve/deploy work. `salesforce.lua` wraps `vim.system` and splices a real token from `sf org auth show-access-token` (config-side; survives `:Lazy sync`).

Nav: [index](./README.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
