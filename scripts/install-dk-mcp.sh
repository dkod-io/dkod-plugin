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

VERSION_FILE="$BIN_DIR/.version"
CHECK_FILE="$BIN_DIR/.last-update-check"
CHECK_INTERVAL=3600  # seconds between update checks (1 hour)

# Fast path: if binary exists and we checked recently, skip entirely (no network).
if [ -x "$BIN_DIR/dk-mcp" ] && [ -f "$CHECK_FILE" ]; then
  LAST_CHECK=$(cat "$CHECK_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [ $((NOW - LAST_CHECK)) -lt $CHECK_INTERVAL ]; then
    exit 0
  fi
fi

# Fetch latest release tag
VERSION=$(curl -fsSL --max-time 5 "https://api.github.com/repos/dkod-io/dkod-engine/releases/latest" \
  | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' 2>/dev/null || true)

if [ -z "$VERSION" ]; then
  # Network error — if binary exists, use it; otherwise fail.
  if [ -x "$BIN_DIR/dk-mcp" ]; then
    echo "Update check failed (network), using installed version" >&2
    date +%s > "$CHECK_FILE"
    exit 0
  fi
  echo "Failed to determine latest dk-mcp version" >&2
  exit 1
fi

# If already on latest version, record check and skip.
INSTALLED_VERSION=""
if [ -f "$VERSION_FILE" ]; then
  INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || true)
fi

if [ -x "$BIN_DIR/dk-mcp" ] && [ "$INSTALLED_VERSION" = "$VERSION" ]; then
  date +%s > "$CHECK_FILE"
  exit 0
fi

# Download and install
TARBALL="dk-${VERSION}-${OS}-${ARCH}.tar.gz"
CHECKSUM_URL="https://github.com/dkod-io/dkod-engine/releases/download/${VERSION}/checksums-sha256.txt"
URL="https://github.com/dkod-io/dkod-engine/releases/download/${VERSION}/${TARBALL}"

if [ -n "$INSTALLED_VERSION" ]; then
  echo "Updating dk-mcp ${INSTALLED_VERSION} → ${VERSION} (${OS}/${ARCH})..." >&2
else
  echo "Installing dk-mcp ${VERSION} (${OS}/${ARCH})..." >&2
fi

# Download tarball
curl -fsSL "$URL" -o "$BIN_DIR/$TARBALL"

# Verify checksum (mandatory — fail if missing or mismatched)
CHECKSUMS=$(curl -fsSL "$CHECKSUM_URL")
EXPECTED=$(echo "$CHECKSUMS" | grep "$TARBALL" | awk '{print $1}')
if [ -z "$EXPECTED" ]; then
  rm -f "$BIN_DIR/$TARBALL"
  echo "No checksum found for $TARBALL in release checksums" >&2
  exit 1
fi
ACTUAL=$(shasum -a 256 "$BIN_DIR/$TARBALL" | awk '{print $1}')
if [ "$ACTUAL" != "$EXPECTED" ]; then
  rm -f "$BIN_DIR/$TARBALL"
  echo "Checksum mismatch for $TARBALL (expected $EXPECTED, got $ACTUAL)" >&2
  exit 1
fi

# Extract and clean up
tar xzf "$BIN_DIR/$TARBALL" --strip-components=1 -C "$BIN_DIR" "dk-${VERSION}-${OS}-${ARCH}/dk-mcp"
rm -f "$BIN_DIR/$TARBALL"
chmod +x "$BIN_DIR/dk-mcp"
echo "$VERSION" > "$VERSION_FILE"
date +%s > "$CHECK_FILE"
echo "dk-mcp ${VERSION} ready" >&2
