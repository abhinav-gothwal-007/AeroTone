#!/usr/bin/env bash
#
# Build the DMG and publish it as a GitHub Release, then print the Homebrew
# cask snippet (with the version + sha256 filled in) to paste into your tap.
#
# Usage: scripts/release.sh <version>      e.g. scripts/release.sh 1.0.0
# Requires: gh (authenticated) and an existing GitHub remote named "origin".

set -euo pipefail

VERSION="${1:?usage: scripts/release.sh <version>  (e.g. 1.0.0)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMG="$ROOT/dist/AeroTone-$VERSION.dmg"
TAG="v$VERSION"

"$ROOT/scripts/package-dmg.sh" "$VERSION"

echo "▶ Creating GitHub release ${TAG}…"
gh release create "$TAG" "$DMG" \
  --title "AeroTone $VERSION" \
  --notes "AeroTone $VERSION — a macOS menu-bar focus timer themed as a flight.

Download **AeroTone-$VERSION.dmg** below. The app is ad-hoc signed, so on first
launch right-click it in /Applications and choose **Open** (or run
\`xattr -dr com.apple.quarantine /Applications/AeroTone.app\`)."

SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

echo
echo "──────────── Homebrew cask (paste into homebrew-aerotone/Casks/aerotone.rb) ────────────"
cat <<EOF
cask "aerotone" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/$REPO/releases/download/v#{version}/AeroTone-#{version}.dmg"
  name "AeroTone"
  desc "Menu-bar focus timer themed as a flight"
  homepage "https://github.com/$REPO"

  depends_on macos: ">= :tahoe"

  app "AeroTone.app"
end
EOF
