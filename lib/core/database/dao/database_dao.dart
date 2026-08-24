import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/users_dao.dart';
import 'package:carepaw/core/database/dao/pets_dao.dart';
import 'package:carepaw/core/database/dao/appointments_dao.dart';
import 'package:carepaw/core/database/dao/medical_records_dao.dart';
import 'package:carepaw/core/database/dao/vaccinations_dao.dart';
import 'package:carepaw/core/database/dao/inventory_dao.dart';
import 'package:carepaw/core/database/dao/prescriptions_dao.dart';
import 'package:carepaw/core/database/dao/queue_dao.dart';
import 'package:carepaw/core/database/dao/notifications_dao.dart';
import 'package:carepaw/core/database/dao/audit_logs_dao.dart';
import 'package:carepaw/core/database/dao/sync_metadata_dao.dart';
import 'package:carepaw/core/database/dao/device_info_dao.dart';

/// Combined database access object providing access to all DAOs
class DatabaseDao {
  final CarePawDatabase _db;

  late final UsersDao users;
  late final PetsDao pets;
  late final AppointmentsDao appointments;
  late final MedicalRecordsDao medicalRecords;
  late final VaccinationsDao vaccinations;
  late final InventoryDao inventory;
  late final PrescriptionsDao prescriptions;
  late final QueueDao queue;
  late final NotificationsDao notifications;
  late final AuditLogsDao auditLogs;
  late final SyncMetadataDao syncMetadata;
  late final DeviceInfoDao deviceInfo;

  DatabaseDao(this._db) {
    users = UsersDao(_db);
    pets = PetsDao(_db);
    appointments = AppointmentsDao(_db);
    medicalRecords = MedicalRecordsDao(_db);
    vaccinations = VaccinationsDao(_db);
    inventory = InventoryDao(_db);
    prescriptions = PrescriptionsDao(_db);
    queue = QueueDao(_db);
    notifications = NotificationsDao(_db);
    auditLogs = AuditLogsDao(_db);
    syncMetadata = SyncMetadataDao(_db);
    deviceInfo = DeviceInfoDao(_db);
  }

  /// Get the underlying database
  CarePawDatabase get database => _db;

  /// Close the database
  Future<void> close() => _db.close();
}