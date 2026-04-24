#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/dist"
WORK_DIR="$ROOT_DIR/.work"
VERSION=""
UPSTREAM_URL=""
TERMUX_GLIBC_LIB="/data/data/com.termux/files/usr/glibc/lib"

usage() {
  cat <<'EOF'
Usage: ./scripts/build.sh --version VERSION [--url URL] [--output-dir DIR]

Build a Termux-ready package from the official JetBrains Kotlin LSP release.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --url)
      UPSTREAM_URL="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo >&2 "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$VERSION" ]; then
  echo >&2 "Missing required --version"
  usage
  exit 1
fi

if [ -z "$UPSTREAM_URL" ]; then
  UPSTREAM_URL="https://download-cdn.jetbrains.com/kotlin-lsp/$VERSION/kotlin-lsp-$VERSION-linux-aarch64.zip"
fi

PACKAGE_BASENAME="kotlin-lsp-termux-$VERSION"
ZIP_PATH="$WORK_DIR/kotlin-lsp-$VERSION-linux-aarch64.zip"
EXTRACT_DIR="$WORK_DIR/extract"
PACKAGE_DIR="$WORK_DIR/package"
ARCHIVE_PATH="$OUTPUT_DIR/$PACKAGE_BASENAME.tar.gz"

rm -rf "$EXTRACT_DIR" "$PACKAGE_DIR"
mkdir -p "$OUTPUT_DIR" "$EXTRACT_DIR" "$PACKAGE_DIR"

echo "Downloading $UPSTREAM_URL"
curl -fL --retry 3 --output "$ZIP_PATH" "$UPSTREAM_URL"

echo "Extracting upstream archive"
unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"

shopt -s nullglob
source_dirs=("$EXTRACT_DIR"/*/)
shopt -u nullglob

if [ "${#source_dirs[@]}" -ne 1 ]; then
  echo >&2 "Expected exactly one top-level directory in upstream zip"
  exit 1
fi

SOURCE_DIR="${source_dirs[0]%/}"

cp -R "$SOURCE_DIR"/. "$PACKAGE_DIR"/
cp "$ROOT_DIR/wrapper/kotlin-lsp-termux.sh" "$PACKAGE_DIR/kotlin-lsp-termux.sh"

if [ ! -f "$PACKAGE_DIR/native/libfilewatcher_jni.so" ]; then
  echo >&2 "Missing native/libfilewatcher_jni.so in upstream package"
  exit 1
fi

if [ ! -f "$PACKAGE_DIR/lib/language-server.kotlin-lsp.jar" ]; then
  echo >&2 "Missing language-server.kotlin-lsp.jar in upstream package"
  exit 1
fi

patchelf --set-rpath "$TERMUX_GLIBC_LIB" "$PACKAGE_DIR/native/libfilewatcher_jni.so"
chmod +x "$PACKAGE_DIR/kotlin-lsp-termux.sh"

tar -C "$PACKAGE_DIR" -czf "$ARCHIVE_PATH" .

(
  cd "$OUTPUT_DIR"
  sha256sum "$(basename "$ARCHIVE_PATH")" > "$(basename "$ARCHIVE_PATH").sha256"
)

echo "Built $ARCHIVE_PATH"
echo "Built $ARCHIVE_PATH.sha256"
