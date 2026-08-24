# CarePaw — Development Guide

This guide covers local development setup, common workflows, testing
strategies, and useful tips for working on CarePaw.

---

## 1. Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | 3.12+ (stable channel) |
| Dart SDK | 3.12+ (bundled with Flutter) |
| IDE | VS Code (recommended) or Android Studio |
| Git | Any recent version |

Verify:
```bash
flutter doctor
```

---

## 2. Initial Setup

```bash
# 1. Clone
git clone <repository-url>
cd carepaw

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift DAOs, Injectable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### 2.1 Code Generation

The project uses several code generators:

| Generator | Purpose | Trigger |
|-----------|---------|---------|
| `drift_dev` | Database DAOs, table classes | `build_runner build` |
| `injectable_generator` | DI registration | `build_runner build` |
| `json_serializable` | (if added) Model serialization | `build_runner build` |

Run after any change to:
- `lib/core/database/tables.dart`
- Annotated repository classes (`@injectable`, `@lazySingleton`)
- Any `part '*.g.dart'` file

```bash
# One-shot
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (keeps generating on save)
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## 3. Project Structure Recap

```
lib/
├── app/                      # Router, theme, config
├── core/                     # Shared infrastructure
│   ├── database/             # Drift schema, DAOs
│   ├── di/                   # GetIt DI setup
│   ├── errors/               # Failure types
│   ├── security/             # Secure storage
│   ├── storage/              # Local storage
│   ├── utils/                # Validators
│   └── widgets/              # Reusable UI
├── features/                 # Feature modules
│   ├── authentication/
│   ├── users/
│   ├── pets/
│   ├── appointments/
│   ├── queue/
│   ├── medical_records/
│   ├── inventory/
│   ├── scanning/
│   └── notifications/
└── main.dart
```

Each feature follows:
```
feature/
├── data/
│   └── repositories/         # *RepositoryImpl
├── domain/
│   ├── entities/             # Pure Dart classes
│   └── repositories/         # Interfaces (contracts)
└── (presentation/ — to be added)
```

---

## 4. Environment Configuration

Currently, CarePaw runs **fully offline** with a local SQLite database.
No `.env` file is required.

When a remote API is added, use:

```bash
# Copy example
cp .env.example .env

# Edit with your values
API_URL=https://api.carepaw.local
ENVIRONMENT=development
```

> **Never commit `.env` or any secrets.** Use `flutter_secure_storage`
> for runtime secrets (tokens, keys).

---

## 5. Running the App

```bash
# Default (mobile/desktop/web)
flutter run

# Specific device
flutter run -d <device-id>

# Web
flutter run -d chrome

# Release profile (performance testing)
flutter run --release
```

### 5.1 Route Testing

All routes are defined in `lib/app/router/routes.dart` and registered in
`lib/app/router/app_router.dart`. Currently every route renders a
`PlaceholderPage`. To test navigation:

```bash
flutter run
# Then use the browser/dev-tools or hot reload to navigate
```

---

## 6. Testing Strategy

### 6.1 Test Categories

| Type | Location | Purpose |
|------|----------|---------|
| Unit | `test/unit/` | Domain logic, validators, repositories (with fakes) |
| Widget | `test/widget/` | Individual widget behavior |
| Integration | `integration_test/` | Full flows (auth → appointment → queue) |

### 6.2 Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Specific file
flutter test test/unit/features/pets/pet_repository_test.dart

# Integration tests (requires device/emulator)
flutter test integration_test/
```

### 6.3 Test Organization

```
test/
├── unit/
│   ├── core/
│   │   ├── errors/
│   │   ├── utils/
│   │   └── repositories/
│   ├── features/
│   │   ├── authentication/
│   │   ├── users/
│   │   ├── pets/
│   │   ├── appointments/
│   │   ├── queue/
│   │   ├── medical_records/
│   │   ├── inventory/
│   │   ├── scanning/
│   │   └── notifications/
│   └── mocks/               # Mocktail fakes
├── widget/
│   ├── core/widgets/
│   └── features/
└── integration_test/
    ├── appointment_flow_test.dart
    ├── queue_flow_test.dart
    └── inventory_scan_flow_test.dart
```

### 6.4 Writing Repository Tests

Use an in-memory fake for fast unit tests:

```dart
// test/mocks/fake_pet_repository.dart
class FakePetRepository implements PetRepository {
  final Map<int, Pet> _pets = {};
  int _nextId = 1;

  @override
  Future<Pet?> findById(int id) async => _pets[id];

  @override
  Future<List<Pet>> findByOwner(int ownerId) async =>
      _pets.values.where((p) => p.ownerId == ownerId).toList();

  @override
  Future<Pet> save(Pet pet) async {
    final saved = pet.id == null
        ? pet.copyWith(id: _nextId++)
        : pet;
    _pets[saved.id!] = saved;
    return saved;
  }
  // ... implement remaining methods
}
```

Then in BLoC tests:

```dart
blocTest<PetBloc, PetState>(
  'emits [Loading, Loaded] when LoadPets succeeds',
  build: () => PetBloc(repository: FakePetRepository()),
  act: (bloc) => bloc.add(LoadPets(ownerId: 1)),
  expect: () => [isA<PetLoading>(), isA<PetLoaded>()],
);
```

---

## 7. Database Workflow

### 7.1 Schema Changes

1. Edit `lib/core/database/tables.dart`
2. Bump `schemaVersion` in `lib/core/database/database.dart`
3. Add migration logic in `MigrationStrategy.onUpgrade`
4. Run:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. Test migration locally (delete app data to simulate fresh install).

### 7.2 Inspecting the Database

```bash
# On Android emulator / device
adb shell
run-as com.example.carepaw
sqlite3 databases/carepaw.sqlite

# On iOS simulator
sqlite3 ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/<APP>/Documents/carepaw.sqlite

# Desktop (macOS/Linux/Windows)
sqlite3 <app-documents>/carepaw.sqlite
```

Useful queries:
```sql
.tables
.schema users
SELECT * FROM appointments WHERE status = 'CONFIRMED';
SELECT * FROM queue_entries ORDER BY position;
SELECT * FROM inventory_transactions ORDER BY created_at DESC LIMIT 20;
```

---

## 8. Common Development Tasks

### 8.1 Adding a New Feature

1. Create folder: `lib/features/<feature_name>/`
2. Add `domain/entities/` — define entity class(es) with `Equatable`
3. Add `domain/repositories/` — define repository interface
4. Add `data/repositories/` — implement using Drift DAOs
5. Register DAO and repo in `lib/core/di/dependency_injection.dart`
6. Run `build_runner` to generate DAOs
7. Add routes in `lib/app/router/routes.dart` and `app_router.dart`
8. Create BLoC in `presentation/` (when ready)

### 8.2 Adding a Table

1. Add class in `lib/core/database/tables.dart`
2. Add to `@DriftDatabase(tables: [...])` in `database.dart`
3. Run `build_runner`
4. DAO is auto-generated in `lib/core/database/dao/<table>_dao.g.dart`
5. Create a typed DAO wrapper in `lib/core/database/dao/<table>_dao.dart`
6. Use in repository implementation.

### 8.3 Adding a Failure Type

1. Add to `lib/core/errors/failures.dart` under appropriate category
2. Throw/catch in repository or use-case
3. Handle in BLoC → UI

---

## 9. Debugging Tips

### 9.1 Drift Query Logging

```dart
// In database.dart, temporarily enable:
CarePawDatabase() : super(_openConnection()) {
  // Log all queries
  // Only in debug!
  // debugOpen = true; // Not directly available, use a custom LoggingExecutor
}
```

Or use `DriftLogger` (add dependency):

```dart
import 'package:drift/drift.dart';

class LoggingExecutor extends DatabaseExecutor {
  final DatabaseExecutor _inner;
  LoggingExecutor(this._inner);

  @override
  Future<T> runSelect<T>(String sql, List<Object?> args, ...) async {
    print('🔍 SELECT: $sql -- $args');
    return _inner.runSelect(sql, args, ...);
  }
  // ... implement other methods
}
```

### 9.2 BLoC Logging

```dart
// Wrap in bloc observer
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    print('🔄 ${bloc.runtimeType}: $change');
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stack) {
    print('❌ ${bloc.runtimeType}: $error');
    super.onError(bloc, error, stack);
  }
}

// In main.dart
void main() {
  Bloc.observer = AppBlocObserver();
  // ...
}
```

### 9.3 Inspector

- **Flutter DevTools** — `flutter run` then open the DevTools URL
- **Widget Inspector** — Select widget mode to inspect tree
- **Timeline** — Profile frame rendering

---

## 10. Code Style & Conventions

### 10.1 Dart Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter_lints` (in `pubspec.yaml`)
- Run `flutter analyze` before committing

### 10.2 Naming

| Element | Convention |
|---------|------------|
| Classes, Enums, Typedefs | `PascalCase` |
| Variables, Functions, Parameters | `camelCase` |
| Constants (compile-time) | `lowerCamelCase` or `SCREAMING_SNAKE_CASE` |
| Private (library) | `_leadingUnderscore` |
| Files | `snake_case.dart` |
| Folders | `snake_case` |

### 10.3 Repository Pattern

- Interface in `domain/repositories/`
- Implementation in `data/repositories/` suffixed `Impl`
- Return `Future<T>` or `Stream<T>` — never expose Drift types
- Use `Failure` for errors (not exceptions)

### 10.4 Entities

- Extend `Equatable` for value equality
- Provide `copyWith` for immutable updates
- Keep pure Dart — no Drift imports

---

## 11. Git Workflow

```bash
# Feature branch
git checkout -b feature/short-description

# Commit with conventional messages
git commit -m "feat(pets): add pet avatar upload"
git commit -m "fix(queue): correct position reordering"
git commit -m "docs(architecture): update ADR-004"

# Push and open PR
git push origin feature/short-description
```

### Branch Types

| Prefix | Purpose |
|--------|---------|
| `feat/` | New feature |
| `fix/` | Bug fix |
| `docs/` | Documentation only |
| `refactor/` | Code restructuring |
| `test/` | Test additions |
| `chore/` | Build, deps, config |

---

## 12. Performance Profiling

```bash
# Profile mode
flutter run --profile

# Trace startup
flutter run --trace-startup

# Memory
flutter run --profile --enable-software-rendering
# Then open DevTools → Memory tab
```

### Common Issues

| Issue | Fix |
|-------|-----|
| Large widget rebuilds | Use `const` constructors, `BlocBuilder` with `buildWhen` |
| Janky animations | Profile → Timeline, look for >16ms frames |
| Memory leaks | Close streams, cancel subscriptions in `dispose` |

---

## 13. Useful Commands Reference

```bash
# Clean build
flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze

# Format
dart format .

# Check outdated deps
flutter pub outdated

# Upgrade deps
flutter pub upgrade

# Build APK
flutter build apk --release

# Build iOS (macOS only)
flutter build ios --release

# Build web
flutter build web --release
```

---

## 14. Troubleshooting

| Problem | Solution |
|---------|----------|
| `build_runner` conflicts | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Drift schema mismatch | Uninstall app (clears DB), or write migration |
| `get_it` not registered | Ensure `configureDependencies()` called before `runApp` |
| GoRouter not navigating | Check `rootNavigatorKey` and route paths |
| BLoC state not updating | Verify `emit` called, `equatable` props correct |

---

## 15. Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [BLoC Library](https://bloclibrary.dev/)
- [GoRouter](https://pub.dev/packages/go_router)
- [GetIt](https://pub.dev/packages/get_it)
- [CarePaw CLAUDE.md](../CLAUDE.md) — Project memory & rules