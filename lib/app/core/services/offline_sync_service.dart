import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/connectivity_helper.dart';
import '../helpers/database_helper.dart';
import 'evidence_storage_service.dart';

class OfflineSyncService {
  final SupabaseClient _supabase;
  final DatabaseHelper _databaseHelper;

  OfflineSyncService({
    SupabaseClient? supabase,
    DatabaseHelper? databaseHelper,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> enqueueUpsert({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) {
    return _enqueue(
      tableName: tableName,
      recordId: recordId,
      operation: 'upsert',
      payload: payload,
    );
  }

  Future<void> enqueueDelete({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) {
    return _enqueue(
      tableName: tableName,
      recordId: recordId,
      operation: 'delete',
      payload: payload,
    );
  }

  Future<void> _enqueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    if (kIsWeb) return;

    final db = await _databaseHelper.db;
    await db.insert(
      'sync_queue',
      {
        'tableName': tableName,
        'recordId': recordId,
        'operation': operation,
        'payload': jsonEncode(payload),
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> syncPending() async {
    if (kIsWeb || !await ConnectivityHelper.isOnline()) return 0;

    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final db = await _databaseHelper.db;
    final rows = await db.query(
      'sync_queue',
      where: 'syncedAt IS NULL',
      orderBy: 'createdAt ASC',
    );

    var synced = 0;
    for (final row in rows) {
      final id = row['id'] as int;
      final tableName = row['tableName'] as String;
      final recordId = row['recordId'] as String;
      final operation = row['operation'] as String;
      final payload =
          jsonDecode(row['payload'] as String) as Map<String, dynamic>;

      try {
        if (operation == 'delete') {
          await _supabase
              .from(tableName)
              .delete()
              .eq('id', recordId)
              .eq('userId', user.id);
        } else {
          final syncPayload = await _uploadEmbeddedEvidences(
            tableName: tableName,
            recordId: recordId,
            payload: payload,
          );
          await _supabase.from(tableName).upsert(syncPayload);
          await db.insert(
            tableName,
            syncPayload,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await db.update(
          'sync_queue',
          {'syncedAt': DateTime.now().toIso8601String(), 'error': null},
          where: 'id = ?',
          whereArgs: [id],
        );
        synced++;
      } catch (e) {
        await db.update(
          'sync_queue',
          {'error': e.toString()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

    return synced;
  }

  Future<Map<String, dynamic>> _uploadEmbeddedEvidences({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    if (tableName != 'ordens_servico') return payload;

    final storage = EvidenceStorageService(supabase: _supabase);
    final syncedPayload = Map<String, dynamic>.from(payload);

    final fotoAntesPath = syncedPayload['fotoAntesPath'] as String?;
    final fotoDepoisPath = syncedPayload['fotoDepoisPath'] as String?;
    final assinaturaBase64 = syncedPayload['assinaturaBase64'] as String?;

    if (_isDataUrl(fotoAntesPath)) {
      syncedPayload['fotoAntesPath'] = await _uploadDataUrl(
        storage: storage,
        ordemId: recordId,
        fileName: 'foto_antes.jpg',
        dataUrl: fotoAntesPath!,
      );
    }

    if (_isDataUrl(fotoDepoisPath)) {
      syncedPayload['fotoDepoisPath'] = await _uploadDataUrl(
        storage: storage,
        ordemId: recordId,
        fileName: 'foto_depois.jpg',
        dataUrl: fotoDepoisPath!,
      );
    }

    if (_isDataUrl(assinaturaBase64)) {
      syncedPayload['assinaturaBase64'] = await _uploadDataUrl(
        storage: storage,
        ordemId: recordId,
        fileName: 'assinatura.png',
        dataUrl: assinaturaBase64!,
      );
    }

    return syncedPayload;
  }

  bool _isDataUrl(String? value) {
    return value != null && value.startsWith('data:') && value.contains(',');
  }

  Future<String> _uploadDataUrl({
    required EvidenceStorageService storage,
    required String ordemId,
    required String fileName,
    required String dataUrl,
  }) {
    final separatorIndex = dataUrl.indexOf(',');
    final metadata = dataUrl.substring(5, separatorIndex);
    final contentType = metadata.split(';').first;
    final bytes = Uint8List.fromList(
      base64Decode(dataUrl.substring(separatorIndex + 1)),
    );

    return storage.uploadBytes(
      ordemId: ordemId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<int> countPending() async {
    if (kIsWeb) return 0;
    final db = await _databaseHelper.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_queue WHERE syncedAt IS NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
