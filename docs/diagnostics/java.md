# Java / jdtls: “non-project file”

Nav: [index](./README.md) · [display](./display.md) · [quiet](./quiet.md) · [example](../examples/java-maven-minimal/)

## Symptom

When editing a `.java` buffer, the Java language server (`jdtls`) may report a diagnostic whose message is like:

> *… is a non-project file, only syntax errors are reported*

Exact wording can vary by server version. Severity is usually **WARN**. It may appear via any enabled channel (virtual text, sign, float, etc.) — **colors follow your colorscheme**.

This comes from **`jdtls`**, not from Treesitter, neo-tree, or the file explorer.

---

## What it means

`jdtls` looks for a **project root** it understands, commonly:

| Kind | Typical markers (any of these near the root) |
| --- | --- |
| Maven | `pom.xml` |
| Gradle | `build.gradle`, `build.gradle.kts`, `settings.gradle`, `settings.gradle.kts` |
| Eclipse | `.project` / `.classpath` |

If you open a directory that is only a pile of `.java` / `.class` files with **no** such marker, `jdtls` treats those sources as **non-project**:

- Syntax-oriented feedback still works
- Full classpath / multi-file project intelligence does not

That is expected behavior, not a failed Mason install.

---

## How to fix

### 1. Use a real project layout (recommended)

Copy or mirror the repo example:

→ **[docs/examples/java-maven-minimal/](../examples/java-maven-minimal/)**

Or create the same shape anywhere on disk:

```text
<project-root>/
├── pom.xml                 # or Gradle build files
└── src/main/java/…/        # package folders + .java sources
```

Then open Neovim with cwd at **`<project-root>`** (or open a file under it), wait for `jdtls` to index (`:LspInfo`).

Gradle alternative: standard Gradle tree with `src/main/java` and build scripts at the root — same idea, different markers.

### 2. Keep a throwaway folder

Fine for tiny experiments. Live with the WARN, or quiet WARN virtual text / raise severity — see [display.md](./display.md) and [quiet.md](./quiet.md).

### 3. Host requirements

`jdtls` needs a **JDK** on PATH (`java -version`). Mason installs the server bits; it does not install Java. See [TOOLS.md](../TOOLS.md).

### 4. Later enhancements

Richer Java workflows (debugging, finer `jdtls` setup) often add `nvim-jdtls`. Not required merely to clear this WARN if the project root is valid.

---

## Verify

1. Project marker exists at the root you expect (`pom.xml` or Gradle files).
2. Sources live under a conventional path (`src/main/java/...`) or whatever that build tool uses.
3. `:LspInfo` shows `jdtls` attached to the buffer.
4. Re-open the buffer or restart Neovim after creating the marker files.

Nav: [index](./README.md) · [display](./display.md) · [quiet](./quiet.md) · [example](../examples/java-maven-minimal/)
