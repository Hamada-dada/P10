# Overblik

[![Flutter CI](https://github.com/Hamada-dada/P10/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/Hamada-dada/P10/actions/workflows/flutter-ci.yml)

Overblik ("Overview") is a family calendar app built with Flutter and Supabase. Parents and children share activities, checklists, and rewards through a single calendar, with role-based access so children get a restricted or full view depending on parental settings.

## Features

- **Shared family calendar** — daily, weekly, and monthly views of activities
- **Role-based access** — parents have full control; children have extended or limited access depending on their role
- **Activities** — create activities with checklists, participants, recurrence, and rewards
- **Child login by code** — children sign in with a family-issued login code instead of email/password
- **Rewards** — direct and streak-based rewards tied to activities
- **Notifications** — local push notifications and per-user notification preferences
- **Offline support** — recent profiles, family data, and activities are cached locally and used as a fallback when the network is unavailable
- **Localization** — Danish and English

## Tech stack

| Layer | Technology |
|---|---|
| Client | Flutter (iOS, Android, Web, Desktop) |
| Backend | [Supabase](https://supabase.com) (PostgreSQL, Auth, RPC functions) |
| State management | Flutter's built-in state management: `StatefulWidget`, service classes and `ChangeNotifier` controllers |

## Project structure

```
overblik/
├── lib/
│   ├── main.dart          # Entry point, Supabase init, global error handling
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable UI components
│   ├── models/            # Data models
│   ├── services/          # Business logic (singletons)
│   ├── repositories/      # Data access layer (Supabase + local cache)
│   ├── controllers/       # App-wide ChangeNotifiers (theme, locale)
│   ├── core/               # Theme, constants, config, utilities
│   └── l10n/               # Localization (da/en)
├── android/, ios/, web/, macos/, linux/, windows/
├── test/
└── supabase/
    └── functions/         # Supabase edge functions (child login)
```

## Architecture notes

- **Repository pattern**: an abstract `ActivityRepository` is implemented by `SupabaseActivityRepository`, which falls back to `LocalActivityCache` when a request fails, so the app stays usable offline.
- **Auth**: parents authenticate with email/password; children authenticate via a Supabase RPC (`child-login`) using a short login code issued by a parent.
- **Navigation**: imperative `Navigator.push`, no named routes or routing package.
- **RPC functions**: multi-step operations that touch several tables (parent join/approval, child login, family + profile fetch) are implemented as Supabase RPC functions rather than client-side transactions.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.11.4)
- A [Supabase](https://supabase.com) project (URL + publishable/anon key)

### Setup

```bash
cd overblik
flutter pub get
```

Configure your Supabase project in [`lib/core/supabase_config.dart`](overblik/lib/core/supabase_config.dart):

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Then run:

```bash
flutter run
```

### Tests & analysis

```bash
flutter analyze
flutter test
```

## Backend

The Supabase edge function for child login lives in [`overblik/supabase/functions/child-login`](overblik/supabase/functions/child-login). Multi-step operations are implemented as Supabase RPC functions with row-level security in the database.

## CI

[`.github/workflows/flutter-ci.yml`](.github/workflows/flutter-ci.yml) runs `flutter analyze` and `flutter test` on every push/PR to `main`.

## License

All rights reserved — see [`LICENSE`](LICENSE).
