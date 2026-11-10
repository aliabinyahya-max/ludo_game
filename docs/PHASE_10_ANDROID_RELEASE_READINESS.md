# Phase 10 — Android Release Readiness Audit

Date: 2026-11-10
Branch: `feat/3d-board-animations-phase-03-04-20261110`
Audit type: source/configuration review and one previously authorized debug build attempt; no build in this phase.

## Verified repository configuration
- Flutter CI: 3.44.9
- Java: 17
- Android Gradle Plugin: 8.11.1
- Kotlin Android plugin: 2.2.20
- Gradle wrapper: 8.14.3
- Compile SDK: 36
- Build Tools (CI preflight): 35.0.0
- NDK: 28.2.13676358
- CMake: 3.31.4
- Target SDK: 34
- Minimum SDK: 21
- Android manifest label: `لودو`

AGP 8.11 requires Gradle 8.13+ and JDK 17, and supports up to API 36. The configured wrapper and Java satisfy those version requirements.

## Phase 10 execution status
The only authorized debug APK build attempt failed at `:flutter_angle:configureCMakeDebug[arm64-v8a]` because CMake 3.31.4 was missing from the runner. The same attempt reported a compile SDK 36 requirement from `shared_preferences_android`; compile SDK was raised to 36 afterward.

The CI workflow now explicitly installs and verifies Android platform 36, Build Tools 35.0.0, NDK 28.2.13676358, CMake 3.31.4, and platform-tools. All Android build/artifact jobs have been removed from CI so the consumed one-time build cannot run accidentally.

## Remaining release blockers
1. Android namespace and application ID remain `com.example.ludo_game`. A permanent package ID requires a separate user decision.
2. Release build type still uses `signingConfigs.debug`. A protected production keystore and secret-handling design are required.
3. Target SDK remains 34. Confirm the current Play policy and choose the final target before release.
4. Launcher icon still uses the Android platform default; a designed launcher/adaptive icon is outstanding.
5. The CMake/NDK/SDK provisioning correction has not yet been confirmed by a subsequent CI run.
6. The Android Gradle configuration, native compilation, APK packaging, and device runtime remain unverified.
7. No APK/AAB was produced or uploaded. No physical-device acceptance test has been performed.

## Result
**SOURCE AUDIT COMPLETED — NOT RELEASE READY.** CI toolchain provisioning has been hardened, but until a non-build CI run confirms SDK installation and a separately authorized build succeeds, Android packaging remains unverified. The single prior build authorization remains consumed.


## Follow-up CI result — 2026-11-10

The first SDK-preflight run failed before package installation because `android-actions/setup-android@v3` requested the obsolete SDK package `tools`. The workflow was corrected to use the Android command-line SDK manager already present on the hosted Ubuntu runner, then explicitly install and verify the pinned SDK/NDK/CMake components. The correction is committed as `b6bf7ec398922dc0f4cd5373eb1174ca9cb98761`.

The next non-build CI run must pass SDK provisioning, dependency resolution, analysis and tests. Android packaging and device execution remain unverified.
