# Phase 09 — Findings Fixes and Retest

Date: 2026-11-10
Branch: `feat/3d-board-animations-phase-03-04-20261110`

## Findings selected for source-level correction
The Phase 06 audit found that the rules engine relied on the menu to provide a valid roster and did not independently protect its public API from malformed match rosters or foreign token objects.

## Changes made
- `LudoEngine` now rejects fewer than two or more than four players.
- `LudoEngine` now rejects duplicate player colors.
- `canMoveToken` now rejects a token object that is not owned by the engine's match roster.
- Added regression tests for each invariant, including rejection through `applyMove`.

## Validation
- Changes are committed on the feature branch.
- GitHub Actions validation run `42740444794` completed: `flutter analyze` passed, but `flutter test` failed (46 passed, 1 failed).
- Failure: the foreign-token regression test showed `canMoveToken` accepted an external `LudoToken` with matching color/id because ownership was not checked by object identity.
- Corrective commit `a6685901ea8ed7f79991425b631f379d09669046` adds an identity-membership check against the current match roster before validating a move. `applyMove` inherits the rejection through `canMoveToken`.
- The corrective commit was pushed to the feature branch. A fresh validation result has not yet been retrieved; stage remains pending CI confirmation.
- No APK/AAB build was run.

## Remaining findings not fixed in this phase
- Four selectable AI difficulty levels remain unimplemented.
- Sound effects, statistics/history, save/resume, theme selection, and language localization remain open product requirements.
- Physical 3D/GPU and touch testing remains blocked by the no-build authorization boundary.

## Stage result
**SOURCE FIX APPLIED — FIRST VALIDATION FAILED, CORRECTION COMMITTED, RETEST PENDING.** The failed run was not treated as a pass. No APK/AAB or platform build was run.
