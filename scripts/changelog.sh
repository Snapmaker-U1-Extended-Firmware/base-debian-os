#!/bin/bash

VERSION="${1:-unknown}"
COMMIT="${2:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"

echo "## Debian (arm64) Base Rootfs"
echo ""
echo "**Version:** $VERSION"
echo "**Built:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "**Commit:** $COMMIT"
echo ""

if git describe --tags --abbrev=0 2>/dev/null; then
  echo "## Changes since last release"
  echo ""
  git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"- %s (%h)"
  echo ""
else
  echo "## Recent Changes"
  echo ""
  git log -10 --pretty=format:"- %s (%h)"
  echo ""
fi

echo ""
echo "## Package List"
echo ""
echo '```'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
grep -v '^#' "$SCRIPT_DIR/../packages/u1-debian" | grep -v '^$'
echo '```'
