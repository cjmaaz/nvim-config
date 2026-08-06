# Example: minimal Maven Java project

Small **valid** `jdtls` project for smoke-testing diagnostics and LSP.

Open this folder as the Neovim cwd (or open a file under it). After `jdtls` attaches, you should **not** see the “non-project file” warning on these sources.

Docs: [diagnostics/java.md](../diagnostics/java.md) · [diagnostics/](../diagnostics/README.md)

```text
java-maven-minimal/
├── README.md                 # this file
├── pom.xml
└── src/main/java/com/example/
    ├── ChapterOne.java
    └── ChapterTwo.java
```

## Try it

```bash
cd docs/examples/java-maven-minimal
nvim src/main/java/com/example/ChapterTwo.java
```

- `:LspInfo` — confirm `jdtls`
- `<leader>e` / `]d` — diagnostic UI (see [display.md](../diagnostics/display.md))

Optional: `mvn -q compile` if Maven is installed (not required for the LSP warning fix).

## Contrast (what triggers the WARN)

A directory that only contains loose files, for example:

```text
some-folder/
├── ChapterOne.java
├── ChapterOne.class
├── ChapterTwo.java
└── ChapterTwo.class
```

with **no** `pom.xml` / Gradle / Eclipse project files at a parent root → `jdtls` reports non-project / syntax-only mode. Any path name is fine; the missing **project marker** is what matters.
