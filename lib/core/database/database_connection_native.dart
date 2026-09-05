// Copyright 2025 CarePaw
// Native database connection using SQLite (dart:ffi)

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io' show File;

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'carepaw.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}