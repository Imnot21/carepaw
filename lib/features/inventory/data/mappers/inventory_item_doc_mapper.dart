import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';

/// Maps between Firestore `inventoryItems/{id}` documents and the domain [InventoryItem].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `InventoryItem.id`.
class InventoryItemDocMapper {
  InventoryItemDocMapper._();

  /// Build a domain [InventoryItem] from Firestore document data.
  static InventoryItem fromData(Map<String, dynamic> data) {
    return InventoryItem(
      id: data[FirestoreSchema.id] as int?,
      name: (data[FirestoreSchema.name] as String?) ?? '',
      category: InventoryCategory.fromString((data[FirestoreSchema.category] as String?) ?? ''),
      unit: (data[FirestoreSchema.unit] as String?) ?? '',
      currentStock: (data[FirestoreSchema.currentStock] as num?)?.toDouble() ?? 0,
      minStock: (data[FirestoreSchema.minStock] as num?)?.toDouble() ?? 0,
      maxStock: (data[FirestoreSchema.maxStock] as num?)?.toDouble(),
      unitCost: (data[FirestoreSchema.unitCost] as num?)?.toDouble(),
      supplier: data[FirestoreSchema.supplier] as String?,
      location: data[FirestoreSchema.location] as String?,
      createdAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ?? DateTime.now(),
      updatedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.updatedAt]) ?? DateTime.now(),
    );
  }

  /// Serialize a domain [InventoryItem] to a Firestore document map.
  static Map<String, dynamic> toData(InventoryItem item) {
    return {
      FirestoreSchema.id: item.id,
      FirestoreSchema.name: item.name,
      FirestoreSchema.category: item.category.value,
      FirestoreSchema.unit: item.unit,
      FirestoreSchema.currentStock: item.currentStock,
      FirestoreSchema.minStock: item.minStock,
      FirestoreSchema.maxStock: item.maxStock,
      FirestoreSchema.unitCost: item.unitCost,
      FirestoreSchema.supplier: item.supplier,
      FirestoreSchema.location: item.location,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(item.createdAt),
      FirestoreSchema.updatedAt: DateFieldCodec.toFirestoreDate(item.updatedAt),
    };
  }
}