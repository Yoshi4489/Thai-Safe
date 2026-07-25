# Thai Safe

Thai Safe is an Android-first community safety app for quick emergency
reporting and coordination with verified volunteer responders. It is not an
official emergency dispatch system and does not guarantee police, fire, or
ambulance response. The app always exposes configurable emergency-call
fallbacks (Thailand defaults: 1669, 191, and 199).

## Safety architecture

- A quick SOS sends an idempotent request ID, authenticated reporter UID,
  exact GPS position, accuracy, last-known fallback, and a server timestamp.
- Optional category, urgency, summary, private details, and protected photos
  are added only after the quick report succeeds.
- Network failures are shown as **waiting to send**, never as submitted. An
  Android WorkManager job retries the durable SQLite outbox.
- `incidents/{id}` contains sanitized public information and an approximate
  geohash-6 position.
- `incident_private/{id}` contains exact position, reporter data, consent, and
  private media paths.
- `incident_assignments/{id}` enforces one lead responder and records status
  history.
- Roles are Firebase custom claims: `user`, `responder`, and `admin`.
  `responder` is the secured canonical replacement for legacy `rescue`,
  `rescuer`, and `officer` values.
- Incident submission, enrichment, following, assignment, status transitions,
  private-data access, responder review, account export/deletion, notification
  creation, and retention run through callable Cloud Functions.
- A scheduled function removes exact location, reporter contact, medical
  consent, and private media after 90 days while preserving anonymous
  statistics.

## Maps

The app uses `flutter_map` and OpenStreetMap-compatible data—no Google Maps API
key is required. Map tiles and attribution are controlled by Firebase Remote
Config (`map_tile_url` and `map_attribution`) or the `MAP_TILE_URL` compile
define.

The community endpoint is a development fallback only:

```text
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

Configure a production-appropriate OSM-compatible provider before rollout and
follow both that provider's terms and OpenStreetMap attribution requirements.

## Firebase environments

Create independent Firebase projects for development, staging, and production.
Copy `.firebaserc.example` to `.firebaserc`, replace the placeholder project
IDs, and generate a platform configuration for each environment:

```powershell
firebase use development
flutterfire configure --project <development-project>
flutter run --dart-define=APP_ENV=development
```

Repeat for staging and production. Do not reuse development App Check,
Crashlytics, Analytics, Storage, or Firestore data in production.

Required Firebase products:

- Authentication (phone)
- Firestore
- Storage
- Cloud Functions (Node.js 22)
- App Check (Play Integrity for release, debug provider locally)
- Cloud Messaging
- Crashlytics, Analytics, and Remote Config
- Cloud Scheduler for the retention function

## Local setup

```powershell
flutter pub get
cd functions
npm install
npm run build
npm test
cd ..
firebase emulators:start
```

Functions enforce App Check in deployed environments. Register the local
debug App Check token shown by the app when developing against Firebase.

Run Firestore rule tests while the emulator is active:

```powershell
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
cd functions
npm test
```

## Data migration

Export Firestore and Storage before any migration. Both scripts are dry-run by
default:

```powershell
cd functions
npm run migrate:roles
npm run migrate:incidents
```

After reviewing the counts and confirming a backup:

```powershell
npm run migrate:roles -- --apply
npm run migrate:incidents -- --apply --backup-confirmed
```

The incident migration normalizes legacy statuses, creates the public/private
split, reduces public location precision, moves reachable legacy media into
protected Storage, and removes reporter/contact/follower fields from public
documents.

## Verification

Before any staged release:

```powershell
npm --prefix functions run build
npm --prefix functions run lint
npm --prefix functions test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

The release build currently uses the debug signing key inherited from the
original project. Replace it with a protected production keystore before a
Play Store upload.

Recommended rollout: internal testing, closed verified-responder beta, limited
regional beta, then gradual production release using Remote Config kill
switches.

## Developer team

- Palat (Yoshi)
- Waiyawat (Leo)
