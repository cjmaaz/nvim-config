# Commitizen (optional)

Interactive helper for [Conventional Commits](https://www.conventionalcommits.org/). Useful if you want prompted `type(scope): subject` commits; this Neovim config does **not** require it.

---

## Install

```bash
npm install -g commitizen cz-conventional-changelog
```

Config (home directory):

```bash
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc
```

Usage from a git repo:

```bash
cz
# or: git cz   (if your git cz alias is set up)
```

---

## Prompt breakdown

### 1. Type of change

Categorizes the work (arrow keys to select):

| Type | Meaning |
| --- | --- |
| `feat` | New feature |
| `docs` | Documentation only |
| `style` | Formatting only (no behavior change) |
| `refactor` | Restructure without fixing a bug or adding a feature |
| `perf` | Performance improvement |
| `test` | Add or fix tests |
| `build` / `ci` | Build system, deps, or CI |
| `chore` | Maintenance that isn’t source/tests (e.g. `.gitignore`) |

### 2. Scope (optional)

One word for where the change landed (`auth`, `statusline`, `git`, …). Press Enter to skip if the change is broad.

### 3. Subject

Short title in **imperative, present tense** (completes: “If applied, this commit will…”).

- Good: `add gitsigns hunk keymaps`
- Bad: `added gitsigns hunk keymaps`
- Lowercase; no period at the end

### 4. Body (optional)

Why / how when the subject isn’t enough. Skip for trivial changes.

### 5. Breaking changes

Answer `y` only if callers must change how they use something (API, config keys, etc.). You’ll describe the break and migration.

### 6. Issues

Link tickets if you use them (`Closes #123`, `Fixes PROJ-42`). Hosting platforms may auto-close the issue when the commit lands on the default branch.
