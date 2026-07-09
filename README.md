# Inkflow

Inkflow is a cross-platform blog application for Android, iOS, and web, built with Flutter. It follows an MVVM layered architecture (UI → domain → data), uses `go_router` for declarative, deep-linkable navigation, `provider` for dependency injection and state, and renders posts written in Markdown. The data layer sits behind a `PostRepository` interface backed by an in-memory mock today, with a Firebase (Firestore) backend planned.

**Status:** In progress — frontend phase.

## Project structure

```text
lib/
├── domain/
│   └── models/            # Immutable domain models: Author, Post, Comment
├── data/
│   └── repositories/      # PostRepository (abstract) + MockPostRepository
├── routing/               # go_router configuration (nav shell + deep links)
├── ui/
│   ├── core/              # Material 3 theme and shared widgets
│   └── features/          # One folder per feature, each with views/ + view_models/
│       ├── feed/
│       ├── post_detail/
│       ├── editor/
│       ├── auth/
│       └── profile/
└── main.dart              # App entry point; wires theme, router, and providers
```

## Getting started

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).

```bash
# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome
```

To run on a connected Android/iOS device or emulator, use `flutter run` and pick the target, or `flutter devices` to list what's available.

## Development

```bash
flutter analyze   # static analysis
flutter test      # unit and widget tests
```
