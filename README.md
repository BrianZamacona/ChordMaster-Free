# 🎸 ChordMaster Free

[![CI](https://github.com/BrianZamacona/ChordMaster-Free/actions/workflows/ci.yml/badge.svg)](https://github.com/BrianZamacona/ChordMaster-Free/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.5-blue.svg)](https://flutter.dev)

> **Free, offline-first music learning app for guitarists, pianists and musicians of all levels.**  
> No subscription. No internet required. Just music.

---

## ✨ Features

| # | Module | Description |
|---|--------|-------------|
| 1 | 🎸 **Chord Library** | Browse 1000+ chords across all instruments with finger diagrams and audio playback |
| 2 | 🎵 **Scale Explorer** | Visual scale diagrams with interval highlighting across the full fretboard |
| 3 | 🎙️ **Guitar Tuner** | Chromatic tuner using the device microphone with cents deviation display |
| 4 | 🥁 **Metronome** | Precision metronome with tap-tempo, subdivision and custom time signatures |
| 5 | 🔗 **Chord Progressions** | Build, save and loop chord progressions with strumming pattern display |
| 6 | 👂 **Ear Training** | Interval, chord and melody recognition exercises with adaptive difficulty |
| 7 | 🎮 **Rhythm Game** | Tap-along rhythm challenges that improve your internal pulse and timing |
| 8 | 🎼 **Improvisation** | Backing tracks with scale overlays to guide freestyle soloing practice |
| 9 | 📚 **Song Library** | Offline song catalog with chord sheets, tabs and play-along mode |
| 10 | 🎹 **Composition Studio** | Multi-track MIDI-style composer for sketching original song ideas |
| 11 | 💆 **Health & Wellness** | Warm-up routines, hand stretches and practice session timers |
| 12 | 📋 **Community Board** | Local bulletin board for saving tips, links and shared resources |
| 13 | 🏆 **Achievements** | Gamified progress tracking with streaks, badges and XP milestones |
| 14 | ⚙️ **Settings** | Theme customisation, instrument selection and notification preferences |

---

## 🏛️ Architecture

ChordMaster Free follows **Clean Architecture** with a strict separation of concerns across four layers:

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│   (Flutter Widgets · Screens · GoRouter · Riverpod Providers)│
└───────────────────────┬─────────────────────────────────────┘
                        │ calls
┌───────────────────────▼─────────────────────────────────────┐
│                      Application Layer                       │
│          (Use Cases · State Notifiers · DTOs)                │
└───────────────────────┬─────────────────────────────────────┘
                        │ depends on (abstractions)
┌───────────────────────▼─────────────────────────────────────┐
│                        Domain Layer                          │
│        (Entities · Repository Interfaces · Value Objects)    │
└───────────────────────┬─────────────────────────────────────┘
                        │ implemented by
┌───────────────────────▼─────────────────────────────────────┐
│                      Infrastructure Layer                    │
│       (Hive · just_audio · Microphone · File System)         │
└─────────────────────────────────────────────────────────────┘
```

**Key design decisions:**
- All state is managed through **Riverpod** providers — no `setState` in feature code.
- **Hive** is the single source of truth for persisted data; all boxes are lazily opened.
- Audio is abstracted behind a `AudioService` interface so the underlying engine can be swapped.
- Navigation is handled exclusively by **GoRouter** with named routes and deep-link support.

---

## 🛠️ Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| [Flutter](https://flutter.dev) | 3.41.5 | Cross-platform UI framework |
| [Riverpod](https://riverpod.dev) | 2.6.1 | Compile-safe state management |
| [Hive](https://docs.hivedb.dev) | 2.2.3 | Fast, lightweight local database |
| [just_audio](https://pub.dev/packages/just_audio) | 0.9.46 | High-quality audio playback |
| [record](https://pub.dev/packages/record) | 5.2.1 | Microphone capture for tuner |
| [fl_chart](https://pub.dev/packages/fl_chart) | 0.68.0 | Pitch and progress visualisations |
| [go_router](https://pub.dev/packages/go_router) | 13.2.5 | Declarative routing and deep links |
| [google_fonts](https://pub.dev/packages/google_fonts) | 6.3.3 | Beautiful typography (cached locally) |
| [lottie](https://pub.dev/packages/lottie) | 3.3.2 | Smooth achievement animations |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | 17.2.4 | Practice reminders |

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/BrianZamacona/ChordMaster-Free.git
cd ChordMaster-Free

# 2. Install dependencies
flutter pub get

# 3. Launch on a connected device or emulator
flutter run
```

> **Requirements:** Flutter SDK ≥ 3.41.5, Dart SDK ≥ 3.11.0

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/          # App-wide constants (colors, strings, sizes)
│   ├── errors/             # Failure types and error handling
│   ├── router/             # GoRouter configuration and route definitions
│   ├── theme/              # ThemeData, color schemes, text styles
│   └── utils/              # Pure helper functions
│
├── features/
│   ├── chord_library/
│   │   ├── data/           # Hive boxes, JSON parsing, repository impl
│   │   ├── domain/         # Chord entity, ChordRepository interface
│   │   └── presentation/   # ChordListScreen, ChordDetailScreen, providers
│   ├── scale_explorer/
│   ├── tuner/
│   ├── metronome/
│   ├── chord_progressions/
│   ├── ear_training/
│   ├── rhythm_game/
│   ├── improvisation/
│   ├── song_library/
│   ├── composition_studio/
│   ├── health_wellness/
│   ├── community_board/
│   ├── achievements/
│   └── settings/
│
└── main.dart               # App entry point, Hive init, ProviderScope

assets/
├── audio/                  # Chord audio samples, backing tracks
├── data/                   # JSON chord/scale databases
└── images/                 # Icons, illustrations

test/
├── unit/                   # Domain logic and use case tests
├── widget/                 # Widget tests per feature
└── integration/            # End-to-end flow tests
```

---

## 🧪 Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run a specific test file
flutter test test/unit/chord_library_test.dart

# Run widget tests only
flutter test test/widget/
```

---

## 🔄 CI / CD

| Trigger | Workflow | Action |
|---------|----------|--------|
| Push / PR → `main`, `develop` | `ci.yml` | Lint + analyse + full test suite |
| Push tag `v*` (e.g. `v1.2.0`) | `release.yml` | Build release APK, upload as artifact |

Releases are created by tagging the commit:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

The release APK is available under **Actions → Release APK → Artifacts**.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository and create a feature branch: `git checkout -b feat/my-feature`
2. **Write tests** for any new business logic.
3. Ensure the suite passes: `flutter test`
4. Ensure analysis is clean: `flutter analyze --no-fatal-infos`
5. **Open a Pull Request** against `develop` with a clear description of your changes.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon) for our code of conduct and detailed guidelines.

---

## 🗺️ Roadmap

- [ ] **v1.1** — iPad / tablet layout support
- [ ] **v1.2** — MIDI device input for tuner and composition studio
- [ ] **v1.3** — Export chord progressions to PDF / MusicXML
- [ ] **v1.4** — Dark / AMOLED theme variants
- [ ] **v2.0** — Optional cloud sync via user-supplied backend (self-hostable)

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

```
MIT License  Copyright (c) 2024 ChordMaster Free Contributors
```

---

## ☕ Support the Project

If ChordMaster Free has helped your musical journey, consider buying the developer a coffee!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/chordmasterfree)

---

<p align="center">Made with ❤️ and Flutter · Star ⭐ the repo if you find it useful!</p>
