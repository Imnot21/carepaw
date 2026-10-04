import 'package:equatable/equatable.dart';

/// Inventory item entity - domain layer representation
class InventoryItem extends Equatable {
  final int? id;
  final String name;
  final InventoryCategory category;
  final String unit;
  final double currentStock;
  final double minStock;
  final double? maxStock;
  final double? unitCost;
  final String? supplier;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.currentStock = 0.0,
    this.minStock = 0.0,
    this.maxStock,
    this.unitCost,
    this.supplier,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if stock is low
  bool get isLowStock => currentStock <= minStock;

  /// Check if stock is out
  bool get isOutOfStock => currentStock <= 0;

  /// Check if stock is at max
  bool get isAtMax => maxStock != null && currentStock >= maxStock!;

  /// Get stock percentage (0-100)
  double? get stockPercentage {
    if (maxStock == null) return null;
    return (currentStock / maxStock! * 100).clamp(0, 100);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    unit,
    currentStock,
    minStock,
    maxStock,
    unitCost,
    supplier,
    location,
    createdAt,
    updatedAt,
  ];

  InventoryItem copyWith({
    int? id,
    String? name,
    InventoryCategory? category,
    String? unit,
    double? currentStock,
    double? minStock,
    double? maxStock,
    double? unitCost,
    String? supplier,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Inventory category enum
enum InventoryCategory {
  medicine('MEDICINE'),
  vaccine('VACCINE'),
  supply('SUPPLY'),
  equipment('EQUIPMENT'),
  food('FOOD');

  final String value;
  const InventoryCategory(this.value);

  static InventoryCategory fromString(String value) {
    return InventoryCategory.values.firstWhere(
      (cat) => cat.value == value,
      orElse: () => InventoryCategory.medicine,
    );
  }

  String get displayName {
    switch (this) {
      case InventoryCategory.medicine:
        return 'Medicine';
      case InventoryCategory.vaccine:
        return 'Vaccine';
      case InventoryCategory.supply:
        return 'Supply';
      case InventoryCategory.equipment:
        return 'Equipment';
      case InventoryCategory.food:
        return 'Food';
    }
  }
}

/// Inventory batch entity - domain layer representation
class InventoryBatch extends Equatable {
  final int? id;
  final int inventoryId;
  final String batchNumber;
  final double quantity;
  final DateTime receivedAt;
  final DateTime? expiresAt;
  final double? costPerUnit;
  final String? supplier;
  final DateTime createdAt;

  const InventoryBatch({
    this.id,
    required this.inventoryId,
    required this.batchNumber,
    required this.quantity,
    required this.receivedAt,
    this.expiresAt,
    this.costPerUnit,
    this.supplier,
    required this.createdAt,
  });

  /// Check if batch is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  /// Check if batch is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    return expiresAt!.isAfter(now) && expiresAt!.isBefore(thirtyDaysLater);
  }

  /// Check if batch has expiry date
  bool get hasExpiry => expiresAt != null;

  @override
  List<Object?> get props => [
    id,
    inventoryId,
    batchNumber,
    quantity,
    receivedAt,
    expiresAt,
    costPerUnit,
    supplier,
    createdAt,
  ];

  InventoryBatch copyWith({
    int? id,
    int? inventoryId,
    String? batchNumber,
    double? quantity,
    DateTime? receivedAt,
    DateTime? expiresAt,
    double? costPerUnit,
    String? supplier,
    DateTime? createdAt,
  }) {
    return InventoryBatch(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      batchNumber: batchNumber ?? this.batchNumber,
      quantity: quantity ?? this.quantity,
      receivedAt: receivedAt ?? this.receivedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      supplier: supplier ?? this.supplier,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Inventory transaction entity - domain layer representation
class InventoryTransaction extends Equatable {
  final int? id;
  final int batchId;
  final TransactionType type;
  final double quantityChange;
  final double quantityBefore;
  final double quantityAfter;
  final String reason;
  final String? referenceType;
  final int? referenceId;
  final int performedBy;
  final String? notes;
  final DateTime createdAt;

  const InventoryTransaction({
    this.id,
    required this.batchId,
    required this.type,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.reason,
    this.referenceType,
    this.referenceId,
    required this.performedBy,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    batchId,
    type,
    quantityChange,
    quantityBefore,
    quantityAfter,
    reason,
    referenceType,
    referenceId,
    performedBy,
    notes,
    createdAt,
  ];

  InventoryTransaction copyWith({
    int? id,
    int? batchId,
    TransactionType? type,
    double? quantityChange,
    double? quantityBefore,
    double? quantityAfter,
    String? reason,
    String? referenceType,
    int? referenceId,
    int? performedBy,
    String? notes,
    DateTime? createdAt,
  }) {
    return InventoryTransaction(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      type: type ?? this.type,
      quantityChange: quantityChange ?? this.quantityChange,
      quantityBefore: quantityBefore ?? this.quantityBefore,
      quantityAfter: quantityAfter ?? this.quantityAfter,
      reason: reason ?? this.reason,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      performedBy: performedBy ?? this.performedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Transaction type enum
enum TransactionType {
  in_('IN'),
  out('OUT'),
  adjustment('ADJUSTMENT');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.adjustment,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionType.in_:
        return 'Stock In';
      case TransactionType.out:
        return 'Stock Out';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }
}

/// Inventory batch with item details
class InventoryBatchWithItem extends Equatable {
  final InventoryBatch batch;
  final InventoryItem item;

  const InventoryBatchWithItem({required this.batch, required this.item});

  @override
  List<Object?> get props => [batch, item];
}
