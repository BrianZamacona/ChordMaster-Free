# ChordMaster-Free — Copilot Workspace Instructions

## Overview
This workspace follows strict Clean Architecture and Flutter best practices. All contributors and AI agents should adhere to the conventions and workflows described here and in the [README.md](../README.md).

---

## Build & Test Commands
- **Install dependencies:** `flutter pub get`
- **Run app:** `flutter run`
- **Run all tests:** `flutter test`
- **Run with coverage:** `flutter test --coverage` then `genhtml coverage/lcov.info -o coverage/html`
- **Widget tests:** `flutter test test/widget/`
- **Analyze:** `flutter analyze --no-fatal-infos`

See [README.md](../README.md#🚀-quick-start) and [README.md](../README.md#🧪-running-tests) for more.

---

## Architecture & Conventions
- **Clean Architecture:** Four layers (Presentation, Application, Domain, Infrastructure/Data).
- **State Management:** Use Riverpod providers only (no setState in feature code).
- **Persistence:** Use Hive for all local storage; boxes are lazily opened.
- **Navigation:** Use GoRouter with named routes and deep-link support.
- **Feature Structure:** Each feature in `lib/features/<feature_name>/` with `data/`, `domain/`, `presentation/` subfolders.
- **Core Utilities:** Shared code in `lib/core/`.
- **Testing:** Place tests in `test/unit/`, `test/widget/`, `test/integration/`. Use fakes/mocks for services. See `test/widget_test.dart` for patterns.
- **Linting:** Follows `flutter_lints` in [analysis_options.yaml](../analysis_options.yaml).

---

## Common Pitfalls
- **Flutter SDK:** Requires Flutter ≥ 3.41.5, Dart ≥ 3.11.0.
- **Android:** Set unique `applicationId` in `android/app/build.gradle.kts`.
- **Local Properties:** Ensure `android/local.properties` has correct `flutter.sdk` path.
- **Do not edit generated files** in platform folders.
- **Release Signing:** Update signing configs for production builds.

---

## Key Files & References
- [README.md](../README.md): Canonical source for architecture, structure, and workflow.
- [lib/main.dart](../lib/main.dart): App entry, Hive init, ProviderScope.
- [lib/core/](../lib/core/): Core models, services, utilities.
- [lib/features/](../lib/features/): Feature modules.
- [test/widget_test.dart](../test/widget_test.dart): Widget test patterns.
- [analysis_options.yaml](../analysis_options.yaml): Lint rules.
- [android/app/build.gradle.kts](../android/app/build.gradle.kts): Android build config.

---

## Example Prompts
- "Add a new feature module for scale visualization."
- "Write a widget test for the ChordListScreen."
- "Update the navigation to support deep links for the tuner."
- "Refactor audio playback to use a new service implementation."

---

## Next Steps & Customizations
- Consider creating agent customizations for:
  - Automated test writing for new features
  - Lint rule enforcement and autofix
  - Architecture diagram generation
- For complex workspaces, use `applyTo` patterns to scope instructions to specific folders (e.g., only `lib/features/` or `test/widget/`).

---

**Link, don’t embed:** Always link to canonical docs (README, analysis_options.yaml, etc.) instead of duplicating content.
