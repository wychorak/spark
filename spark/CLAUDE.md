# SPARK – Project Memory & Architecture Rules

## Dev Server
- **Port: 9091** (PROTECTED — never change, never use 9090 or other ports)
- Server: `spark-server.js` (Node.js static server at repo root)
- Start: `preview_start("spark")` in launch.json → port 9091
- Build: `flutter build web --release` from `spark/` directory
- After build: restart preview server to serve new files

## Project Overview
Spark – Cherry blossom dating + friends + FWB app for iOS & Android (Flutter single codebase + Supabase backend).
Main colors: `#FF6B9D` (soft pink) + `#FFF5F7` (cream). Style: light cherry blossom aesthetic, glassmorphism.
App language: **Polish** (all user-facing strings in Polish).
Support email: sparksupport@gmail.com

## Tech Stack
- **Frontend**: Flutter 3.24+ (Dart 3.5+)
- **State**: Riverpod 2.0 (riverpod_annotation + code generation)
- **Routing**: go_router
- **Backend**: Supabase (PostgreSQL 15 + Auth + Storage + Realtime + Edge Functions + PostGIS + Vault)
- **Payments**: in_app_purchase (Apple/Google) + Stripe fallback (web)
- **Push**: Firebase Cloud Messaging + APNs
- **Analytics**: Mixpanel + Supabase Analytics
- **Crash Reporting**: Sentry (sentry_flutter)
- **Audio**: just_audio + spotify_sdk (30s Spotify preview on profile)
- **Location**: PostGIS + geolocator + geocoding
- **Animations**: Lottie (lottie) + Rive (rive) + shimmer

## Folder Structure (Clean Architecture)
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/        # Colors, strings, dimensions, enums
│   ├── theme/            # AppTheme, Y2K neon theme data
│   ├── router/           # GoRouter config + guards
│   ├── utils/            # Helpers, validators, formatters
│   ├── extensions/       # Dart extensions
│   └── errors/           # Custom exceptions, failure classes
├── features/
│   ├── auth/             # Login, register, age gate, biometric
│   │   ├── data/         # Repositories impl, data sources
│   │   ├── domain/       # Entities, repository interfaces
│   │   └── presentation/ # Screens, widgets, providers
│   ├── onboarding/       # Profile setup, photo upload, interests
│   ├── discovery/        # Swipe cards, filters, matching algorithm
│   ├── matching/         # Match list, instant match animation
│   ├── chat/             # Realtime messaging, media sharing
│   ├── profile/          # View/edit profile, Spotify, photos
│   ├── premium/          # Paywall, subscription management
│   ├── settings/         # App settings, notifications, privacy
│   ├── safety/           # Block, report, photo verification
│   └── notifications/    # Push notification handling
├── shared/
│   ├── widgets/          # Reusable UI components
│   ├── providers/        # Global providers (auth state, user, location)
│   └── models/           # Shared data models
└── l10n/                 # Localization (Polish primary)
```

## Coding Conventions
- **Language**: Dart 3.5+ with null safety, pattern matching, sealed classes
- **Naming**: snake_case for files, camelCase for variables/methods, PascalCase for classes
- **Riverpod**: Always use @riverpod annotation (code generation), never raw Provider()
- **Models**: Use freezed + json_serializable for all data classes
- **Error handling**: Use Either<Failure, T> pattern (fpdart) for repository methods
- **Imports**: Use relative imports within features, package imports across features
- **Tests**: Unit tests for providers/repos, widget tests for key screens, integration tests for flows
- **Comments**: Only where logic is non-obvious. No boilerplate comments.

## Security Rules (CRITICAL)
- **NO hardcoded secrets** – all keys via --dart-define or .env (envied package)
- **Supabase RLS on EVERY table** – no exceptions
- **Supabase service_role key NEVER in client code** – only in Edge Functions
- **Biometric auth** via local_auth for sensitive actions
- **Secure storage** via flutter_secure_storage for tokens
- **Age gate 18+** enforced at registration AND in Supabase RLS
- **Photo verification** flow before full access
- **Rate limiting** on Edge Functions
- **Input sanitization** on all user inputs
- **HTTPS only** – certificate pinning in production

## Account Types & Color Logic
| Type         | Color Code | Polish Label    | Badge Color |
|-------------|-----------|-----------------|-------------|
| Relationship | #FF1493   | Związek         | Deep Pink   |
| Friends      | #00FF7F   | Znajomi         | Green       |
| FWB          | #FF8C00   | FWB             | Orange      |

Users can have multiple active modes. Card border + badge reflects their current mode.

## Database Naming Convention
- Tables: snake_case plural (e.g., `user_profiles`, `swipe_actions`)
- Columns: snake_case (e.g., `created_at`, `is_verified`)
- Indexes: `idx_{table}_{column}`
- RLS Policies: `{table}_{action}_{who}` (e.g., `user_profiles_select_authenticated`)
- Functions: `fn_{description}` (e.g., `fn_calculate_distance`)
- Triggers: `trg_{table}_{event}` (e.g., `trg_matches_after_insert`)

## Git Conventions
- Branch: `feature/{name}`, `fix/{name}`, `chore/{name}`
- Commits: Conventional Commits (feat:, fix:, chore:, docs:)
- PR: Always squash merge to main

## Premium Features (Spark Premium)
- Unlimited swipes (free = 50/day)
- See who liked you
- Superlike (10/month premium, 1/day free)
- Rewind last swipe
- Advanced filters (height, education, zodiac)
- Read receipts in chat
- Boost profile (1/month)
- No ads
- Priority in discovery algorithm
