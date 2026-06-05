#!/usr/bin/env bash
# Install the cccc-es binary from a GitHub release and expose it on PATH.
#
# Inputs (environment variables, set by action.yml):
#   INPUT_VERSION     Release tag to install, or "latest".
#   INPUT_REPOSITORY  Repository to fetch the release from.
#   GH_TOKEN          Optional token for the GitHub API.
#   RUNNER_OS / RUNNER_ARCH / RUNNER_TEMP   Provided by the runner.
#   GITHUB_PATH / GITHUB_OUTPUT             Provided by the runner.
set -euo pipefail

repo="$INPUT_REPOSITORY"

# Map the runner OS/arch to the release target triple.
case "$RUNNER_OS-$RUNNER_ARCH" in
  Linux-X64)    target=x86_64-unknown-linux-musl ;;
  Linux-ARM64)  target=aarch64-unknown-linux-musl ;;
  macOS-X64)    target=x86_64-apple-darwin ;;
  macOS-ARM64)  target=aarch64-apple-darwin ;;
  Windows-X64)  target=x86_64-pc-windows-msvc ;;
  *)
    echo "::error::unsupported runner: $RUNNER_OS/$RUNNER_ARCH" >&2
    exit 1 ;;
esac

# Resolve the release tag.
tag="$INPUT_VERSION"
if [ -z "$tag" ] || [ "$tag" = latest ]; then
  api="https://api.github.com/repos/$repo/releases/latest"
  if [ -n "${GH_TOKEN:-}" ]; then
    body=$(curl -fsSL -H "Authorization: Bearer $GH_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" "$api")
  else
    body=$(curl -fsSL "$api")
  fi
  tag=$(printf '%s' "$body" | grep -m1 '"tag_name"' \
    | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
fi
if [ -z "$tag" ]; then
  echo "::error::could not resolve a cccc-es release tag" >&2
  exit 1
fi

case "$RUNNER_OS" in
  Windows) archive_ext=zip;    binname=cccc-es.exe ;;
  *)       archive_ext=tar.gz; binname=cccc-es ;;
esac

archive="cccc-es-$tag-$target.$archive_ext"
base="https://github.com/$repo/releases/download/$tag"
workdir="$RUNNER_TEMP/cccc-es"
mkdir -p "$workdir"
cd "$workdir"

echo "Downloading $base/$archive"
curl -fsSL -o "$archive" "$base/$archive"
curl -fsSL -o "$archive.sha256" "$base/$archive.sha256"

# Verify the SHA-256 checksum.
expected=$(awk '{print $1}' "$archive.sha256")
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$archive" | awk '{print $1}')
else
  actual=$(shasum -a 256 "$archive" | awk '{print $1}')
fi
if [ "$expected" != "$actual" ]; then
  echo "::error::checksum mismatch for $archive (expected $expected, got $actual)" >&2
  exit 1
fi

# Extract: bsdtar (Windows) handles zip; GNU tar auto-detects gzip.
tar -xf "$archive"
chmod +x "$binname" 2>/dev/null || true
bin="$workdir/$binname"

echo "$workdir" >> "$GITHUB_PATH"
echo "bin=$bin" >> "$GITHUB_OUTPUT"
echo "version=$tag" >> "$GITHUB_OUTPUT"
echo "Installed cccc-es $tag ($target) -> $bin"
