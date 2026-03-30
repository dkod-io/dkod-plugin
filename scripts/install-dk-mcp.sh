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

# Skip if already installed
if [ -x "$BIN_DIR/dk-mcp" ]; then
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
CHECKSUM_URL="https://github.com/dkod-io/dkod-engine/releases/download/${VERSION}/checksums-sha256.txt"
URL="https://github.com/dkod-io/dkod-engine/releases/download/${VERSION}/${TARBALL}"

echo "Installing dk-mcp ${VERSION} (${OS}/${ARCH})..." >&2

# Download tarball
curl -fsSL "$URL" -o "$BIN_DIR/$TARBALL"

# Verify checksum
EXPECTED=$(curl -fsSL "$CHECKSUM_URL" | grep "$TARBALL" | awk '{print $1}')
if [ -n "$EXPECTED" ]; then
  ACTUAL=$(shasum -a 256 "$BIN_DIR/$TARBALL" | awk '{print $1}')
  if [ "$ACTUAL" != "$EXPECTED" ]; then
    rm -f "$BIN_DIR/$TARBALL"
    echo "Checksum mismatch for $TARBALL (expected $EXPECTED, got $ACTUAL)" >&2
    exit 1
  fi
fi

# Extract and clean up
tar xzf "$BIN_DIR/$TARBALL" --strip-components=1 -C "$BIN_DIR" "dk-${VERSION}-${OS}-${ARCH}/dk-mcp"
rm -f "$BIN_DIR/$TARBALL"
chmod +x "$BIN_DIR/dk-mcp"
echo "dk-mcp installed to $BIN_DIR/dk-mcp" >&2
