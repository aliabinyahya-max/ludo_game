# Phase 03–04 — 3D Board and Gameplay Animation

## Phase 03: Three-dimensional board

- Added `three_js: 0.3.0` as the real-time 3D rendering engine.
- Added `LudoBoard3D` with an orthographic camera, raised board slab, four colored home quadrants, recessed home sockets, raised path cells, safe-cell markers, colored home lanes, center destination, and 3D token meshes.
- Kept the game rules in `LudoEngine`; the 3D board only renders model state and sends legal token taps to the existing callback.
- Token positions are synchronized from the existing logical `step` state. Tokens in base, on the shared path, in a home lane, and finished are all represented.
- The tap overlay maps screen coordinates back to the orthographic board grid. Only tokens passed in `highlightedTokens` can be selected.
- The original 2D board remains available through `GameScreen(use3DBoard: false)` for deterministic widget tests and as a fallback.

## Phase 04: Motion and feedback

- Existing step-by-step token movement now drives interpolated 3D token motion through the ThreeJS frame loop.
- Legal tokens receive a pulsing gold selection ring.
- Tokens rotate subtly while moving; capture/reset positions are synchronized from the rules engine.
- Dice control rotates while rolling.
- Game status messages use a short fade-and-slide transition.
- The existing game engine still owns capture, extra-turn, exact-home, and win decisions.

## Android build validation

The GitHub Actions validation workflow installs CMake 3.31.4 for flutter_angle, then runs:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug`
5. Uploads `app-debug.apk` as the `ludo-android-debug-apk` artifact.

This debug build is for device testing only. It is not a signed release and does not publish or distribute the app.

## Known validation boundary

The ThreeJS renderer is a GPU-backed platform component. The Android target now compiles with SDK 35 and NDK 28.2.13676358, as required by the flutter_angle renderer dependency. Widget tests deliberately use the 2D fallback and do not prove real GPU rendering, touch alignment, thermal behavior, or frame rate on a physical phone. A successful Android APK build proves compilation and packaging only. Final acceptance requires installing the artifact on an Android device and checking board rendering, taps, movement, and performance.

The package publisher is marked unverified on pub.dev. This dependency was accepted for this implementation after explicit approval; its platform constraints and known issues should remain part of the release review.
