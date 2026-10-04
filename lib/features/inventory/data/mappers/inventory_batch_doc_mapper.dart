import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';

/// Maps between Firestore `inventoryBatches/{id}` documents and the domain [InventoryBatch].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `InventoryBatch.id`.
class InventoryBatchDocMapper {
  InventoryBatchDocMapper._();

  /// Build a domain [InventoryBatch] from Firestore document data.
  static InventoryBatch fromData(Map<String, dynamic> data) {
    return InventoryBatch(
      id: data[FirestoreSchema.id] as int?,
      inventoryId: (data[FirestoreSchema.inventoryId] as num?)?.toInt() ?? 0,
      batchNumber: (data[FirestoreSchema.batchNumberInv] as String?) ?? '',
      quantity: (data[FirestoreSchema.quantity] as num?)?.toDouble() ?? 0,
      receivedAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.receivedAt]) ??
          DateTime.now(),
      expiresAt: DateFieldCodec.fromFirestoreDate(
        data[FirestoreSchema.expiresAt],
      ),
      costPerUnit: (data[FirestoreSchema.costPerUnit] as num?)?.toDouble(),
      supplier: data[FirestoreSchema.supplier] as String?,
      createdAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ??
          DateTime.now(),
    );
  }

  /// Serialize a domain [InventoryBatch] to a Firestore document map.
  static Map<String, dynamic> toData(InventoryBatch batch) {
    return {
      FirestoreSchema.id: batch.id,
      FirestoreSchema.inventoryId: batch.inventoryId,
      FirestoreSchema.batchNumberInv: batch.batchNumber,
      FirestoreSchema.quantity: batch.quantity,
      FirestoreSchema.receivedAt: DateFieldCodec.toFirestoreDate(
        batch.receivedAt,
      ),
      FirestoreSchema.expiresAt: DateFieldCodec.toFirestoreDate(
        batch.expiresAt,
      ),
      FirestoreSchema.costPerUnit: batch.costPerUnit,
      FirestoreSchema.supplier: batch.supplier,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(
        batch.createdAt,
      ),
    };
  }
}
