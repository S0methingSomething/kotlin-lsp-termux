#!/usr/bin/env bash
set -euo pipefail

DEFAULT_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_DIR="$DEFAULT_PREFIX/share/kotlin-lsp"
TEMP_BASE="${TMPDIR:-$DEFAULT_PREFIX/tmp}"
ARCHIVE_PATH=""
REPO=""
TAG=""

usage() {
  cat <<'EOF'
Usage:
  ./install.sh /path/to/kotlin-lsp-termux-<version>.tar.gz
  ./install.sh --repo OWNER/REPO [--tag termux-v<version>] [--install-dir DIR]
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    --install-dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -n "$ARCHIVE_PATH" ]; then
        echo >&2 "Unexpected extra argument: $1"
        usage
        exit 1
      fi
      ARCHIVE_PATH="$1"
      shift
      ;;
  esac
done

if [ -z "$ARCHIVE_PATH" ] && [ -z "$REPO" ]; then
  echo >&2 "Provide a local archive path or --repo OWNER/REPO"
  usage
  exit 1
fi

mkdir -p "$TEMP_BASE"
WORK_DIR="$(mktemp -d "$TEMP_BASE/kotlin-lsp-termux.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

if [ -z "$ARCHIVE_PATH" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo >&2 "gh is required to download from GitHub Releases"
    exit 1
  fi

  if [ -z "$TAG" ]; then
    TAG="$(gh release view --repo "$REPO" --json tagName -q .tagName)"
  fi

  gh release download "$TAG" \
    --repo "$REPO" \
    --pattern 'kotlin-lsp-termux-*.tar.gz' \
    --dir "$WORK_DIR"

  shopt -s nullglob
  archives=("$WORK_DIR"/kotlin-lsp-termux-*.tar.gz)
  shopt -u nullglob

  if [ "${#archives[@]}" -ne 1 ]; then
    echo >&2 "Expected exactly one downloaded archive"
    exit 1
  fi

  ARCHIVE_PATH="${archives[0]}"
fi

if [ ! -f "$ARCHIVE_PATH" ]; then
  echo >&2 "Archive not found: $ARCHIVE_PATH"
  exit 1
fi

mkdir -p "$(dirname "$INSTALL_DIR")"
NEW_DIR="$WORK_DIR/kotlin-lsp"
mkdir -p "$NEW_DIR"
tar -xzf "$ARCHIVE_PATH" -C "$NEW_DIR"

if [ ! -f "$NEW_DIR/kotlin-lsp-termux.sh" ]; then
  echo >&2 "Archive did not extract the expected wrapper"
  exit 1
fi

chmod +x "$NEW_DIR/kotlin-lsp-termux.sh"

BACKUP_DIR="$INSTALL_DIR.bak"
rm -rf "$BACKUP_DIR"
if [ -e "$INSTALL_DIR" ]; then
  mv "$INSTALL_DIR" "$BACKUP_DIR"
fi

mv "$NEW_DIR" "$INSTALL_DIR"

echo "Installed Kotlin LSP to $INSTALL_DIR"
echo "Wrapper: $INSTALL_DIR/kotlin-lsp-termux.sh"
echo "If needed, update your editor config to point at that wrapper path."
