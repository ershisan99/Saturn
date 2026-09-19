# Changelog

Release notes for this fork of [OceanRamen/Saturn](https://github.com/OceanRamen/Saturn).
Each `## <tag> - <title>` section below is published verbatim as the GitHub
release notes by `scripts/release.ps1`, so write it before cutting a release.

Notes for `alpha-0.2.2-E-qf3` and earlier are on the
[upstream releases page](https://github.com/OceanRamen/Saturn/releases).

## alpha-0.2.2-F - Keyboard shortcuts

### Added

- **Keyboard shortcuts for the animation settings.** During a run, press `A` to toggle "Remove animations" and `D` to toggle "Pause after scoring" without opening the options menu. The change is saved to your config immediately. Shortcuts are ignored while the game is paused, a menu is open, or a text field is focused.
- **Status strip.** Two small icons in the left margin of the screen show each shortcut's key and light up green while the setting is on. Hover an icon to see the setting's name, its current state and the key that toggles it.
- **Rebindable keys.** Set `keybind_anim` / `keybind_pause` in `%appdata%/Balatro/config/Saturn.jkr` to any [LÖVE key name](https://love2d.org/wiki/KeyConstant) (e.g. `"f5"`, `"n"`). Numpad keys match their plain equivalents (`kp1` acts as `1`). Set a key to `""` to disable that shortcut.

### Fixed

- Options added in a new version are now backfilled into an existing config on startup, instead of staying `nil` until the config is recreated.
- Includes the upstream card stacking fix made after `alpha-0.2.2-E-qf3`: splitting or dissolving a stack of negative consumables no longer raises the consumable slot limit by one each time.

### Installing

Download `Saturn-alpha-0.2.2-F.zip` below and extract it into `%appdata%/Balatro/Mods`, so that you end up with `Mods/Saturn/metadata.json`. Requires [Lovely](https://github.com/ethangreen-dev/lovely-injector). The zip already contains a correctly named `Saturn` folder, so there is nothing to rename. If you are updating, delete the old Saturn folder first; your settings live in `%appdata%/Balatro/config/Saturn.jkr` and are kept.
