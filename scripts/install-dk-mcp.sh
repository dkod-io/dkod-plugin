#!/bin/bash
set -euo pipefail

# Resolve platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Plugin directory (where this script lives)
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$PLUGIN_DIR/bin"
mkdir -p "$BIN_DIR"

# Skip if already installed and working
if [ -x "$BIN_DIR/dk-mcp" ] && "$BIN_DIR/dk-mcp" --version >/dev/null 2>&1; then
  echo "dk-mcp already installed at $BIN_DIR/dk-mcp" >&2
  exit 0
fi

# Fetch latest release tag
VERSION=$(curl -fsSL "https://api.github.com/repos/dkod-io/dkod-engine/releases/latest" \
  | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "Failed to determine latest dk-mcp version" >&2
  exit 1
fi

TARBALL="dk-${VERSION}-${OS}-${ARCH}.tar.gz"
URL="https://github.com/dkod-io/dkod-engine/releases/download/${VERSION}/${TARBALL}"

echo "Installing dk-mcp ${VERSION} (${OS}/${ARCH})..." >&2
curl -fsSL "$URL" | tar xz --strip-components=1 -C "$BIN_DIR" "dk-${VERSION}-${OS}-${ARCH}/dk-mcp"
chmod +x "$BIN_DIR/dk-mcp"
echo "dk-mcp installed to $BIN_DIR/dk-mcp" >&2
