import 'package:drift/drift.dart';

import 'tables.dart';

// Platform-specific database connection factory
import 'database_connection_stub.dart'
    if (dart.library.io) 'database_connection_native.dart'
    if (dart.library.js_interop) 'database_connection.dart';

part 'database.g.dart';

/// CarePaw database instance
@DriftDatabase(
  tables: [
    Users,
    Pets,
    Appointments,
    MedicalRecords,
    Vaccinations,
    InventoryItems,
    InventoryBatches,
    InventoryTransactions,
    Prescriptions,
    QueueEntries,
    Notifications,
    NotificationPreferences,
    ScanRecords,
    AuditLogs,
    SyncMetadata,
    DeviceInfo,
    LocalFiles,
  ],
)
class CarePawDatabase extends _$CarePawDatabase {
  CarePawDatabase() : super(openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Enable foreign key constraints (only for native SQLite)
        if (!_kIsWeb) {
          await customStatement('PRAGMA foreign_keys = ON');
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Migration from v1 to v2: Re-create all tables to ensure they exist
          // This handles cases where database was created with incomplete schema
          await m.createAll();
        }
        if (from < 3) {
          // Migration from v2 to v3: Add firebase_uid column to users table
          await m.addColumn(users, users.firebaseUid as GeneratedColumn<Object>);
          // Create unique index for firebase_uid (only for native SQLite)
          if (!_kIsWeb) {
            await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid) WHERE firebase_uid IS NOT NULL');
          }
        }
      },
      beforeOpen: (OpeningDetails details) async {
        // Ensure foreign keys are enabled on every connection (only for native SQLite)
        if (!_kIsWeb) {
          await customStatement('PRAGMA foreign_keys = ON');
        }
      },
    );
  }
}

/// Check if running on web
const bool _kIsWeb = identical(0, 0.0);