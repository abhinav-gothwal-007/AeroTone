# Reference Homebrew Cask for AeroTone.
#
# This file lives in a SEPARATE repo that is your Homebrew "tap":
#   1. Create a public repo named exactly:  homebrew-aerotone
#   2. Put this file at:                     Casks/aerotone.rb
#   3. Fill in `version` and `sha256` for each release (scripts/release.sh
#      prints the exact values to paste).
#
# Users then install with:
#   brew install --cask <your-github-user>/aerotone/aerotone --no-quarantine
#
# (--no-quarantine is needed because the app is ad-hoc signed, not notarized.)

cask "aerotone" do
  version "1.0.0"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/REPLACE_OWNER/AeroTone/releases/download/v#{version}/AeroTone-#{version}.dmg"
  name "AeroTone"
  desc "Menu-bar focus timer themed as a flight"
  homepage "https://github.com/REPLACE_OWNER/AeroTone"

  depends_on macos: ">= :tahoe"   # macOS 26

  app "AeroTone.app"
end
