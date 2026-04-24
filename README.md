# kotlin-lsp-termux

Thin packaging repo for running the official JetBrains Kotlin LSP on Termux.

This repo does not fork Kotlin LSP. It downloads the upstream `linux-aarch64` standalone release, adds a Termux wrapper, patches the file watcher JNI library for Termux's glibc package, and publishes a fetchable release asset.

## What It Fixes

- Launches the bundled JetBrains Runtime through Termux's glibc loader
- Avoids `grun` wildcard expansion issues
- Uses a valid temp directory on Termux
- Removes invalid platform-specific JVM opens from the wrapper
- Forces `--stdio` so LSP clients get proper JSON-RPC traffic
- Patches `native/libfilewatcher_jni.so` with the Termux glibc rpath

## Repo Layout

- `wrapper/kotlin-lsp-termux.sh`: Termux launcher for the packaged upstream bundle
- `scripts/build.sh`: builds a Termux-ready tarball from an upstream JetBrains release
- `.github/workflows/release.yml`: manual GitHub Actions release workflow
- `install.sh`: installs a built archive locally, or fetches it from a GitHub Release with `gh`

## Build Locally

Requirements:

- `bash`
- `curl`
- `unzip`
- `tar`
- `patchelf`

Build a package for a specific upstream version:

```bash
bash ./scripts/build.sh --version 262.2310.0
```

Output:

- `dist/kotlin-lsp-termux-262.2310.0.tar.gz`
- `dist/kotlin-lsp-termux-262.2310.0.tar.gz.sha256`

## Publish With GitHub Actions

Run the workflow manually:

```bash
gh workflow run release.yml -R OWNER/kotlin-lsp-termux -f version=262.2310.0
gh run watch -R OWNER/kotlin-lsp-termux
```

The workflow will:

1. Download the official JetBrains `linux-aarch64` zip
2. Add the Termux wrapper
3. Patch the file watcher JNI library rpath
4. Repack everything as a tarball
5. Publish a GitHub Release tagged `termux-v<version>`

## Install From A GitHub Release

```bash
bash ./install.sh --repo OWNER/kotlin-lsp-termux
```

Install a specific release tag:

```bash
bash ./install.sh --repo OWNER/kotlin-lsp-termux --tag termux-v262.2310.0
```

Install from a local archive:

```bash
bash ./install.sh dist/kotlin-lsp-termux-262.2310.0.tar.gz
```

By default this installs to `$PREFIX/share/kotlin-lsp`.

## OpenCode Config

Point your Kotlin LSP entry at the stable wrapper path:

```json
{
  "kotlin-lsp": {
    "command": [
      "/data/data/com.termux/files/usr/share/kotlin-lsp/kotlin-lsp-termux.sh"
    ],
    "extensions": [".kt", ".kts", ".java"]
  }
}
```

## License Note

This repo repackages upstream JetBrains Kotlin LSP binaries. Before publishing public release assets, verify that redistribution is acceptable for the upstream artifact you are packaging.
