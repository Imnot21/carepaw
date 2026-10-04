import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';

/// Maps between Firestore `inventoryTransactions/{id}` documents and the domain [InventoryTransaction].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `InventoryTransaction.id`.
class InventoryTransactionDocMapper {
  InventoryTransactionDocMapper._();

  /// Build a domain [InventoryTransaction] from Firestore document data.
  static InventoryTransaction fromData(Map<String, dynamic> data) {
    return InventoryTransaction(
      id: data[FirestoreSchema.id] as int?,
      batchId: (data[FirestoreSchema.batchId] as num?)?.toInt() ?? 0,
      type: TransactionType.fromString(
        (data[FirestoreSchema.type] as String?) ?? '',
      ),
      quantityChange:
          (data[FirestoreSchema.quantityChange] as num?)?.toDouble() ?? 0,
      quantityBefore:
          (data[FirestoreSchema.quantityBefore] as num?)?.toDouble() ?? 0,
      quantityAfter:
          (data[FirestoreSchema.quantityAfter] as num?)?.toDouble() ?? 0,
      reason: (data[FirestoreSchema.reasonInv] as String?) ?? '',
      referenceType: data[FirestoreSchema.referenceType] as String?,
      referenceId: (data[FirestoreSchema.referenceId] as num?)?.toInt(),
      performedBy: (data[FirestoreSchema.performedBy] as num?)?.toInt() ?? 0,
      notes: data[FirestoreSchema.notesInv] as String?,
      createdAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ??
          DateTime.now(),
    );
  }

  /// Serialize a domain [InventoryTransaction] to a Firestore document map.
  static Map<String, dynamic> toData(InventoryTransaction transaction) {
    return {
      FirestoreSchema.id: transaction.id,
      FirestoreSchema.batchId: transaction.batchId,
      FirestoreSchema.type: transaction.type.value,
      FirestoreSchema.quantityChange: transaction.quantityChange,
      FirestoreSchema.quantityBefore: transaction.quantityBefore,
      FirestoreSchema.quantityAfter: transaction.quantityAfter,
      FirestoreSchema.reasonInv: transaction.reason,
      FirestoreSchema.referenceType: transaction.referenceType,
      FirestoreSchema.referenceId: transaction.referenceId,
      FirestoreSchema.performedBy: transaction.performedBy,
      FirestoreSchema.notesInv: transaction.notes,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(
        transaction.createdAt,
      ),
    };
  }
}
