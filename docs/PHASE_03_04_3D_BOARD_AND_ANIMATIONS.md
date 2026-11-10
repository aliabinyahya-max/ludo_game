# Phase 03–04 — 3D Board and Gameplay Animation

## Phase 03: Three-dimensional board

- Added `three_js: 0.3.0` as the real-time 3D rendering engine.
- Added `LudoBoard3D` with an orthographic camera, raised board slab, four colored home quadrants, recessed home sockets, raised path cells, safe-cell markers, colored home lanes, center destination, and 3D token meshes.
- Kept game rules in `LudoEngine`; the 3D board renders model state and sends legal token taps to the existing callback.
- Token positions are synchronized from logical `step` state.
- The original 2D board remains available as a fallback through `GameScreen(use3DBoard: false)`.

## Phase 04: Motion and feedback

- Token movement drives interpolated 3D token motion through the ThreeJS frame loop.
- Legal tokens receive a pulsing gold selection ring.
- Tokens rotate subtly while moving; dice control rotates while rolling.
- Game status messages use a fade-and-slide transition.
- The game engine remains authoritative for captures, extra turns, exact-home entry, and victory.

## Android build and installation evidence

- The authorized debug build and artifact upload succeeded in run [42781991508](https://github.com/aliabinyahya-max/ludo_game/actions/runs/42781991508).
- The user confirmed installation on a physical Android phone.
- The user confirmed that the main menu opens clearly.
- Starting a match currently displays the match app bar and back arrow but leaves the board area blank. This is a device-reported failure; the exact GPU/renderer root cause is not yet established.

## Renderer failure handling update

- `GameScreen` now starts an 8-second initialization timeout when 3D is enabled.
- `LudoBoard3D` reports scene setup completion and catches setup/render exceptions.
- `GameScreen` switches to the existing 2D board and shows a localized message when initialization times out or a renderer error is reported.
- A widget test covers the initialization-timeout fallback.
- The CI workflow is now validation-only: dependency resolution, Android SDK preflight, static analysis, and automated tests. It does not build APK/AAB artifacts.

## Validation boundary

Widget tests use the 2D fallback and cannot prove real GPU rendering, touch alignment, thermal behavior, or frame rate on a physical phone. The fallback correction also requires a newly authorized and installed APK before device verification. Do not claim the black-screen defect is resolved until that manual test passes.
