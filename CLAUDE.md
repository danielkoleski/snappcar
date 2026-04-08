# CLAUDE.md — SnappCar

This file is the authoritative guide for AI assistants working in this repository.
Read it before writing any code or making architectural decisions.

---

## Project Overview

**SnappCar** is a mobile-first application (Android + iOS) that helps car owners track and
manage their vehicle maintenance history. The core goals are:

- Give owners a reliable record of every service, part replacement, and mileage check.
- Send proactive push-notification reminders so maintenance is never forgotten.
- Increase resale value and buyer confidence by providing a verifiable service history.
- Use AI to extract structured data from photos of invoices/receipts (NF-e, cupom fiscal).
- Long-term: connect owners with nearby workshops and online spare-parts suppliers.

The product ships as an MVP first. Prioritise speed of delivery and simplicity over
premature abstraction.

---

## Tech Stack

### Mobile (Frontend)
| Concern | Choice | Notes |
|---------|--------|-------|
| Framework | **Flutter** (Dart) | Best cross-platform UI consistency; single codebase for Android & iOS |
| State management | **Riverpod** | Type-safe, testable, works well with async Supabase calls |
| Navigation | **go_router** | Declarative routing, deep-link support |
| Push notifications | **Firebase Cloud Messaging (FCM)** via `firebase_messaging` | Required for both platforms |
| Local notifications | `flutter_local_notifications` | Scheduled reminders without network |
| Image picking | `image_picker` | Camera + gallery access for invoice photos |
| HTTP / REST | Supabase Flutter SDK (`supabase_flutter`) | Handles auth, realtime, storage, RPC |
| Form validation | `reactive_forms` | Consistent validation across all forms |

### Backend
| Concern | Choice | Notes |
|---------|--------|-------|
| Database | **Supabase** (PostgreSQL) | Auth, Realtime, Storage and Edge Functions in one platform |
| Auth | Supabase Auth | Email/password + Google OAuth (social login) |
| File storage | Supabase Storage | Invoice photos, vehicle photos |
| Serverless logic | **Supabase Edge Functions** (Deno/TypeScript) | AI invoice parsing, notification scheduling |
| AI / OCR | **Google Cloud Vision API** or **OpenAI GPT-4o** | Extract line items from invoice images |
| Push scheduling | **Firebase Admin SDK** inside Edge Functions | Server-side FCM push delivery |
| Car database | FIPE API (`parallelum.com.br/fipe/api`) | Brazilian vehicle catalogue (make/model/year) |

### Tooling
| Tool | Purpose |
|------|---------|
| `fvm` (Flutter Version Manager) | Pin Flutter SDK version per project |
| `dart format` + `flutter analyze` | Formatting and static analysis |
| `very_good_analysis` | Strict lint rules |
| `flutter_gen` | Type-safe asset and colour generation |
| GitHub Actions | CI: format check, analysis, unit tests on every PR |
| Melos (optional, if monorepo grows) | Manage multiple Dart packages |

---

## Repository Structure

```
snappcar/
├── lib/
│   ├── main.dart                  # App entry point; ProviderScope + GoRouter bootstrap
│   ├── app.dart                   # MaterialApp / theme / router wiring
│   ├── core/
│   │   ├── constants/             # App-wide constants (colors, strings, sizes)
│   │   ├── extensions/            # Dart extension methods
│   │   ├── router/                # go_router configuration and route guards
│   │   ├── theme/                 # ThemeData, text styles, color scheme
│   │   └── utils/                 # Pure utility functions (date helpers, formatters)
│   ├── data/
│   │   ├── models/                # Plain Dart classes (freezed + json_serializable)
│   │   ├── repositories/          # Repository interfaces + Supabase implementations
│   │   └── services/              # External service wrappers (FCM, Vision AI, FIPE)
│   ├── domain/
│   │   └── entities/              # Core business objects (if diverging from models)
│   └── features/
│       ├── auth/                  # Login, register, forgot password
│       │   ├── data/
│       │   ├── presentation/
│       │   │   ├── pages/
│       │   │   └── widgets/
│       │   └── providers/
│       ├── vehicles/              # Add/edit/view vehicles; FIPE lookup
│       ├── maintenance/           # Log maintenance; view history; schedule next
│       ├── mileage/               # Monthly mileage entry; chart of mileage over time
│       ├── invoices/              # Photo capture; AI parsing; line-item list
│       ├── notifications/         # Notification preferences; local + push setup
│       └── profile/               # User settings, account management
├── supabase/
│   ├── migrations/                # SQL migration files (numbered, sequential)
│   ├── functions/                 # Edge Functions (Deno TypeScript)
│   │   ├── parse-invoice/         # OCR + AI extraction endpoint
│   │   └── schedule-reminders/    # Cron-triggered push notification dispatcher
│   └── seed.sql                   # Development seed data
├── test/
│   ├── unit/                      # Repository & provider unit tests
│   ├── widget/                    # Widget tests per feature
│   └── integration/               # End-to-end flows (flutter_test driver)
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── android/
├── ios/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── .env.example                   # Required env vars (never commit .env)
└── CLAUDE.md                      # This file
```

---

## Database Schema (Supabase / PostgreSQL)

Key tables. All tables include `id uuid DEFAULT gen_random_uuid() PRIMARY KEY`,
`created_at timestamptz DEFAULT now()`, `updated_at timestamptz`.

### `profiles`
Extends Supabase `auth.users`. Created via trigger on `auth.users` insert.
```
id          uuid  FK → auth.users.id
full_name   text
avatar_url  text
```

### `vehicles`
```
id          uuid
owner_id    uuid  FK → profiles.id
make        text        -- e.g. "Volkswagen"
model       text        -- e.g. "Polo"
year        int
color       text
plate       text
fipe_code   text        -- FIPE table code
odometer    int         -- current km (updated when mileage entry is added)
photo_url   text
```

### `mileage_entries`
```
id            uuid
vehicle_id    uuid  FK → vehicles.id
recorded_km   int
recorded_at   date
notes         text
```

### `maintenance_records`
```
id              uuid
vehicle_id      uuid  FK → vehicles.id
title           text        -- e.g. "Troca de óleo"
description     text
performed_at    date
next_due_at     date        -- nullable; triggers reminder
next_due_km     int         -- nullable; km-based reminder
cost_brl        numeric(10,2)
workshop_name   text
invoice_id      uuid  FK → invoices.id  -- nullable
```

### `maintenance_templates`
Seeded from community/FIPE data. Read-only for users.
```
id              uuid
make            text        -- null = applies to all makes
model           text        -- null = applies to all models
title           text
interval_months int
interval_km     int
notes           text
```

### `invoices`
```
id              uuid
vehicle_id      uuid  FK → vehicles.id
photo_url       text        -- Supabase Storage path
ai_parsed_at    timestamptz -- null until Edge Function completes
raw_text        text        -- full OCR output
total_brl       numeric(10,2)
issued_at       date
```

### `invoice_items`
AI-extracted line items from an invoice.
```
id            uuid
invoice_id    uuid  FK → invoices.id
description   text
quantity      numeric
unit_price    numeric(10,2)
item_type     text  CHECK IN ('part', 'labor', 'other')
```

### Row-Level Security
Every table must have RLS enabled. The standard policy pattern is:
```sql
-- Select: owner only
CREATE POLICY "owner_select" ON vehicles
  FOR SELECT USING (owner_id = auth.uid());

-- Insert: authenticated user sets own id
CREATE POLICY "owner_insert" ON vehicles
  FOR INSERT WITH CHECK (owner_id = auth.uid());
```
Never skip RLS on tables that hold user data.

---

## Feature Descriptions

### 1. Vehicle Registration
- User selects make → model → year using cascading FIPE API dropdowns.
- On save, `maintenance_templates` matching make/model/year are copied as upcoming
  maintenance items with suggested due dates/km.

### 2. Mileage Tracking
- User logs odometer reading once a month.
- A push reminder fires on the 1st of each month if no entry exists for that month.
- Mileage delta triggers km-based maintenance alerts (e.g., oil change every 10 000 km).

### 3. Maintenance Records
- Free-form log: title, date, workshop, cost, notes, optional invoice.
- `next_due_at` / `next_due_km` fields drive the reminder system.
- The home screen shows a "Health Score" badge based on overdue items.

### 4. Invoice / NF-e AI Parsing
Flow:
1. User taps camera icon → `image_picker` opens.
2. Photo uploaded to Supabase Storage under `invoices/{user_id}/{uuid}.jpg`.
3. `invoices` row created with `ai_parsed_at = null`.
4. Supabase Realtime subscription in the app shows a "Processing…" indicator.
5. Storage trigger (or webhook) fires the `parse-invoice` Edge Function.
6. Edge Function sends image to Vision API / GPT-4o, parses response, writes
   `invoice_items` rows and updates `ai_parsed_at`.
7. Realtime update in the app reveals the extracted line items for user review/edit.

### 5. Push Notifications
- FCM token stored per device in a `device_tokens` table.
- `schedule-reminders` Edge Function runs via Supabase cron (pg_cron) nightly.
- It queries overdue or upcoming maintenance and sends FCM payloads.
- Users can opt out per notification type in Profile → Notifications.

---

## Development Workflow

### Setup
```bash
# 1. Install Flutter via fvm
fvm install          # reads .fvmrc for pinned version
fvm use

# 2. Install dependencies
flutter pub get

# 3. Copy environment file
cp .env.example .env
# Fill in: SUPABASE_URL, SUPABASE_ANON_KEY, OPENAI_API_KEY, etc.

# 4. Start Supabase locally
npx supabase start
npx supabase db reset   # applies all migrations + seed.sql

# 5. Run the app
flutter run
```

### Daily Commands
```bash
flutter analyze                     # Static analysis (must pass before PR)
dart format --set-exit-if-changed . # Formatting check
flutter test                        # All unit + widget tests
flutter test integration_test/      # Integration tests (requires a running device)
npx supabase functions serve        # Run Edge Functions locally
```

### Migrations
```bash
# Create a new migration
npx supabase migration new <name>

# Apply locally
npx supabase db reset

# Push to remote (staging/production)
npx supabase db push
```
Never edit existing migration files. Always create a new migration.

### Branch Strategy
```
main          →  production (protected, requires PR + CI green)
develop       →  integration branch; merge feature branches here first
feature/<name>   new features
fix/<name>       bug fixes
chore/<name>     non-functional changes (deps, config, docs)
```

### Pull Requests
- Must pass `flutter analyze` and `dart format` with zero warnings.
- Must include tests for new repositories and providers.
- PR description must describe what changed and why.

---

## Code Conventions

### Dart / Flutter
- Use `const` constructors wherever possible.
- All `Widget build()` methods should be short; extract sub-widgets into private
  classes (`_SomeSection`) or dedicated files when they exceed ~60 lines.
- Never call `Supabase.instance.client` directly in widgets. Always go through
  a repository class injected via Riverpod.
- Prefer `AsyncNotifierProvider` / `FutureProvider` over raw `FutureBuilder`.
- Use `freezed` for all data model classes (immutability + copyWith + equality).
- Do not use `dynamic`; type everything explicitly.
- Error handling: repositories return `Either<Failure, T>` or throw typed
  exceptions; providers catch and expose `AsyncError` state.

### Naming
| Entity | Convention | Example |
|--------|-----------|---------|
| Files | `snake_case` | `maintenance_repository.dart` |
| Classes | `PascalCase` | `MaintenanceRepository` |
| Variables / functions | `camelCase` | `fetchByVehicle()` |
| Constants | `lowerCamelCase` | `defaultPageSize` |
| Database columns | `snake_case` | `next_due_at` |
| Supabase table names | `snake_case`, plural | `maintenance_records` |

### Supabase Edge Functions
- Written in TypeScript (Deno).
- Each function lives in `supabase/functions/<function-name>/index.ts`.
- Use `Deno.env.get()` for secrets; never hard-code API keys.
- All functions must validate the incoming request (check `Authorization` header
  or verify it was called by Supabase service role).
- Return structured JSON: `{ data: T | null, error: string | null }`.

### Assets
- Run `flutter pub run build_runner build` after adding assets to regenerate
  `flutter_gen` files.
- Images: 1x in `assets/images/`, 2x and 3x in subdirectories.
- SVG icons preferred over PNG for UI elements.

---

## Environment Variables

All secrets are read from `.env` (never committed). Use `flutter_dotenv` on the
client and `Deno.env.get()` in Edge Functions.

```
# .env.example

# Supabase
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Supabase Edge Functions (server-side only)
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# AI
OPENAI_API_KEY=sk-...

# Firebase
FIREBASE_PROJECT_ID=snappcar-xxxxx
```

Firebase config files (`google-services.json`, `GoogleService-Info.plist`) are
stored in `android/app/` and `ios/Runner/` respectively. They are **gitignored**
and provided via CI secrets.

---

## Security

Security is a first-class concern. The app stores personal vehicle data, invoice photos,
and vehicle plates — all of which are sensitive. Every layer of the stack must be treated
as a potential attack surface.

### Authentication
- **Supabase Auth is the only identity provider.** Never implement custom session logic.
- JWTs are managed by the Supabase SDK; never store them in plain `SharedPreferences` —
  use `flutter_secure_storage` for any token that must be persisted locally.
- **Session expiry**: configure Supabase to use short-lived JWTs (1 hour) with refresh
  tokens. The SDK handles refresh automatically; do not disable this.
- **Google OAuth**: validate the `id_token` server-side via Supabase Auth — never trust
  the raw token returned by the Google Sign-In plugin without server verification.
- **Password policy**: enforce minimum 8 characters with at least one number and one
  special character at the form-validation layer (`reactive_forms`). Supabase enforces
  its own server-side policy as a second line of defence.
- **Rate limiting**: Supabase Auth has built-in rate limiting on `/auth/v1/token` and
  `/auth/v1/signup`. Do not expose the service role key on the client — it bypasses all
  rate limits and RLS.
- After a successful login, always call `supabase.auth.currentSession` to verify the
  session is active before navigating to protected routes. Use a `go_router` redirect
  guard tied to a Riverpod auth state provider.

### Data Access — Row-Level Security (RLS)
- **Every table that holds user data must have RLS enabled and at least one policy.**
  A table with RLS enabled but no policies denies all access — verify this is intentional
  for read-only seed tables like `maintenance_templates`.
- Never use the `service_role` key inside the Flutter app. It is only allowed inside
  Edge Functions running in a trusted server environment.
- Policies must cover all four operations explicitly: `SELECT`, `INSERT`, `UPDATE`,
  `DELETE`. Do not rely on a catch-all policy unless you have consciously reviewed it.
- After writing a new migration, add a test in `test/unit/` that verifies the RLS
  policies reject cross-user access.

### Storage Security
- Supabase Storage buckets for user content (`invoices`, `vehicle-photos`) must be
  **private** (not public). Always generate signed URLs server-side with short expiry
  (≤ 60 minutes) when the app needs to display an image.
- Storage policies must mirror the RLS pattern: only the owning user can upload, read,
  or delete their own files. Example:
  ```sql
  -- Only the owner can upload to their invoices folder
  CREATE POLICY "owner_upload" ON storage.objects
    FOR INSERT WITH CHECK (
      bucket_id = 'invoices' AND
      (storage.foldername(name))[1] = auth.uid()::text
    );
  ```
- Never construct a storage path using user-supplied strings without sanitising them.
  Always use `auth.uid()` as the top-level folder to prevent path traversal.

### Edge Functions
- Always verify the caller's JWT at the start of every Edge Function:
  ```typescript
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
  const { data: { user }, error } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
  if (error || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
  ```
- Functions triggered by Supabase webhooks (storage events) must validate the
  `x-supabase-webhook-secret` header against a secret stored in `Deno.env.get()`.
- Never log full request bodies — they may contain file data or PII.
- Secrets (`OPENAI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`) are set via
  `supabase secrets set` and accessed with `Deno.env.get()`. They are never committed
  to source control.

### Transport & API
- All communication with Supabase and external APIs (OpenAI, FIPE) must be over HTTPS.
  The Supabase and Dio clients enforce this by default — never downgrade to HTTP.
- The FIPE API is public and unauthenticated; treat its responses as untrusted input.
  Validate and sanitise all fields before writing to the database.
- Do not proxy raw AI responses to the client. The Edge Function must parse the AI output
  and return only the structured `invoice_items` data.

### Secrets & Environment
- `.env` is **gitignored**. CI/CD secrets are injected via GitHub Actions secrets and
  `supabase secrets set`. Never hardcode any key, URL, or credential in source code.
- Rotate keys immediately if accidentally committed. Add a pre-commit hook (or
  `gitleaks` in CI) to scan for leaked secrets on every push.
- The `SUPABASE_ANON_KEY` is intentionally public (safe to ship in the app) but the
  `SUPABASE_SERVICE_ROLE_KEY` must never leave the server environment.

### Mobile-Specific
- Enable **certificate pinning** before production launch to prevent MITM attacks on
  rooted/jailbroken devices. Use the `http_certificate_pinning` package or configure
  it at the network layer.
- Do not store sensitive data (tokens, vehicle plates, personal info) in plain
  `SharedPreferences`. Use `flutter_secure_storage` which maps to Keychain (iOS) and
  Android Keystore.
- Request only the permissions the current screen needs (camera, storage). Do not
  request all permissions at app launch.
- Obfuscate Dart code in release builds:
  ```bash
  flutter build apk --obfuscate --split-debug-info=build/debug-info
  ```

### LGPD Compliance (Brazilian Data Protection Law)
- Display a clear privacy policy on first launch and require explicit acceptance before
  account creation.
- The app collects: name, email, vehicle plate, odometer readings, invoice photos, and
  location (future). Each data category must be disclosed in the privacy policy.
- Provide a "Delete my account" flow in Profile → Settings that removes all user data
  from `profiles`, `vehicles`, `mileage_entries`, `maintenance_records`, `invoices`,
  `invoice_items`, and Supabase Storage. Implement as a Postgres function called via RPC
  to ensure atomicity.
- Data is stored in Supabase's managed infrastructure. Confirm the selected Supabase
  region (prefer `sa-east-1` — São Paulo) to keep data within Brazilian territory where
  possible.

---

## AI Assistant Guidelines

When working in this codebase:

1. **Always check the database schema** in this file or in `supabase/migrations/`
   before writing queries or models. Do not invent column names.
2. **Features follow the structure** `lib/features/<name>/{data,presentation,providers}/`.
   New features must follow this pattern.
3. **No direct Supabase calls in widgets** — always through a repository provider.
4. **Test new repositories**: every public method on a repository class must have
   at least one unit test using a mocked Supabase client.
5. **RLS first**: when writing a new migration that creates a table with user data,
   include the RLS policies in the same migration file.
6. **MVP scope**: avoid over-engineering. If a feature is not listed in the
   Feature Descriptions section, discuss with the owner before implementing.
7. **Portuguese UI copy**: all user-facing strings must be in Brazilian Portuguese.
   Use `flutter_localizations` + ARB files in `lib/l10n/` for all copy.
8. **Currency**: monetary values are always BRL. Display with `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`.

---

## Roadmap (Post-MVP)

These are planned but **not yet in scope**. Do not implement unless instructed.

- Workshop marketplace: nearby garages can post estimates for a maintenance job.
- Spare-parts store: affiliate links / direct purchase integration.
- Multi-vehicle household: share vehicle management with family members.
- Gamification: streaks and badges for on-time maintenance.
- Export: full service history PDF for use in vehicle sale negotiations.
