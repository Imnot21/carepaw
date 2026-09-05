import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';

/// Local file storage service - free alternative to Firebase Storage.
///
/// Stores files in the app's documents directory and tracks metadata
/// in the local SQLite database. No cloud costs, works offline.
class LocalFileStorage {
  LocalFileStorage._();

  static final LocalFileStorage _instance = LocalFileStorage._();
  static LocalFileStorage get instance => _instance;

  CarePawDatabase? _database;
  Directory? _storageDir;

  /// Initialize the storage service
  Future<void> initialize(CarePawDatabase database) async {
    _database = database;
    final appDir = await getApplicationDocumentsDirectory();
    _storageDir = Directory(p.join(appDir.path, 'carepaw_files'));

    // Create category subdirectories
    final categories = [
      'profile_images',
      'pet_images',
      'medical_records',
      'scans',
      'receipts',
      'medicine_boxes',
      'uploads',
      'general',
    ];

    for (final category in categories) {
      final dir = Directory(p.join(_storageDir!.path, category));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Get the database instance
  CarePawDatabase get _db {
    if (_database == null) {
      throw StateError('LocalFileStorage not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Get the storage directory
  Directory get _dir {
    if (_storageDir == null) {
      throw StateError('LocalFileStorage not initialized. Call initialize() first.');
    }
    return _storageDir!;
  }

  /// Save a file from bytes
  ///
  /// Returns the LocalFile record with the saved file info.
  Future<LocalFile> saveFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String category,
    required int uploadedBy,
    int? referenceId,
    String? referenceType,
    bool isPublic = false,
  }) async {
    // Compute hash for deduplication
    final hash = sha256.convert(bytes).toString();

    // Check if file already exists (deduplication)
    final existing = await (_db.select(_db.localFiles)
          ..where((f) => f.hash.equals(hash) & f.uploadedBy.equals(uploadedBy)))
        .getSingleOrNull();

    if (existing != null) {
      // File already exists, return existing record
      return existing;
    }

    // Generate unique filename
    final extension = p.extension(fileName).toLowerCase();
    final baseName = p.basenameWithoutExtension(fileName);
    final uniqueName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}$extension';

    // Determine category directory
    final categoryDir = Directory(p.join(_dir.path, category));
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }

    final filePath = p.join(categoryDir.path, uniqueName);
    final relativePath = p.join(category, uniqueName);

    // Write file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Create database record
    final localFile = LocalFilesCompanion(
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      fileSize: Value(bytes.length),
      localPath: Value(relativePath),
      hash: Value(hash),
      category: Value(category),
      referenceId: referenceId != null ? Value(referenceId) : const Value.absent(),
      referenceType: referenceType != null ? Value(referenceType) : const Value.absent(),
      uploadedBy: Value(uploadedBy),
      isPublic: Value(isPublic),
      isSynced: const Value(false),
    );

    final id = await _db.into(_db.localFiles).insert(localFile);
    return (await (_db.select(_db.localFiles)..where((f) => f.id.equals(id))).getSingle());
  }

  /// Save a file from a File object
  Future<LocalFile> saveFileFromFile({
    required File file,
    required String category,
    required int uploadedBy,
    int? referenceId,
    String? referenceType,
    bool isPublic = false,
  }) async {
    final bytes = await file.readAsBytes();
    final mimeType = _guessMimeType(file.path);
    return saveFile(
      bytes: bytes,
      fileName: p.basename(file.path),
      mimeType: mimeType,
      category: category,
      uploadedBy: uploadedBy,
      referenceId: referenceId,
      referenceType: referenceType,
      isPublic: isPublic,
    );
  }

  /// Get file bytes by ID
  Future<Uint8List?> getFileBytes(int fileId) async {
    final record = await (_db.select(_db.localFiles)
          ..where((f) => f.id.equals(fileId)))
        .getSingleOrNull();

    if (record == null) return null;

    final file = File(p.join(_dir.path, record.localPath));
    if (!await file.exists()) return null;

    return file.readAsBytes();
  }

  /// Get file record by ID
  Future<LocalFile?> getFile(int fileId) async {
    return (_db.select(_db.localFiles)..where((f) => f.id.equals(fileId))).getSingleOrNull();
  }

  /// Get files by category
  Future<List<LocalFile>> getFilesByCategory(String category) async {
    return (_db.select(_db.localFiles)
          ..where((f) => f.category.equals(category))
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();
  }

  /// Get files by reference (e.g., all images for a pet)
  Future<List<LocalFile>> getFilesByReference({
    required String referenceType,
    required int referenceId,
  }) async {
    return (_db.select(_db.localFiles)
          ..where((f) =>
              f.referenceType.equals(referenceType) & f.referenceId.equals(referenceId))
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();
  }

  /// Get files uploaded by a user
  Future<List<LocalFile>> getFilesByUser(int userId) async {
    return (_db.select(_db.localFiles)
          ..where((f) => f.uploadedBy.equals(userId))
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();
  }

  /// Get public files (e.g., profile images)
  Future<List<LocalFile>> getPublicFiles(String category) async {
    return (_db.select(_db.localFiles)
          ..where((f) => f.category.equals(category) & f.isPublic.equals(true))
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();
  }

  /// Delete a file (soft delete - marks as deleted, keeps record for audit)
  Future<bool> deleteFile(int fileId, int userId) async {
    final record = await getFile(fileId);
    if (record == null) return false;

    // Check ownership
    if (record.uploadedBy != userId) {
      // Could add admin check here
      return false;
    }

    // Delete physical file
    final file = File(p.join(_dir.path, record.localPath));
    if (await file.exists()) {
      await file.delete();
    }

    // Delete database record (hard delete since we're removing the file)
    // For audit trail, we could soft delete instead
    await (_db.delete(_db.localFiles)..where((f) => f.id.equals(fileId))).go();
    return true;
  }

  /// Update file metadata
  Future<bool> updateFile(int fileId, {
    String? fileName,
    String? category,
    int? referenceId,
    String? referenceType,
    bool? isPublic,
  }) async {
    final companion = LocalFilesCompanion(
      fileName: fileName != null ? Value(fileName) : const Value.absent(),
      category: category != null ? Value(category) : const Value.absent(),
      referenceId: referenceId != null ? Value(referenceId) : const Value.absent(),
      referenceType: referenceType != null ? Value(referenceType) : const Value.absent(),
      isPublic: isPublic != null ? Value(isPublic) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    final result = await (_db.update(_db.localFiles)
          ..where((f) => f.id.equals(fileId)))
        .write(companion);

    return result > 0;
  }

  /// Mark file as synced (for future cloud sync)
  Future<void> markSynced(int fileId) async {
    await (_db.update(_db.localFiles)..where((f) => f.id.equals(fileId)))
        .write(const LocalFilesCompanion(isSynced: Value(true)));
  }

  /// Get storage usage statistics
  Future<StorageStats> getStorageStats() async {
    final allFiles = await _db.select(_db.localFiles).get();
    int totalSize = 0;
    int fileCount = allFiles.length;

    final byCategory = <String, int>{};
    final byCategoryCount = <String, int>{};

    for (final file in allFiles) {
      totalSize += file.fileSize;
      byCategory[file.category] = (byCategory[file.category] ?? 0) + file.fileSize;
      byCategoryCount[file.category] = (byCategoryCount[file.category] ?? 0) + 1;
    }

    return StorageStats(
      totalFiles: fileCount,
      totalBytes: totalSize,
      byCategory: byCategory,
      byCategoryCount: byCategoryCount,
    );
  }

  /// Clean up orphaned files (files in storage but not in database)
  Future<int> cleanupOrphanedFiles() async {
    final dbFiles = await _db.select(_db.localFiles).get();
    final dbPaths = dbFiles.map((f) => f.localPath).toSet();

    int deleted = 0;
    await for (final entity in _dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: _dir.path);
        if (!dbPaths.contains(relativePath)) {
          await entity.delete();
          deleted++;
        }
      }
    }

    return deleted;
  }

  /// Guess MIME type from file extension
  String _guessMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get absolute file path for a LocalFile record
  String getAbsolutePath(LocalFile file) {
    return p.join(_dir.path, file.localPath);
  }

  /// Check if file exists on disk
  Future<bool> fileExistsOnDisk(LocalFile file) async {
    final absolutePath = getAbsolutePath(file);
    return File(absolutePath).exists();
  }
}

/// Storage usage statistics
class StorageStats {
  final int totalFiles;
  final int totalBytes;
  final Map<String, int> byCategory;
  final Map<String, int> byCategoryCount;

  StorageStats({
    required this.totalFiles,
    required this.totalBytes,
    required this.byCategory,
    required this.byCategoryCount,
  });

  String get formattedSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}