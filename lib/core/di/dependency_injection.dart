import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/users_dao.dart';
import 'package:carepaw/core/database/dao/medical_records_dao.dart';
import 'package:carepaw/core/database/dao/notifications_dao.dart';
import 'package:carepaw/core/database/dao/prescriptions_dao.dart';
import 'package:carepaw/core/database/dao/queue_dao.dart';
import 'package:carepaw/core/database/dao/audit_logs_dao.dart';
import 'package:carepaw/core/database/dao/device_info_dao.dart';
import 'package:carepaw/core/database/dao/sync_metadata_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/core/sync/sync_repository_impl.dart';
import 'package:carepaw/core/sync/sync_engine.dart';
import 'package:carepaw/core/sync/network_monitor.dart';
import 'package:carepaw/core/sync/background_sync.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/users/data/repositories/user_repository_impl.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/queue/data/repositories/queue_repository_impl.dart';
import 'package:carepaw/features/medical_records/domain/repositories/medical_record_repository.dart';
import 'package:carepaw/features/medical_records/data/repositories/medical_record_repository_impl.dart';
import 'package:carepaw/features/medical_records/data/repositories/vaccination_repository_impl.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/data/repositories/inventory_item_repository_impl.dart';
import 'package:carepaw/features/inventory/data/repositories/inventory_batch_repository_impl.dart';
import 'package:carepaw/features/inventory/data/repositories/inventory_transaction_repository_impl.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';
import 'package:carepaw/features/scanning/data/repositories/scan_repository_impl.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';
import 'package:carepaw/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final getIt = GetIt.instance;

/// Get the GetIt instance for use in other files
GetIt getItInstance() => getIt;

/// Configure all dependencies for the CarePaw application
Future<void> configureDependencies() async {
  // Register database as singleton
  getIt.registerLazySingleton<CarePawDatabase>(() => CarePawDatabase());

  // Register DAOs
  getIt.registerLazySingleton<UsersDao>(() => UsersDao(getIt<CarePawDatabase>()));
  getIt.registerLazySingleton<MedicalRecordsDao>(() => MedicalRecordsDao(getIt<CarePawDatabase>()));
  getIt.registerLazySingleton<NotificationsDao>(() => NotificationsDao(getIt<CarePawDatabase>()));
  getIt.registerLazySingleton<PrescriptionsDao>(() => PrescriptionsDao(getIt<CarePawDatabase>()));
  getIt.registerLazySingleton<QueueDao>(() => QueueDao(getIt<CarePawDatabase>()));
  getIt.registerLazySingleton<AuditLogsDao>(() => AuditLogsDao(getIt<CarePawDatabase>()));
  getIt.registerLazySingleton<DeviceInfoDao>(() => DeviceInfoDao(getIt<CarePawDatabase>()));
  getIt.registerLazySingleton<SyncMetadataDao>(() => SyncMetadataDao(getIt<CarePawDatabase>()));

  // PasswordHasher, SecureStorage, LocalStorage are static utility classes
  // - PasswordHasher: static methods only, no instance needed
  // - SecureStorage: static methods only, initialized via SecureStorage.init()
  // - LocalStorage: static methods only, initialized via LocalStorage.init()
  // They are used directly as static classes in the code.

  // Register Sync Repository
  getIt.registerLazySingleton<SyncRepository>(() => SyncRepositoryImpl(getIt<CarePawDatabase>()));

  // Register Network Monitor
  getIt.registerLazySingleton<NetworkMonitor>(() => NetworkMonitor(Connectivity()));

  // Register Firestore (needs Firebase to be initialized first)
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Auth Repository - uses static classes directly (PasswordHasher, SecureStorage, LocalStorage)
  // Register with a factory
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<CarePawDatabase>()));

  // Now update AuthRepository with SyncController to enable immediate auth sync
  // This runs after SyncController is registered, so it's available
  // We need to re-register with the SyncController set
  getIt.unregister<AuthRepository>();
  final authRepo = AuthRepositoryImpl(getIt<CarePawDatabase>());

  // Register Sync Engine
  getIt.registerLazySingleton<SyncEngine>(() => SyncEngine(
    syncRepo: getIt<SyncRepository>(),
    firestore: getIt<FirebaseFirestore>(),
    networkMonitor: getIt<NetworkMonitor>(),
  ));

  // Register Sync Controller
  getIt.registerLazySingleton<SyncController>(() => SyncController(
    syncEngine: getIt<SyncEngine>(),
    syncRepo: getIt<SyncRepository>(),
    usersDao: getIt<UsersDao>(),
  ));

  // Set SyncController on authRepo and register as singleton
  authRepo.setSyncController(getIt<SyncController>());
  getIt.registerSingleton<AuthRepository>(authRepo);

  // Register Repositories
  getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<PetRepository>(() => PetRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<AppointmentRepository>(() => AppointmentRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<QueueRepository>(() => QueueRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<MedicalRecordRepository>(() => MedicalRecordRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<VaccinationRepositoryImpl>(() => VaccinationRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<InventoryItemRepository>(() => InventoryItemRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<InventoryBatchRepository>(() => InventoryBatchRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<InventoryTransactionRepository>(() => InventoryTransactionRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<ScanRecordRepository>(() => ScanRecordRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
  getIt.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(getIt<CarePawDatabase>(), syncRepo: getIt<SyncRepository>()));
}