# Saturn - Quality of life mod for Balatro

**Saturn** is a [Lovely](https://github.com/ethangreen-dev/lovely-injector) mod for [Balatro](https://www.playbalatro.com/) which introduces some Quality of Life features for better game experience on endless mode.

> This is a fork of [OceanRamen/Saturn](https://github.com/OceanRamen/Saturn) that adds keyboard shortcuts for the animation settings. See the [changelog](CHANGELOG.md) for what differs from upstream.

## Features

-   **Animation Control**

    -   **Game Speed:** Allow increase game speed up to 16x.
    -   **Remove Animations:** Eliminate in-game animations to speed up game loop in later antes.
    -   **Pause after scoring:** Provides some time to shuffle jokers during scoring
    -   **Keyboard shortcuts:** Press `A` to toggle Remove Animations and `D` to toggle Pause after scoring during a run. A status strip at the left edge of the screen shows the current state of both. Another mod can move it into a row above the right end of one of its own boxes by setting `Saturn.status_ui_dock` (see `core/logic/keybinds.lua`).

-   **Consumable Management**

    -   **Stacking:** Stacking of consumable cards. Merge all negative copies of planets, tarots or other consumables to reduce lag.

-   **Enhanced Deck Viewer**
    -   **Hide Played Cards:** hide played cards in deck view.

## Installation

1. Install [Lovely](https://github.com/ethangreen-dev/lovely-injector) by following instructions in repository page. Make sure your antivirus is not removing it;
2. Download `Saturn-<version>.zip` from the [latest release](https://github.com/ershisan99/Saturn/releases/latest);
3. Extract it into game's `Mods` folder (can be found in `%appdata%/Balatro/Mods`). You should end up with `Mods/Saturn/metadata.json`;
4. Start a game. If all done correctly, new button should appear in options menu;

## Contributing

Contributions are welcome! If you found any bug or want a new feature, [make an issue](https://github.com/OceanRamen/Saturn/issues).

## Releasing

1. Add a `## <tag> - <title>` section with the release notes to [CHANGELOG.md](CHANGELOG.md) and commit it;
2. Run `.\scripts\release.ps1 <tag>` (add `-DryRun` first to check the notes and build the zip without publishing anything).

The script bumps the version in `metadata.json` and `core/logic/main.lua`, tags and pushes, builds `dist/Saturn-<tag>.zip` and publishes the GitHub release. It needs [GitHub CLI](https://cli.github.com).
