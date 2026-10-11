# Beat UP!

Beat UP! is a desktop rhythm game built with Godot. Notes travel along a horizontal lane toward a hit zone, and players press directional keys in time with the music. Its main control scheme uses eight directions on the numeric keypad.

## Features

- **Directional gameplay:** 8-key numpad controls with an alternative 4-key mode.
- **Three difficulties:** Normal, Hard, and Master charts.
- **Performance tracking:** timing judgments, combos, scores, ranks, and personal bests.
- **Song Library:** browse tracks, choose difficulties, and access replay features.
- **Custom levels:** import charts and `.beatup-pack` files, and export installed custom songs. Chart Studio has been retired.

## Controls

```text
7 ↖    8 ↑    9 ↗
4 ←           6 →
1 ↙    2 ↓    3 ↘
```

`5` is unused. Press **Space** for Space notes. A 4-key control mode is also available.

## Getting Started

1. Install **Godot 4.7**.
2. Clone this repository:

   ```bash
   git clone https://github.com/Geraldicky/Beat-UP.git
   ```

3. Open `project.godot` in Godot and let the project assets import.
4. Run the project with **F5**.

## Tech Stack

- **Engine:** Godot 4.7
- **Game and UI:** GDScript
- **Development tools and tests:** Python

## Development Status

Beat UP! is currently in development. There is no public GitHub release yet.

Developer setup and checks are described in [`docs/PROJECT_STRUCTURE.md`](docs/PROJECT_STRUCTURE.md). Major milestones are recorded in [`CHANGELOG.md`](CHANGELOG.md).

Music and artwork may belong to third-party rights holders. Verify redistribution permissions before repackaging those assets. Credits and license details for the menu music and sound effects are documented in [`music/menu/LICENSE.md`](music/menu/LICENSE.md) and [`audio/SFX-SOURCES.md`](audio/SFX-SOURCES.md).
