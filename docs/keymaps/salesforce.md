# Salesforce (sf.nvim)

Org, retrieve/deploy, Apex tests/coverage, managed-package Vlocity, SOQL, metadata lists, and SF terminal.

Plugin: `lua/plugins/salesforce.lua`. Language intelligence stays in [lsp.md](./lsp.md) (`apex_ls`).

**Host:** `sf` CLI (`sf --version`); npm `vlocity` for managed-package DataPacks — [TOOLS.md](../TOOLS.md).
**Project:** cwd or file under a folder with `sfdx-project.json` or `.forceignore`.  
**Check:** `:check sf` · `:lua require("sf.util").get_sf_root()`

Nav: [index](./README.md) · [lsp](./lsp.md) · [which-key](./which-key.md) · [telescope](./telescope.md)

---

## Discover maps

`<leader>` is **Space**. Press **`Space` then `S`** (capital **S**), wait ~300ms — which-key shows the **Salesforce** group.

Search stays on lowercase `<leader>s…` (Telescope). Child labels omit the redundant `SF:` prefix because the group already supplies that context.

Also: `:SF` then Tab for command categories.

---

## Keymaps

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>SF` | n | Run sf.nvim’s default org fetch and adopt the CLI-default target |
| `<leader>So` | n | Set the **local target** org only |
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
| `<leader>SV` | n | Retrieve scoped or full managed-package Vlocity DataPacks |
| `<leader>SQ` | n | Open the schema-aware SOQL builder |
| `<leader>Sq` | n | Save and run the current `.soql` file |
| `<leader>Sq` | x | Run **visual** selection as SOQL |
| `<leader>Sm` | n | Pick cached metadata to retrieve (fzf-lua) |
| `<leader>Su` | n | Open the cached multi-select metadata browser |
| `<leader>SU` | n | Update **Common** or **All** metadata inventory |
| `<leader>SP` | n | Search package manifests under `manifest/` and its subdirectories |
| `<leader>Ss` | n | Refresh SObject definitions (helps `apex_ls`) |
| `<leader>Sc` | n | Create Apex ctags (needs `universal-ctags`) |

---

## Managed-package Vlocity retrieval (`<leader>SV`)

This is Vlocity Build Tool **DataPack** retrieval for managed-package CMT orgs. It is separate from Metadata API OmniStudio types such as `OmniScript`; `sf project retrieve -m Omni*` is not a substitute.

The picker discovers YAML jobs below the Salesforce project’s `vlocity/` directory and prefers `ExportOmni.yaml`. It resolves `node_modules/.bin/vlocity` first, then the npm-global `vlocity` command.

| Mode | Behavior |
| --- | --- |
| **Retrieve one DataPack** | Search cached remote keys plus local `vlocity/Type/Key` folders, refresh the remote key inventory, or enter `Type/Key` manually |
| **Full configured export** | Run the selected job’s `packExport` only after explicit confirmation; warns when local `vlocity/` changes exist |
| **Refresh key inventory** | Run `packGetAllAvailableExports --json` and cache only key/type/label/status fields |

Scoped exports preserve the selected job’s dependency-depth settings. Full export never includes inactive bulk export or cleanup operations. Both exports run in SFTerm; cancel with `Esc` or `<leader>Sx`. Exit status and a newly written `VlocityBuildLog.yaml` are checked, but partial errors still require reviewing the terminal/log.

The inventory cache is org-scoped below `sf_cache/metadata-browser/`. It never stores access tokens, org URLs, record IDs, creator names, or sample DataPack data.

---

## SOQL builder, completion, and runner

`<leader>SQ` selects a queryable SObject, lazily caches its describe data, opens a multi-select field picker, and writes an org-scoped draft below `sf_cache/query-builder/`. Drafts stay outside deployable package directories.

Blink completion in `.soql` buffers uses the disk/memory cache only:

- SObjects after `FROM`;
- fields and relationships in query clauses;
- cached related-object fields after `.`;
- SOQL keywords, functions, operators, and date literals.

Schema cache entries refresh after 24 hours. Network requests happen while opening the builder or explicitly changing an object—not while typing.

Inside the SOQL field picker, `<Tab>` toggles a field and `<CR>` confirms the selection.

| Query-buffer key | Action |
| --- | --- |
| `<localleader>f` (`\f`) | Pick fields and replace the draft’s SELECT list |
| `<localleader>o` (`\o`) | Change SObject / open its draft |
| `<localleader>r` (`\r`) | Save and run standard SOQL |
| `<localleader>t` (`\t`) | Save and run through the Tooling API |

Normal `<leader>Sq` saves the whole `.soql` buffer before execution. Visual `<leader>Sq` keeps sf.nvim’s existing selected-text runner. Results use SFTerm and the captured project/org context.

---

## Metadata browser (`<leader>Su`)

Inventory is project-local under `sf_cache/`. `SF` only refreshes sf.nvim’s org list/default target, while `So` changes only the local target. `SU` is the metadata inventory refresh: choose **Common** or **All enabled types**. The old `SM` mapping was removed because it performed the same Common refresh. The legacy `SK`/`Sk` type-catalog pair is also removed; **All** refreshes that catalog internally before scanning members. The All path can take several minutes and also traverses Report, Dashboard, Document, and EmailTemplate folders.

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

- **Project isolation:** sf.nvim, fzf-lua, query schema modules, and the global `vim.system` token workaround load only after a current buffer/cwd resolves to `sfdx-project.json` or `.forceignore`. Ordinary HTML/JS/TS/SOQL projects keep lightweight guarded mappings only. Once sf.nvim has been used in a Neovim process it remains loaded, but mappings, SOQL completion, and statusline output continue to re-check the active project root.
- **Org flow:** `<leader>SF` runs the upstream org-list fetch; `<leader>So` and `<leader>SO` change only the local/global target. None fetch metadata—run `<leader>SU` when you want to refresh inventory.
- **SFTerm** (float after deploy/retrieve/metadata): stays open so you can read output. `<leader>Se` toggles it; focused `q` also hides it. `Esc` is a cancel key, not a visibility toggle.
- **Cancel:** `Esc` and `<leader>Sx` send Ctrl-C to running SFTerm channels and stop background inventory processes without requiring `<C-w>w`, whether the float is focused, unfocused, hidden, or absent. Normal-mode `<C-c>` inside SFTerm also cancels; terminal-mode `<C-c>` remains the terminal’s native interrupt. With nothing running, normal-mode `Esc` still clears search highlighting. Cancellation is best-effort after Salesforce has accepted a server-side deploy job.
- **fzf-lua** is installed for metadata pickers only; everyday file search remains **Telescope** (`<leader>sf` / `sg`). Needs host **`fzf`** (`brew install fzf` · `sudo pacman -S fzf`) — see [TOOLS.md](../TOOLS.md).
- Coverage signs appear after a **coverage** test run (`ST` / `SA`) when `auto_display_code_sign` is on.
- Optional statusline: target org + coverage appear in lualine once `sf.nvim` is loaded (`statusline.lua` / CodeOSS-style).
- Custom objects / `__mdt` “Invalid type” in `apex_ls`: set target org, then `<leader>Ss` (needs `curl`) to refresh SObject stubs under `.sfdx/tools/sobjects/`.
- **Note:** modern `sf org display --json` **redacts** `accessToken`. Upstream sf.nvim still feeds that into curl → HTTP 401 on `<leader>Ss` even when retrieve/deploy work. `salesforce.lua` wraps `vim.system` and splices a real token from `sf org auth show-access-token` (config-side; survives `:Lazy sync`).

Nav: [index](./README.md) · [lsp](./lsp.md) · [which-key](./which-key.md)
