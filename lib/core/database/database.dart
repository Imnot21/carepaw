import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables.dart';

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
  ],
  // Enable foreign keys enforcement
  // This is automatically enabled in Drift 2.x
)
class CarePawDatabase extends _$CarePawDatabase {
  CarePawDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will be added here
        // For now, we only have schema version 1
      },
      beforeOpen: (OpeningDetails details) async {
        // Ensure foreign keys are enabled on every connection
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

/// Open SQLite connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'carepaw.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}