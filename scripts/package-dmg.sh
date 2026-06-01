#!/usr/bin/env bash
#
# Build a Release .app and package it into a distributable .dmg.
# Usage: scripts/package-dmg.sh [version]   (default version: 1.0.0)
#
# The app is ad-hoc signed (no Apple Developer account required), so users will
# need to bypass Gatekeeper on first launch — see the README "Download" section.

set -euo pipefail

VERSION="${1:-1.0.0}"
SCHEME="AeroTone"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build/release"
DIST_DIR="$ROOT/dist"
APP="$BUILD_DIR/Build/Products/Release/$SCHEME.app"
DMG="$DIST_DIR/AeroTone-$VERSION.dmg"

echo "▶ Building $SCHEME (Release)…"
xcodebuild -project "$ROOT/AeroTone.xcodeproj" -scheme "$SCHEME" \
  -configuration Release -derivedDataPath "$BUILD_DIR" \
  clean build >/dev/null

[ -d "$APP" ] || { echo "✗ App not found at $APP"; exit 1; }

echo "▶ Staging disk image contents…"
mkdir -p "$DIST_DIR"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # drag-to-install target

echo "▶ Creating DMG…"
rm -f "$DMG"
hdiutil create -volname "$SCHEME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"
echo
echo "✓ Built $DMG"
echo "  version : $VERSION"
echo "  sha256  : $SHA"
