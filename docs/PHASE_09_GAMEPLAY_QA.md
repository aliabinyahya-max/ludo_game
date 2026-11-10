# Phase 9 — Gameplay QA Checklist

## Scope and execution status

This phase covers automated widget-level gameplay validation and a manual device test plan.
Automated checks run through the validation-only GitHub Actions workflow. No APK/AAB build,
package, release, merge, or deployment is part of this phase.

**Device execution:** Pending an explicit, separate authorization to build an installable Android
package. Do not mark the device scenarios below as passed until they have been executed on a
physical Android device.

## Automated coverage

- Menu requires at least two active seats and at least one human player.
- Menu cycles each seat through human, AI, and empty states.
- Menu starts a match using the selected human/AI configuration.
- Dice input is locked during the third-consecutive-six cancellation transition.
- A human player with no legal move passes to the next player.
- Human/AI turn cycling is exercised for two, three, and four player configurations.
- Core rules and AI selection are covered by `test/ludo_logic_test.dart`.

## Physical-device checklist (not yet executed)

1. Launch the app and verify the menu fits the device screen without overflow.
2. Verify the start button remains disabled with fewer than two active seats or no human seat.
3. Configure two humans and start a match; verify board, player labels, and dice controls.
4. Configure one human plus one AI; verify AI takes its turn without user input.
5. Repeat with three and four active seats.
6. Roll a six twice in the same turn, then roll a third six; verify the third roll is cancelled,
   no token can be moved, and the next player's turn begins after the transition.
7. Attempt to tap the dice repeatedly while it is rolling and during the cancelled-turn transition;
   verify no duplicate roll is accepted.
8. Make a move that captures an opponent on an unsafe cell; verify the captured token returns to base
   and the capturing player receives an extra roll.
9. Land on a safe cell occupied by an opponent; verify no capture occurs.
10. Move across an own-color block and verify the move remains legal; attempt to cross an opponent
    block and verify it is rejected.
11. Verify exact home entry, victory after all four tokens finish, and the return-to-menu control.
12. Play a complete match and observe animation smoothness, touch response, layout, and stability.

## Evidence to record during device execution

- Device model and Android version.
- App commit SHA and package version.
- Pass/fail for each numbered scenario.
- Screenshots or screen recording for failures.
- Reproduction steps and relevant log output for each defect.

## Release gate

Do not approve public release based only on widget tests. Complete the physical-device checklist,
resolve defects, and separately review Android release signing before distribution.
