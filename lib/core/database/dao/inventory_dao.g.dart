// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dao.dart';

// ignore_for_file: type=lint
mixin _$InventoryDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $InventoryItemsTable get inventoryItems => attachedDatabase.inventoryItems;
  $InventoryBatchesTable get inventoryBatches =>
      attachedDatabase.inventoryBatches;
  InventoryDaoManager get managers => InventoryDaoManager(this);
}

class InventoryDaoManager {
  final _$InventoryDaoMixin _db;
  InventoryDaoManager(this._db);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(
        _db.attachedDatabase,
        _db.inventoryItems,
      );
  $$InventoryBatchesTableTableManager get inventoryBatches =>
      $$InventoryBatchesTableTableManager(
        _db.attachedDatabase,
        _db.inventoryBatches,
      );
}
