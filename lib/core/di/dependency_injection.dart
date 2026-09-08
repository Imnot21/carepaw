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
import 'package:carepaw/core/firebase/user_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/users/data/repositories/firestore_user_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/data/repositories/firestore_pet_repository.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/appointments/data/repositories/firestore_appointment_repository.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/queue/data/repositories/firestore_queue_repository.dart';
import 'package:carepaw/features/medical_records/domain/repositories/medical_record_repository.dart';
import 'package:carepaw/features/medical_records/domain/repositories/vaccination_repository.dart';
import 'package:carepaw/features/medical_records/data/repositories/firestore_medical_record_repository.dart';
import 'package:carepaw/features/medical_records/data/repositories/firestore_vaccination_repository.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/data/repositories/firestore_inventory_item_repository.dart';
import 'package:carepaw/features/inventory/data/repositories/firestore_inventory_batch_repository.dart';
import 'package:carepaw/features/inventory/data/repositories/firestore_inventory_transaction_repository.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';
import 'package:carepaw/features/scanning/data/repositories/firestore_scan_record_repository.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/data/repositories/firestore_notification_repository.dart';
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';
import 'package:carepaw/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // User ID sequence (Firestore counter for app-facing int IDs)
  getIt.registerLazySingleton<UserIdSequence>(() => UserIdSequence(getIt<FirebaseFirestore>()));

  // Auth Repository - Firebase-backed (real Firebase Authentication + Firestore profiles)
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    firebaseAuth: FirebaseAuth.instance,
    firestore: getIt<FirebaseFirestore>(),
    userIdSequence: getIt<UserIdSequence>(),
  ));

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

  // Register Repositories
  // UserRepository - Firestore-backed source of truth (admin account creation etc.)
  getIt.registerLazySingleton<UserRepository>(() => FirestoreUserRepository(
    firestore: getIt<FirebaseFirestore>(),
    firebaseAuth: FirebaseAuth.instance,
    userIdSequence: getIt<UserIdSequence>(),
  ));
  // Pets
  getIt.registerLazySingleton<PetRepository>(() => FirestorePetRepository(
    firestore: getIt<FirebaseFirestore>(),
    petIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'petIds',
    ),
  ));

  // Appointments
  getIt.registerLazySingleton<AppointmentRepository>(() => FirestoreAppointmentRepository(
    firestore: getIt<FirebaseFirestore>(),
    appointmentIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'appointmentIds',
    ),
    petRepository: getIt<PetRepository>(),
    userRepository: getIt<UserRepository>(),
  ));

  // Queue
  getIt.registerLazySingleton<QueueRepository>(() => FirestoreQueueRepository(
    firestore: getIt<FirebaseFirestore>(),
    queueIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'queueIds',
    ),
    appointmentRepository: getIt<AppointmentRepository>(),
    petRepository: getIt<PetRepository>(),
    userRepository: getIt<UserRepository>(),
  ));

  // Medical Records
  getIt.registerLazySingleton<MedicalRecordRepository>(() => FirestoreMedicalRecordRepository(
    firestore: getIt<FirebaseFirestore>(),
    medicalRecordIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'medicalRecordIds',
    ),
    petRepository: getIt<PetRepository>(),
    userRepository: getIt<UserRepository>(),
    appointmentRepository: getIt<AppointmentRepository>(),
  ));

  // Vaccinations
  getIt.registerLazySingleton<VaccinationRepository>(() => FirestoreVaccinationRepository(
    firestore: getIt<FirebaseFirestore>(),
    vaccinationIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'vaccinationIds',
    ),
    petRepository: getIt<PetRepository>(),
    userRepository: getIt<UserRepository>(),
  ));

  // Inventory Items
  getIt.registerLazySingleton<InventoryItemRepository>(() => FirestoreInventoryItemRepository(
    firestore: getIt<FirebaseFirestore>(),
    inventoryItemIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'inventoryItemIds',
    ),
  ));

  // Inventory Batches
  getIt.registerLazySingleton<InventoryBatchRepository>(() => FirestoreInventoryBatchRepository(
    firestore: getIt<FirebaseFirestore>(),
    inventoryBatchIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'inventoryBatchIds',
    ),
    itemRepository: getIt<InventoryItemRepository>(),
  ));

  // Inventory Transactions
  getIt.registerLazySingleton<InventoryTransactionRepository>(() => FirestoreInventoryTransactionRepository(
    firestore: getIt<FirebaseFirestore>(),
    inventoryTransactionIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'inventoryTransactionIds',
    ),
  ));

  // Scan Records
  getIt.registerLazySingleton<ScanRecordRepository>(() => FirestoreScanRecordRepository(
    firestore: getIt<FirebaseFirestore>(),
    scanRecordIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'scanRecordIds',
    ),
  ));

  // Notifications
  getIt.registerLazySingleton<NotificationRepository>(() => FirestoreNotificationRepository(
    firestore: getIt<FirebaseFirestore>(),
    notificationIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'notificationIds',
    ),
  ));
}