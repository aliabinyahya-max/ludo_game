# Android build blocker diagnosis and source-level correction

## Confirmed failures

The Android build history contains two distinct blockers:

1. An earlier run failed while applying the Flutter Gradle plugin because the project used AGP `8.2.1`, below the Flutter 3.44.9 requirement documented in that run (`8.6.0+`). This was corrected by moving to AGP `8.11.1`.
2. The one authorized debug APK attempt later failed at `:flutter_angle:configureCMakeDebug[arm64-v8a]` because CMake `3.31.4` was not installed in the runner. That attempt also reported that `shared_preferences_android` requires compile SDK 36; compile SDK was subsequently raised from 35 to 36.

The one-time build authorization has been consumed. No further APK/AAB build or Gradle build task is authorized by this phase.

## Current pinned Android toolchain

| Component | Repository configuration | Audit |
|---|---:|---|
| Flutter | 3.44.9 (CI) | Pinned |
| Java | 17 (CI) | Meets AGP 8.11 requirement |
| Android Gradle Plugin | 8.11.1 | Requires Gradle 8.13+ |
| Gradle wrapper | 8.14.3 | Above AGP minimum |
| Kotlin Android plugin | 2.2.20 | Kept with the current Gradle 8.14 line |
| compile SDK | 36 | Satisfies the reported plugin requirement; within AGP 8.11 API support |
| Build Tools | 35.0.0 | Explicit CI provisioning |
| NDK | 28.2.13676358 | Explicitly pinned by app Gradle config and CI provisioning |
| CMake | 3.31.4 | Explicit CI provisioning; addresses the reported missing component |
| min SDK | 21 | Unchanged |
| target SDK | 34 | Release-policy review remains separate |

AGP 8.11 requires Gradle 8.13 or newer, uses JDK 17, and supports up to API 36. The wrapper at 8.14.3 is above the documented minimum. See the official [AGP compatibility table](https://developer.android.com/build/releases/about-agp) and [AGP 8.11 release notes](https://developer.android.com/build/releases/agp-8-11-0-release-notes).

## Source and CI corrections in this phase

- The workflow now provisions and verifies the exact Android SDK packages declared/required by the project: Android platform 36, Build Tools 35.0.0, NDK 28.2.13676358, CMake 3.31.4, and platform-tools.
- Java 17 and Flutter 3.44.9 remain pinned in CI.
- The workflow has been made validation/preflight-only. The APK build and artifact upload job was removed, preventing an accidental repeat of the consumed one-time build.
- No app package ID, signing key, target SDK policy, or release configuration was guessed or changed.

## Verification limits

The workflow's SDK provisioning and package checks will be exercised by the next ordinary GitHub Actions validation run. This phase does not execute Gradle, compile native code, create APK/AAB files, or establish device compatibility. A successful SDK preflight is not proof of a successful Android build.

## Result

**SOURCE/CI HARDENING COMPLETED — ANDROID BUILD STILL UNVERIFIED.** The previously missing CMake and pinned NDK are now part of explicit CI SDK provisioning; the next validation run must confirm the provisioning step. A new explicit build authorization is required before any Android packaging attempt.


## Follow-up CI failure and correction (2026-11-10)

The first SDK-preflight workflow run failed inside `android-actions/setup-android@v3` because it attempted to install the obsolete SDK package `tools` (`Warning: Failed to find package 'tools'`). The SDK package installation, dependency resolution, analyzer and tests were therefore skipped.

Correction: removed that setup action and now locate/use the Android command-line SDK manager already provisioned on GitHub-hosted Ubuntu runners. The workflow checks the sdkmanager executable and version before installing/verifying the pinned SDK platform, Build Tools, NDK and CMake packages. This remains a non-build workflow; no Gradle task or APK/AAB packaging is invoked.

Correction commit: `b6bf7ec398922dc0f4cd5373eb1174ca9cb98761`. Await the subsequent CI result before declaring the phase verified.

## Follow-up CI failure: license pipeline SIGPIPE (2026-11-10)

Runs `42780479279` and `42780483585` both reached `sdkmanager --licenses`, printed `All SDK package licenses accepted`, then failed with `yes: standard output: Broken pipe` (exit code 1). The root cause was `set -o pipefail`: `sdkmanager` closed its input after accepting the licenses, so the `yes` producer received SIGPIPE and caused the pipeline to be marked failed even though the SDK manager operation succeeded.

The workflow now disables `pipefail` only around the license pipeline, captures `${PIPESTATUS[1]}` immediately, checks the actual sdkmanager exit code, and restores `pipefail` before package installation and verification. This preserves real SDK manager failures while ignoring the expected producer-side SIGPIPE. Fix commit: `31dea195c8058eed8ea5aec7675083fbbf3a8250`.

Validation is pending on a fresh workflow run. The workflow remains preflight-only and contains no Gradle, APK, or AAB build step.