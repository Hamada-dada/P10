# Overblik

[![Flutter CI](https://github.com/Hamada-dada/P10/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/Hamada-dada/P10/actions/workflows/flutter-ci.yml)

Overblik ("Overview") is a family calendar app built with Flutter and Supabase. Parents and children share activities, checklists, and rewards through a single calendar, with role-based access so children get a restricted view.

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
| State management | Plain `StatefulWidget` + service singletons + `ChangeNotifier` controllers (no Provider/Riverpod/BLoC) |

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
└── test/
supabase/
└── migrations/            # Database migrations
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

## Database

SQL migrations for the Supabase project live under [`supabase/migrations`](supabase/migrations).

## Unfinished scaffolding

`lib/controllers/activity_controller.dart`, `calendar_controller.dart`, `reward_controller.dart`, and `lib/models/family.dart`, `reminder.dart`, `recurrence_rule.dart` are empty files left over from the project's initial MVC-style scaffold. They are not imported anywhere. Their responsibilities are currently covered elsewhere:

- Activity/calendar/reward state → `services/activity_service.dart`, `calendar_service.dart`, `reward_service.dart` + `StatefulWidget`/`FutureBuilder` in the screens (the `controllers/` pattern used for `theme_controller.dart`/`locale_controller.dart` was never extended to these).
- Family data → read as raw `familyId`/`familyName`/`familyCode` fields in `FamilyService`/`ProfileService`, no `Family` model class.
- Reminders → handled as scheduled local notifications in `NotificationService`, no `Reminder` model.
- Recurrence rules → already implemented via the `ActivityRecurrence` enum and `recurrenceInterval`/`recurrenceEndDate` fields in `models/activity.dart`; `recurrence_rule.dart` is superseded.

Treat these six files as dead scaffolding: either delete them, or pick one up and actually implement it (e.g. migrating activity/calendar/reward state to the controller pattern already used for theme/locale).

## CI

[`.github/workflows/flutter-ci.yml`](.github/workflows/flutter-ci.yml) runs `flutter analyze` and `flutter test` on every push/PR to `main`.

## License

All rights reserved — see [`LICENSE`](LICENSE).
