# Chapter 2 — Technologies Used

**Project:** CarePaw — Smart Veterinary Patient Management System

> All technologies in this chapter were verified directly against the source
> code, dependency lockfile, and platform build configuration. Version numbers
> are the **resolved** versions recorded in `pubspec.lock` and
> `functions/package.json`, not the lower-bound constraints in `pubspec.yaml`.
> Where a package is declared but never imported, that is stated explicitly so
> the claim can be defended in an oral defence.

---

## 2.1 Framework and Language

| Technology | Version | Evidence |
|---|---|---|
| **Flutter** | 3.44.9 (stable, revision `6b182d2c75`) | Installed SDK; `pubspec.lock` → `flutter: ">=3.44.0"` |
| **Dart** | 3.12.2 | `pubspec.yaml:7` → `sdk: ^3.12.2`; lock → `>=3.12.2 <4.0.0` |
| **Material Design 3** | — | `lib/app/theme/app_theme.dart` sets `useMaterial3: true` in both the light and dark themes |

Flutter was selected because it compiles a single Dart codebase to Android, iOS,
Web, Windows, macOS, and Linux from one source tree, with a declarative widget
system and a consistent rendering surface across all six targets.

**Correction to legacy documentation:** `CLAUDE.md` states "Flutter 3.12+ /
Dart 3.12+". The actual installed toolchain is **Flutter 3.44.9 / Dart 3.12.2**.

---

## 2.2 State Management — BLoC Pattern

| Package | Resolved version | Role |
|---|---|---|
| `flutter_bloc` | 9.1.1 | BLoC/Cubit implementation, imported by 31 files |
| `equatable` | 2.1.0 | Value-equality for `Event`, `State`, and `Failure` classes |

CarePaw adopts the **Business Logic Component** pattern. Each event dispatched
from the widget layer is handled by a BLoC, which emits an immutable state that
the widget layer rebuilds from. Widgets contain no business logic; all state
transitions are unit-testable without a widget tree.

Providers in use: `MultiBlocProvider`, `MultiRepositoryProvider`,
`BlocProvider`, `RepositoryProvider`, plus the `context.read<T>()` and
`context.select<T>()` lookups.

Each of the 11 feature modules follows the same BLoC triple convention
(`*_bloc.dart`, `*_event.dart`, `*_state.dart`):

| BLoC | Feature |
|---|---|
| `AuthBloc` | authentication |
| `UserManagementBloc` | users |
| `PetBloc` | pets |
| `AppointmentBloc` | appointments |
| `QueueBloc` | queue |
| `MedicalRecordBloc` | medical_records |
| `InventoryBloc` | inventory |
| `ScanBloc` | scanning |
| `NotificationBloc` | notifications |
| `AuditLogBloc` | audit |

BLoCs are created in two places: `AuthBloc` is provided once at app root in
`lib/main.dart`; all others are instantiated per-route inside
`lib/app/router/app_router.dart`, which keeps state scopes tied to the
navigation lifetime.

---

## 2.3 Navigation — go_router

| Package | Version | Location |
|---|---|---|
| `go_router` | 17.5.0 | `lib/app/router/app_router.dart` (787 lines), `lib/app/router/routes.dart` |

CarePaw uses **declarative** routing rather than imperative `Navigator` calls.
Route definitions and navigation guards are data, which makes the access-control
rules auditable in one place.

Implementation specifics:

- **ShellRoute** — a single `ShellRoute` (`lib/app/shell/app_shell.dart`) wraps
  every authenticated route and renders role-adaptive bottom navigation
  (`lib/app/shell/role_tabs.dart` defines four hardcoded tab sets: 5 tabs for pet
  owners, 6 for staff, 5 for veterinarians, 4 for admins).
- **Authorization guard** — a single global `redirect` closure enforces
  role-based access using prefix string matching (`location.startsWith(...)`):
  unauthenticated users are sent to `/login`; authenticated users are routed
  away from auth pages; and role mismatches (e.g. a pet owner requesting
  `/admin`) are redirected to that role's home destination.
- **Auth-to-router bridge** — a custom `ChangeNotifier` (`AuthStateListenable`)
  subscribes to `AuthBloc` and is passed as GoRouter's `refreshListenable`, so
  navigation reacts automatically to authentication state changes.
- **Error handling** — an `errorBuilder` renders unmatched paths; no explicit
  `/404` route exists.
- 32 routes are registered across the public (splash, login, register,
  forgot-password, reset-password) and protected (owner, staff, veterinarian,
  admin) areas.

---

## 2.4 Dependency Injection — GetIt (Manual Registration)

| Package | Version | Location |
|---|---|---|
| `get_it` | 9.2.1 | `lib/core/di/dependency_injection.dart` |

Dependency injection follows the **Service Locator** pattern. All repository
abstractions are bound to their concrete implementations at startup, so feature
code depends on domain interfaces only and never constructs its own data sources.

Fifteen services are registered with `registerLazySingleton<T>()`: the
`FirebaseFirestore` instance, two transaction-backed ID-sequence generators, and
twelve repository implementations. Registrations are consumed two ways — via
`getIt<T>()` inside the router when building per-route BLoCs, and via
`RepositoryProvider<T>(create: (_) => getIt<T>())` in `main.dart` for
`context.read<T>()` lookups in the widget layer.

**Accuracy note:** DI is **entirely manual**. There is no `injectable` package,
no `@injectable` annotations, and no `build_runner` code generation anywhere in
the project.

**Correction to legacy documentation:** `README.md:48` states
"Dependency Inject. | GetIt + Injectable (`get_it`, `injectable`)". This is
incorrect — `injectable` is absent from `pubspec.yaml` and unused.

---

## 2.5 Backend / Cloud Services — Google Firebase (Backend-as-a-Service)

Firebase project: **`carepaw-93d16`**. Firestore region: **`asia-southeast1`**
(Singapore).

| Firebase Product | Package | Version | Actual use |
|---|---|---|---|
| **Firebase Core** | `firebase_core` | 3.15.2 | SDK initialisation via generated `DefaultFirebaseOptions` |
| **Cloud Firestore** | `cloud_firestore` | 5.6.12 | **Primary datastore** for all 14 collections |
| **Firebase Authentication** | `firebase_auth` | 5.7.0 | Email/password login, registration, password reset |
| **Firebase App Check** | `firebase_app_check` | 0.3.2+10 | Play Integrity / DeviceCheck / reCAPTCHA v3 (release builds) |
| **Cloud Functions** | `firebase-admin` / `firebase-functions` | 12.1.0 / 5.1.0 | Server-side privileged operations |
| **Firebase Hosting** | `firebase.json` | — | Serves the Flutter web build from `build/web` with SPA rewrite |
| **Firestore Emulator** | `firebase.json` | — | Local emulator on port 8080 with Emulator UI |

A Backend-as-a-Service model was chosen so the thesis project can deliver a
secure, audited, real-time system without provisioning or operating server
infrastructure, while still providing server-side enforcement through security
rules and Cloud Functions.

### 2.5.1 Cloud Firestore as the Datastore

Firestore is the actual persistence layer. There is **no local SQL database**.
The directory `lib/core/database/` does not exist, and there are zero imports of
`drift`, `sqflite`, `hive`, `sqlite3`, `isar`, or `objectbox` anywhere in `lib/`
or `test/`. The only two textual references to a former local database are
comments in `auth_repository_impl.dart:31` and
`firestore_user_repository.dart:27` explaining that it was removed during the
Firestore migration.

Firestore patterns actually implemented:

| Pattern | Implementation |
|---|---|
| **Real-time reactivity** | All 13 repositories subscribe via `.snapshots()` streams (28 call sites), giving live queue and list updates without polling |
| **Transactions** | `FirestoreIdSequence` / `UserIdSequence` (`lib/core/firebase/`) generate integer surrogate keys inside `runTransaction()` against `counters/*` documents, letting the domain model keep `int id` fields on top of string document IDs |
| **Write batches** | Atomic multi-document writes in the inventory and notification repositories |
| **Schema centralisation** | 14 collection constants and roughly 130 field-name constants in `lib/core/firebase/firestore_schema.dart` (296 lines) — the most-referenced file in the codebase at 394 references |
| **Date serialisation** | `lib/core/firebase/date_field_codec.dart` normalises `Timestamp`, `DateTime`, and ISO-8601 `String` values (72 references) |
| **Error translation** | `firebase_firestore_error_mapper.dart` and `firebase_auth_error_mapper.dart` convert platform exceptions into the project's typed `Failure` hierarchy |
| **Pagination contracts** | `PaginatedRepository` and `PaginationParams` / `PaginatedResult<T>` in `core/repositories/base_repository.dart` |

**The 14 collections** are `users`, `pets`, `appointments`, `medicalRecords`,
`vaccinations`, `inventoryItems`, `inventoryBatches`, `inventoryTransactions`,
`prescriptions`, `queueEntries`, `notifications`, `notificationPreferences`,
`scanRecords`, and `auditLogs`.

**Correction to legacy documentation:** `README.md:50` claims
"Database | Drift (SQLite)". This is obsolete — the project migrated to Firestore
(commit `4697d80`, "feat: complete Firestore migration"). `CLAUDE.md` still lists
"Database | TBD (SQLite/PostgreSQL via API)". Chapter 2 must state **Cloud
Firestore, a NoSQL document database**.

---

## 2.6 Serverless Backend — Cloud Functions (Node.js 20, JavaScript)

`functions/index.js` — 144 lines, plain JavaScript using CommonJS modules.

| Item | Value |
|---|---|
| Runtime | **Node.js 20** (`functions/package.json` → `"engines": { "node": "20" }`; `firebase.json` → `"runtime": "nodejs20"`) |
| Language | **JavaScript** — there is no `tsconfig.json`; the backend is **not** TypeScript |
| Generation | **Cloud Functions v2** (`firebase-functions/v2/https`, `onRequest` trigger) |
| SDKs | `firebase-admin@12.1.0`, `firebase-functions@5.1.0` — the only two npm dependencies |
| Functions implemented | 1 — `deleteUser` (admin-only permanent account deletion) |

### 2.6.1 Why a Cloud Function Exists

The Flutter client SDK cannot delete an arbitrary user's Firebase Auth
credential; `User.delete()` only works for the currently signed-in user. To free
a mis-created email address, deletion must run server-side with the Admin SDK,
which is privileged and therefore must not be embedded in the client.

### 2.6.2 Security flow of `deleteUser`

The function enforces a strict chain of checks before mutating anything:

1. Permissive CORS with `OPTIONS` preflight handling
2. Method gate — `POST` only, otherwise `405`
3. Extract the `Authorization: Bearer` header, otherwise `401`
4. **Verify the caller's ID token** with `admin.auth().verifyIdToken()`, otherwise `401`
5. **Authorise the caller as an administrator** by reading `users/{callerUid}` and requiring `role === 'admin'`, otherwise `403`
6. Validate the target UID is present, otherwise `400`
7. **Block self-deletion**, otherwise `409`
8. Confirm the target document exists, otherwise `404`
9. **Block deleting the last administrator** by counting `users` where
   `role == 'admin'` and rejecting if one or fewer remain, otherwise `409`
10. **Revoke the Auth credential** via `auth.deleteUser(targetUid)`, which frees the email
11. **Delete the `users/{uid}` Firestore document**
12. **Append an audit-log entry** (`action: 'USER_DELETE'`, `entityType: 'USER'`) to `auditLogs`
13. Return `{ ok: true }`, or `500` on an unexpected error with `logger.error`

Related domain records (pets, appointments, medical records) are deliberately
left intact, honouring the project's "never delete medical records" rule; once
the credential is revoked the records become inert.

### 2.6.3 Client transport

The Flutter app calls the function with plain `package:http`:

```dart
final uri = Uri.parse('https://deleteuser-$projectId.uc.r.appspot.com/deleteUser');
await http.post(uri,
  headers: { contentType: 'application/json', authorization: 'Bearer $idToken' },
  body: jsonEncode({'uid': uid}),
).timeout(const Duration(seconds: 30));
```

The `firebase_functions` Dart package (0.6.0) is declared but **not used at
runtime**; the source documents the reason — the pinned Dart package is the
authoring SDK and exposes no runtime callable API, so the raw HTTPS protocol is
posted instead.

---

## 2.7 Security Architecture

### 2.7.1 Firestore Security Rules

`firestore.rules` — 233 lines, `rules_version = '2'`. Authorization is enforced
**server-side** by the database, not merely by hiding UI controls.

Helper functions define the role predicates:
`isAuthenticated()`, `isAdmin()`, `isStaff()`, `isVeterinarian()`,
`isPetOwner()`, `isClinicStaff()`.

| Collection | Policy |
|---|---|
| `/users/{uid}` | Owner reads/updates own document; admin has full access; **`allow delete: if false`** — deletion is only possible through the audited Cloud Function |
| `/pets/{petId}` | Admin/staff/veterinarian, or the owner where `resource.data.ownerId == getCurrentUserId()` |
| `/appointments/{id}` | Owner creates and reads; staff/veterinarian/admin update; admin full write |
| `/medicalRecords/{id}` | Create: veterinarian/staff/admin. Read: clinic roles or owner. **`allow update, delete: if false`** |
| `/medicalRecords/{id}/vaccinations/{id}` | Same append-only enforcement |
| `/inventoryItems/{id}` | Read: staff/veterinarian/admin. Write: staff/admin |
| `/inventoryBatches/{id}` | Read: staff/veterinarian/admin. Write: staff/admin |
| `/inventoryTransactions/{id}` | Read: clinic roles. Create: staff/admin. **`allow update, delete: if false`** |
| `/prescriptions/{id}` | Read: owner/veterinarian/admin. Create: veterinarian. Update: veterinarian, restricted to `affectedKeys().hasOnly(['status','updatedAt'])`. Delete forbidden |
| `/queueEntries/{id}` | Read: clinic roles or owner. Create/update: clinic roles. Delete: admin only |
| `/notifications/{id}` | Read/update own only (`userId == getCurrentUserId()`). Create: staff/veterinarian/admin |
| `/scanRecords/{id}` | Read: own or admin. Create: any authenticated user. **`allow update, delete: if false`** |
| `/auditLogs/{id}` | **Admin only** |
| `/syncMetadata/{id}` | Read: any authenticated. Write: admin only |
| `/deviceInfo/{deviceId}` | Read/write where `request.auth.uid == deviceId` |
| `/syncConflicts/{id}` | Read: own or admin. Write: admin only |
| `/counters/{counterId}` | `userIds` readable/writable by any authenticated user; **all other counters admin-only** |
| `/{document=**}` | **Catch-all deny** — `allow read, write: if false` |

The append-only enforcement on medical records is how the project's
"medical records are append-only" principle is technically guaranteed rather
than merely documented.

### 2.7.2 Client-Side Defence in Depth

| Package | Version | Role |
|---|---|---|
| `pointycastle` | 4.0.0 | **Argon2id** implementation in `core/security/password_hasher.dart` — 3 iterations, 65,536 KB memory, 32-byte derived key, version 1.3, constant-time comparison, and `needsRehash()`/`maybeRehash()` support. **This file is imported by zero files and is dead code**, because credential handling is delegated entirely to Firebase Auth |
| `flutter_secure_storage` | 11.0.0 | OS-backed secure storage (iOS Keychain, Android Encrypted SharedPreferences). Initialised, but only `clearAuthData()` is ever invoked — **no value is ever written to it** |

### 2.7.3 Firebase App Check

`firebase_app_check` provides attestation of genuine app instances. Release
builds enable Play Integrity (Android) and DeviceCheck / reCAPTCHA v3 (iOS/Web);
the app is explicitly skipped in debug mode because the App Check API is not
enabled for the project.

### 2.7.4 Audit Logging

Auditing is implemented at two levels. The client writes to the `auditLogs`
collection through `FirestoreAuditLogRepository` (append-only, real-time
stream). The Cloud Function appends its own `USER_DELETE` entry so that
privileged server-side actions are recorded independently of client behaviour.
`AuditLogBloc` provides admin-side filtering by `action` and `entityType`.

---

## 2.8 Local Persistence

| Package | Version | Actual role |
|---|---|---|
| `shared_preferences` | 2.5.5 | **Session mirror cache only** — three keys (`user_id`, `user_role`, `is_logged_in`) are written in `auth_repository_impl.dart:459-461`. Firebase Auth remains the authoritative session provider |
| `flutter_secure_storage` | 11.0.0 | Initialised, then only cleared — effectively unused |

`lib/core/storage/local_storage.dart` declares roughly 18 storage keys
(`auth_token`, `theme_mode`, `locale`, `notification_enabled`, `cached_pets`, and
so on), but only the three authentication keys are ever written. No theming
preference, cache, or notification preference is persisted.

---

## 2.9 Networking

| Package | Version | Use |
|---|---|---|
| `http` | 1.6.0 | Single purpose — POST to the `deleteUser` Cloud Function with a 30-second timeout and a 3-attempt post-delete verification loop |

All other data access goes through the native Firestore and Auth SDKs rather
than a hand-rolled REST layer. The `core/network/` directory does not exist.

---

## 2.10 Notifications

| Package | Version | Status |
|---|---|---|
| `flutter_local_notifications` | 18.0.1 | Initialised with two Android channels (`carepaw_instant`, `carepaw_scheduled`); supports `zonedSchedule` with `AndroidScheduleMode.exactAllowWhileIdle` and a custom `NotificationPriority` enum. **`initialize()` is called, but no notification is ever shown or scheduled** |
| `timezone` | 0.9.4 | Timezone database backing scheduled local notifications |
| `firebase_messaging` | 15.2.10 | **Declared but imported nowhere** — FCM push is not implemented. The local-notification service is documented in-source as the "free alternative to Firebase Cloud Messaging" |

Notification records themselves are fully implemented in Firestore (list, detail,
and settings screens with `notificationPreferences` support and real-time
streams). What is missing is delivery: the notification tap handler in
`local_notification_service.dart` is a `// TODO: Navigate to relevant screen
based on payload` stub.

---

## 2.11 UI Design System

| Item | Detail |
|---|---|
| Design language | "Soft Clinic" — warm bone canvas `#F8F5F0`, terracotta primary `#E27D60`, warm charcoal dark mode `#1A1A1A`, warm hairline borders `#E7E0D5`, tinted recessed wells `#F1ECE3` |
| Design tokens | `lib/app/theme/design_tokens.dart` — the `NeuTokens` class is a single source of truth: spacing scale (4→48), radius scale (8→999) with shape presets, depth/shadow presets per brightness, hairline widths (1 / 1.5), animation durations (80 ms→1500 ms), easing curves, opacity and press scales, icon sizes, control sizes with `minTapTarget = 44` (WCAG 2.5.5 Target Size), and a four-level z-index scale |
| Component library | `lib/core/widgets/neomorphism/` — **18 purpose-built widgets** with **1,321 `Neu*` references** across `lib/`: container, card, button, icon button, text field, switch, chip, progress, shimmer/skeleton (4 variants), avatar, bottom navigation, dialog, confirm dialog, bottom sheet, divider, FAB, and FAB speed dial |
| Colour resolution | `lib/app/theme/theme_colors.dart` — a `ThemeColors` static resolver exposing 20 brightness-aware colour accessors, the pattern used by feature pages instead of raw colour constants |
| Theming | Material 3 with hand-authored light **and** dark `ColorScheme` instances (not derived from a seed colour). `ThemeMode.system` — there is no in-app theme toggle |
| Typography | `google_fonts` 6.3.3 — **Nunito** at weights 700 and 600 for display, headline, app-bar title, and large numeric styles; the platform system face (Roboto / San Francisco) for body, title, label, button, caption, and code styles. Fetched from Google's font CDN at runtime, not bundled as an asset |
| Device preview | `device_preview` 1.3.1 — device-frame preview enabled only in debug builds (`enabled: !kReleaseMode`) |
| Colour utilities | A `ColorScale` extension (`scale`, `lighten`, `darken`) plus seven per-species accent colours resolved by `accentForSpecies()` |

**Accuracy note for defence:** although the directory and widget names retain
"neomorphism" and the `Neu` prefix, the shipped implementation explicitly
abandoned the dual light/dark soft-UI shadows that define classic neumorphism.
The source comments in `neu_shadows.dart:6-14` and `index.dart:3-6` state that
separation now comes from **hairline borders and tinted fills**, and that
shadows are reserved only for genuinely floating overlays (FAB, bottom
navigation, dialog, bottom sheet). Describe the system in the thesis as a
**custom flat/soft-material design system with legacy neumorphic naming**, not as
neumorphism.

---

## 2.12 Architecture and Design Patterns

| Pattern | Implementation |
|---|---|
| **Clean Architecture** | Three layers per feature — `presentation` → `domain` → `data` — with a strict downward-only dependency rule. `lib/core/repositories/base_repository.dart` imports nothing, so the domain layer has zero external dependencies |
| **Feature-first organisation** | 11 feature modules: `appointments`, `audit`, `authentication`, `home`, `inventory`, `medical_records`, `notifications`, `pets`, `queue`, `scanning`, `users` |
| **Repository Pattern** | 12 repository **interfaces** declared in `domain/repositories/` and bound to `Firestore*Repository` **implementations** in `data/repositories/`. All bindings live in the GetIt registration file |
| **Mapper Pattern** | A `*_doc_mapper.dart` in every feature isolates Firestore document (de)serialisation from domain entities, so persistence format changes never leak into business logic |
| **Either / Outcome error handling** | `lib/core/errors/` — a `Failure` hierarchy of roughly 28 typed failures extending `Equatable` (families: `Unexpected`, `Cancelled`, `Network`, `Auth`, `Validation`, `Data`, `Storage`, `Appointment`, `Inventory`, `OCR`), an `AppException` hierarchy, and `ErrorHandler` that maps `FirebaseException` to the matching `Failure` |
| **Domain contracts** | `BaseRepository<T, ID>`, `SoftDeleteRepository`, `StreamRepository` (`watchById` / `watchAll`), `PaginatedRepository` with `PaginationParams` and `PaginatedResult<T>` |
| **Role-Based Access Control** | Four roles — `petOwner`, `staff`, `veterinarian`, `admin` — enforced at three independent layers: the GoRouter redirect, the Firestore security rules, and Cloud Function authorisation |
| **Valid layered design (ADR)** | Four accepted architecture decision records: Clean Architecture, feature-first organisation, immutable append-only medical records, and human-verified OCR |

Domain rules enforced in the domain layer include the appointment state machine
(`REQUESTED → CONFIRMED → CHECKED_IN → QUEUED → IN_PROGRESS → COMPLETED`, with
`REJECTED` / `CANCELLED` terminal branches, and `InvalidStatusTransitionFailure`
on illegal moves) and queue priority ordering (`QueueEntry.byQueueOrder`,
covered by unit tests).

---

## 2.13 Platform Build Tooling

### 2.13.1 Android

| Item | Value |
|---|---|
| Build DSL | **Kotlin DSL** (`.kts` — there is no Groovy `build.gradle`) |
| Android Gradle Plugin | 9.0.1 |
| Kotlin | 2.3.20 |
| Gradle | 9.1.0 |
| `compileSdk` | 37 |
| Java / Kotlin target | JVM 17 |
| Google Services plugin | 4.3.15 |
| Core library desugaring | `com.android.tools:desugar_jdk_libs:2.0.4` (required by `flutter_local_notifications`) |
| `applicationId` | `com.example.carepaw` — still the default template identifier |

### 2.13.2 iOS

| Item | Value |
|---|---|
| Deployment target | iOS 13.0 |
| Xcode project object version | 54 |
| Swift | 5.0 |
| Plugin linking | **Swift Package Manager** (Flutter's SPM route) — there is **no `Podfile` and no CocoaPods** |
| Push notifications | **Not configured** — no `aps-environment` entitlement, no Push Notifications capability, no Background Modes |
| Usage descriptions | None declared — no `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`, or `NSUserTrackingUsageDescription` |

### 2.13.3 Supported Targets

Android, iOS, Web, Windows, macOS, and Linux are all configured. **Web is the
only target actually built and deployed** (verified by the
`.firebase/hosting.*.cache` deploy manifest), compiled with the **CanvasKit**
renderer rather than the HTML renderer. Firebase Hosting rewrites all paths to
`/index.html` so client-side routing works on refresh.

---

## 2.14 Testing

| Package | Version | Use |
|---|---|---|
| `flutter_test` | SDK | Test framework |
| `bloc_test` | 10.0.0 | BLoC event/state assertion |
| `mocktail` | 1.0.5 | Mock repository doubles |
| `flutter_lints` | 6.0.0 | Static-analysis ruleset configured in `analysis_options.yaml` |

**Three test files exist** (381 lines total):

| File | Coverage |
|---|---|
| `test/auth_bloc_test.dart` | Authentication event handling with mocked repository |
| `test/user_management_bloc_test.dart` | Admin user-management flows with mocked repository |
| `test/queue_priority_order_test.dart` | Pure unit tests of `QueuePriority` ranks and `QueueEntry.byQueueOrder` |

**Do not claim a coverage strategy or per-layer coverage targets as
implemented.** `CAREPAW_ARCHITECTURE.md:408-412` lists targets of 90% domain /
80% application / 70% data / 60% presentation coverage, but these are aspirational
and are not currently met or measured.

---

## 2.15 Packages Declared but Not Used

These are present in `pubspec.yaml` but imported nowhere in `lib/` or `test/`.
They must **not** be presented as implemented technologies.

| Package | Version | Reason |
|---|---|---|
| `local_auth` | 3.0.2 | Biometric authentication is a TODO stub in `auth_bloc.dart:192` |
| `firebase_messaging` | 15.2.10 | FCM push is not implemented |
| `uuid` | 4.6.0 | Identifiers come from Firestore transaction sequences instead |
| `logger` | 2.7.0 | The codebase uses raw `print()` / `debugPrint()` |
| `path_provider` | 2.1.6 | No local file storage is required |
| `permission_handler` | 12.0.3 | Never imported; permissions are not requested at runtime |
| `crypto` | 3.0.7 | Hashing uses PointyCastle, and even that path is dead code |
| `pointycastle` | 4.0.0 | Referenced only by `password_hasher.dart`, which nothing imports |
| `firebase_functions` | 0.6.0 | No runtime callable API in the Dart SDK; raw `http` is used instead |

---

## 2.16 Summary Table

| Layer | Technology | Version |
|---|---|---|
| Framework | Flutter (Material 3) | 3.44.9 |
| Language | Dart | 3.12.2 |
| State management | BLoC (`flutter_bloc`) + `equatable` | 9.1.1 / 2.1.0 |
| Navigation | go_router | 17.5.0 |
| Dependency injection | GetIt (manual registration) | 9.2.1 |
| Database | **Google Cloud Firestore** (NoSQL document DB) | 5.6.12 |
| Authentication | Firebase Authentication | 5.7.0 |
| App integrity | Firebase App Check | 0.3.2+10 |
| Backend | Cloud Functions v2 — Node.js 20 / JavaScript | admin 12.1.0 / functions 5.1.0 |
| Web hosting | Firebase Hosting | — |
| Security enforcement | Firestore Security Rules v2 (RBAC) | `rules_version = '2'` |
| Local cache | shared_preferences | 2.5.5 |
| Secure storage | flutter_secure_storage | 11.0.0 |
| Networking | http | 1.6.0 |
| Local notifications | flutter_local_notifications + timezone | 18.0.1 / 0.9.4 |
| Typography | google_fonts (Nunito) | 6.3.3 |
| Formatting | intl | 0.20.2 |
| Testing | flutter_test, bloc_test, mocktail, flutter_lints | — / 10.0.0 / 1.0.5 / 6.0.0 |
| Architecture | Clean Architecture + Repository + feature-first | — |

---

## 2.17 Known Implementation Gaps

These are genuine code-level issues, distinct from the documentation
discrepancies in Section 2.18. They are recorded here so the thesis does not
overstate system completeness.

| # | Gap | Location |
|---|---|---|
| 1 | **No Android permissions declared** — no `INTERNET`, `CAMERA`, or `POST_NOTIFICATIONS`. `INTERNET` exists only in the debug and profile manifests, so a **release APK cannot reach Firestore** | `android/app/src/main/AndroidManifest.xml` |
| 2 | **Role casing mismatch** — security rules compare against uppercase `'ADMIN'` / `'STAFF'` / `'VETERINARIAN'`, but the application writes lowercase `'admin'` / `'staff'`. Every RBAC rule therefore fails | `firestore.rules` vs `auth_repository_impl.dart` |
| 3 | **Duplicate `configureDependencies()` call** — invoked at `main.dart:92` and again at `main.dart:101`; the second throws inside GetIt and is swallowed by its own `catch` block | `lib/main.dart` |
| 4 | **Empty `firestore.indexes.json`** — despite roughly 28 multi-field queries, no composite indexes are defined, so those queries will fail at runtime | `firestore.indexes.json` |
| 5 | **Android release signing uses the debug keystore** — no `key.properties` or Play upload key exists | `android/app/build.gradle.kts` |
| 6 | **OCR and camera capture are simulated** — `scan_camera_page.dart:303-315` renders a placeholder feed; there is no camera, image-picker, or ML Kit dependency. The scan *record* persistence, list, and detail screens are real | `lib/features/scanning/presentation/pages/scan_camera_page.dart` |
| 7 | **Stale, insecure, unreferenced ruleset** — `firestore.rules.prod` contains an email-based read rule that would let any signed-in user read another user's document, and provides no admin write path. It is not referenced by `firebase.json` | `firestore.rules.prod` |
| 8 | **Hardcoded user identifiers** — `final userId = 1; // TODO: Get from auth state` | `inventory_detail_page.dart:734`, `notification_bloc.dart:162`, `scan_bloc.dart:169` |
| 9 | **Vet dashboard is a placeholder** — all eight quick-action tiles emit a "coming soon" snackbar | `vet_dashboard_page.dart` |
| 10 | **Debug diagnostics left enabled** — `debugLogDiagnostics: true` in the router, and raw `print()` statements dumping user data and Firestore payloads in `register()` | `app_router.dart`, `auth_repository_impl.dart:118-177` |
| 11 | **Logo asset not bundled** — `assets/logo/logo_svg.svg` exists on disk but `pubspec.yaml` has no `assets:` section, so it is never packaged | `pubspec.yaml:67-68` |
| 12 | **Web PWA metadata is default** — `web/manifest.json` still uses the stock Flutter blue `#0175C2` and the description "A new Flutter project." | `web/manifest.json`, `web/index.html` |

---

## 2.18 Documentation Discrepancies (Corrected Above)

| Source | Claim | Reality |
|---|---|---|
| `README.md:50` | Database: Drift (SQLite) | **Cloud Firestore** — Drift was removed in commit `4697d80` |
| `README.md:48` | DI: GetIt + Injectable | **GetIt only** — manual registration, no codegen |
| `README.md:84-88` | Local SQLite at `<app-docs>/carepaw.sqlite` | No local SQL database exists |
| `README.md:73-74` | `build_runner build` for Drift DAOs and Injectable | No code generation step; no `build_runner` dependency |
| `README.md:177` | Links to a `docs/` folder (ARCHITECTURE, DATABASE, API, DEVELOPMENT, CONTRIBUTING, USER_GUIDE, THESIS_SUPPORT) | These files do not exist |
| `CLAUDE.md` | Database: TBD (SQLite/PostgreSQL via API) | **Cloud Firestore** |
| `CLAUDE.md` | State management: TBD | **BLoC** (`flutter_bloc` 9.1.1) |
| `CLAUDE.md` | Authentication: PLANNED | **Implemented** — login, registration, reset, role assignment |
| `CLAUDE.md` | "Database Schema ✅ COMPLETE" as a *local* schema | `firestore_schema.dart` exists but still contains Drift↔Firestore name mappers for removed local tables |
| `CAREPAW_ARCHITECTURE.md:372-392` | State management, database, and backend all "TBD" | All three decided and implemented |
| `CAREPAW_ARCHITECTURE.md:304` | "Secure password hashing (bcrypt/Argon2)" | Delegated to Firebase Auth; the local Argon2id hasher is dead code |
| `CAREPAW_ARCHITECTURE.md:408-412` | Per-layer coverage targets | Not met or measured |
| `firestore_schema.dart:5` | "Mirrors the Drift database schema for bidirectional sync" | Stale — no local database, no sync layer |
| `CAREPAW_ARCHITECTURE.md:326-347` | 13 "core tables" (SQL terminology) | 14 Firestore collections |

---

## 2.19 Technology Selection Rationale

| Requirement | Technology chosen | Justification |
|---|---|---|
| Cross-platform delivery | Flutter + Dart | One codebase compiles to all six targets, removing the need for separate web and mobile teams |
| Offline-free, real-time clinic floor | Cloud Firestore | Push-based `.snapshots()` streams give live queue and appointment state to staff and owners simultaneously without polling or WebSocket infrastructure |
| Credential security | Firebase Authentication | Managed password hashing, token rotation, and password-reset email flows without handling any password material in application code |
| Tamper-proof medical history | Firestore Security Rules | `allow update, delete: if false` enforces append-only records at the database layer, so the guarantee survives any client bug |
| Privileged operations | Cloud Functions v2 (Node.js 20) | The Admin SDK can delete Auth credentials that the client cannot; the function also enables last-admin and self-delete protection |
| Layered maintainability | Clean Architecture + feature-first | Domain rules are testable with no Flutter binding, and features can be reasoned about independently |
| Testable business logic | BLoC + `equatable` | Events and states become plain value objects, so logic is unit-testable with `bloc_test` and `mocktail` |
| Consistent visual identity | Custom token-driven design system | Centralised spacing, radius, depth, and motion tokens guarantee a coherent interface across a codebase of 164 Dart files |
| Low operational overhead | Firebase BaaS + Firebase Hosting | The capstone project operates a production-style backend with no server to provision, patch, or monitor |

---

*Verified against commit `7a62381` on branch `feature/neumorphism-design`.
Generated from the source tree: 164 Dart files in `lib/`, 1 Cloud Function,
3 test files, and the Android, iOS, and web build configurations.*
