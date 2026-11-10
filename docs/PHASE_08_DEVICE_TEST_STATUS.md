# Phase 08 — Physical Device Test Status

Date: 2026-11-10
Branch: `feat/3d-board-animations-phase-03-04-20261110`

## Status
**BLOCKED — no installable APK was produced.**

The user authorized exactly one Android build. That single debug build was attempted in GitHub Actions run [42776828452](https://github.com/aliabinyahya-max/ludo_game/actions/runs/42776828452) and failed before artifact upload.

## Build failure evidence
- Gradle task: `:flutter_angle:configureCMakeDebug[arm64-v8a]`
- Failure: CMake `3.31.4` was not found in the Android SDK, PATH, or `cmake.dir`.
- Additional plugin compatibility warning: `shared_preferences_android` requires compile SDK 36; project compile SDK was 35 at the time.
- Source follow-up: compile SDK raised to 36 and the workflow now provisions CMake 3.31.4 before the build step.
- These follow-up changes have not been compiled because the one-build authorization was consumed.

## Physical test matrix — not executed
- Install and first launch on a physical Android device.
- 2-, 3-, and 4-player Pass & Play.
- All four AI levels and tactical decisions.
- 3D board rendering, touch selection, animation smoothness, GPU stability, and 2D fallback.
- Sound on/off, Arabic/English, and all three themes.
- Save a match, force-close, relaunch, and resume at the correct turn.
- Complete a match and verify winner, capture count, duration, and history.
- Background/foreground, rotation, memory pressure, and crash-free session.

## Acceptance rule
Do not mark Phase 08 complete without a successful APK artifact and recorded physical-device results. No second build was attempted or authorized.
