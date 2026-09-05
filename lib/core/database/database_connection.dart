// Copyright 2025 CarePaw
// Web database connection using IndexedDB (wasm)

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    // Use wasm IndexedDB on web
    final result = await WasmDatabase.open(
      databaseName: 'carepaw_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  });
}