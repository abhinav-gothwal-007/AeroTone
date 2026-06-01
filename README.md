# AeroTone ✈️

A macOS menu-bar focus timer disguised as a flight. Pick a destination, choose your
seat, and "board" — your focus session is framed as a journey across a 3D globe, with
the remaining time shown right in the menu bar.

> Instead of staring at a countdown, you're flying somewhere. The further the
> destination, the longer the session.

## How it works

1. **Set your home airport** (defaults to SFO, remembered between launches).
2. **Pick a destination** from ~450 major airports worldwide — or choose a specific
   focus length directly.
3. **Choose a seat**, get a boarding pass, and board.
4. **Focus.** A live flight plays out over an Apple Maps globe showing the great-circle
   route, with the timer counting down in the menu bar. Land at your destination when
   the session ends.

The session length is derived from the real great-circle distance between airports, so
short hops are quick sessions and long-haul flights are deep-focus blocks.

## Features

- **Menu-bar app** — lives in the menu bar with a live countdown; the window is a
  popover.
- **3D globe** — Apple Maps (MapKit) imagery globe centered on your flight, with the
  great-circle route, endpoints, and plane drawn on top. Pan, spin, and zoom freely.
- **Ambient sound mixer** — synthesized jet-engine drone and selectable white / pink /
  brown noise, each with its own level, plus a master volume. Off by default.
- **Liquid Glass UI** — built with the macOS 26 glass design, with a graceful fallback.

## Requirements

- **macOS 26 (Tahoe)** or later
- **Xcode 26** or later (only if building from source)

The app targets macOS 26 because it uses the Liquid Glass design system. The globe also
requires a network connection to load Apple Maps imagery.

## Download

Grab the latest **`AeroTone-x.y.z.dmg`** from the
[Releases](../../releases) page, open it, and drag **AeroTone** into Applications.

> **First launch:** AeroTone is ad-hoc signed (not notarized through an Apple Developer
> account), so macOS Gatekeeper will warn on first open. Either **right-click the app →
> Open** and confirm, or run:
> ```sh
> xattr -dr com.apple.quarantine /Applications/AeroTone.app
> ```
> You only need to do this once.

### Install via Homebrew

```sh
brew install --cask abhinav-gothwal-007/aerotone/aerotone --no-quarantine
```

(`--no-quarantine` skips the Gatekeeper prompt above, since the app isn't notarized.)

## Build & run

```sh
git clone <your-repo-url>
cd AeroTone
open AeroTone.xcodeproj
```

Then build and run (⌘R) in Xcode. The app appears in your menu bar (look for the app
icon); click it to open the window. Code signing is set to "Sign to Run Locally," so no
developer account is required to run it on your own machine.

## Tech

- SwiftUI + the Observation framework (`@Observable`)
- MapKit for the globe
- AVAudioEngine for the synthesized ambient sound
- No third-party dependencies

## Releasing (maintainer)

```sh
scripts/package-dmg.sh 1.0.0   # build + package dist/AeroTone-1.0.0.dmg (prints sha256)
scripts/release.sh     1.0.0   # the above + publish a GitHub Release + print the cask snippet
```

`scripts/release.sh` prints a ready-to-paste Homebrew cask (with version + sha256 filled
in) for the `homebrew-aerotone` tap — see [packaging/aerotone.rb](packaging/aerotone.rb).

## Data

Airport coordinates are derived from [OurAirports](https://ourairports.com/data/), which
is in the public domain.

## License

[MIT](LICENSE)
