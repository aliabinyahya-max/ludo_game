# Phase 08 — Physical Device Test Status

Date: 2026-11-10
Branch: `feat/3d-board-animations-phase-03-04-20261110`

## Build and installation evidence

**Debug APK build: PASS; installation: user-confirmed.**

- Authorized one-time build run: [42781991508](https://github.com/aliabinyahya-max/ludo_game/actions/runs/42781991508)
- Build command: `flutter build apk --debug`
- Build and artifact upload steps: success.
- User confirmed the APK was installed on the Android phone.
- No additional build is authorized or planned in this phase unless the user explicitly grants a new authorization.

## Device test results reported by the user

| Scenario | Result | Evidence |
|---|---|---|
| App launch | PASS | User reported that the app opened normally |
| Main menu visibility | PASS | User reported that the first interface was clear; screenshot supplied |
| Start match navigation | FAIL | User reported that tapping Start opens a dark/blank match screen; screenshot shows the Ludo app bar and back arrow but no board |
| 3D board rendering | FAIL / not initialized visibly | Same screenshot; root cause not yet proven |
| 2D fallback after renderer failure | Pending | Source fallback added; requires a new installable build for device confirmation |

## Source correction in progress

- Added an 8-second 3D initialization timeout in `GameScreen`.
- Added 3D setup/render error callbacks.
- On initialization timeout or reported setup/render exception, the game switches to the existing 2D board and displays a localized fallback message.
- Added a widget regression test for the timeout fallback.
- CI validation is validation-only; no APK/AAB build is included.

## Remaining physical-device acceptance

A new APK is required to verify the source correction on the phone. Until the user separately authorizes another build and installs the resulting artifact, the following remain pending:
- Verify 2D fallback appears instead of a blank screen.
- Verify 3D rendering and GPU stability on the device.
- Verify board touch selection, token movement, dice, animations, and full match completion.
- Verify AI levels, sound, themes, languages, save/resume, and match history on device.

## Acceptance rule

Do not mark Phase 08 complete. The initial app launch passed, but starting a match currently fails on the installed build. Keep the phase open until the corrected build is separately authorized, installed, and the device test matrix passes.
