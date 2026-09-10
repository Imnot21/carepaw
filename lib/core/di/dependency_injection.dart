import 'package:get_it/get_it.dart';
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
import 'package:carepaw/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:carepaw/features/audit/data/repositories/firestore_audit_log_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final getIt = GetIt.instance;

/// Get the GetIt instance for use in other files
GetIt getItInstance() => getIt;

/// Configure all dependencies for the CarePaw application
Future<void> configureDependencies() async {
  // PasswordHasher, SecureStorage, LocalStorage are static utility classes
  // - PasswordHasher: static methods only, no instance needed
  // - SecureStorage: static methods only, initialized via SecureStorage.init()
  // - LocalStorage: static methods only, initialized via LocalStorage.init()
  // They are used directly as static classes in the code.

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

  // Audit logs (append-only)
  getIt.registerLazySingleton<AuditLogRepository>(() => FirestoreAuditLogRepository(
    firestore: getIt<FirebaseFirestore>(),
    auditLogIdSequence: FirestoreIdSequence(
      getIt<FirebaseFirestore>(),
      counterCollection: 'counters',
      counterDoc: 'auditLogIds',
    ),
  ));
}