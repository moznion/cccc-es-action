# DEPRECATED

This action is no longer available. Please use [cccc-action](https://github.com/moznion/cccc-action) instead.

# cccc-es-action

A GitHub composite action that installs the
[`cccc-es`](https://github.com/moznion/cccc) complexity analyzer from a GitHub
release (matching the runner's OS/arch, verified by SHA-256) and adds it to
`PATH`. If you pass `path`, it also runs cccc-es as a Cognitive/Cyclomatic
complexity gate.

`cccc-es` measures **Cognitive Complexity** (SonarSource) and **Cyclomatic
Complexity** (McCabe) of TypeScript/JavaScript.

## Usage

### Run it as a CI gate

```yaml
- uses: moznion/cccc-es-action@v1
  with:
    path: src/
    max-cognitive: 15      # fail the job if any function exceeds this
    max-cyclomatic: 20
    exclude: |             # one glob per line (repeatable)
      dist/**
      **/*.{test,spec}.ts
```

### Install only, then use the binary yourself

```yaml
- uses: moznion/cccc-es-action@v1
  with:
    version: v0.1.0        # or "latest" (default)
- run: cccc-es --top-cognitive 10 src/
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `version` | `latest` | Release tag to install (e.g. `v0.1.0`), or `latest` |
| `repository` | `moznion/cccc` | Repo to fetch the cccc-es release from |
| `github-token` | `${{ github.token }}` | Token for API calls / asset downloads |
| `path` | _(empty)_ | Files/dirs to analyze. **Empty = install only** |
| `table` | `false` | Human-readable table instead of JSON |
| `ext` | | Comma-separated extensions to include |
| `exclude` | | Glob patterns to exclude, one per line (e.g. `dist/**`) |
| `max-cognitive` | | Fail if any function's cognitive complexity exceeds N |
| `max-cyclomatic` | | Fail if any function's cyclomatic complexity exceeds N |
| `min` | | Only report functions with complexity >= N |
| `top-cognitive` | | Show the N most cognitively-complex functions |
| `top-cyclomatic` | | Show the N most cyclomatically-complex functions |
| `no-ignore` | `false` | Do not respect `.gitignore` |
| `jobs` | | Parallel worker count |
| `args` | | Extra raw arguments appended to the invocation |
| `output-file` | | Also write output to this file (gate exit code preserved) |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The release tag that was installed |
| `bin` | Absolute path to the installed `cccc-es` binary |

## Supported runners

`ubuntu-latest`, `macos-latest`, and `windows-latest` (the targets published by
the [cccc release workflow](https://github.com/moznion/cccc/blob/main/.github/workflows/release.yml)):

| OS | Arch | Target |
|----|------|--------|
| Linux | x64 | `x86_64-unknown-linux-musl` |
| Linux | arm64 | `aarch64-unknown-linux-musl` |
| macOS | x64 | `x86_64-apple-darwin` |
| macOS | arm64 | `aarch64-apple-darwin` |
| Windows | x64 | `x86_64-pc-windows-msvc` |

## License

[MIT](./LICENSE)
