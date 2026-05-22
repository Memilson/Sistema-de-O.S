import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/connectivity_helper.dart';
import '../helpers/database_helper.dart';
import 'evidence_storage_service.dart';

class OfflineSyncService {
  final SupabaseClient _supabase;
  final DatabaseHelper _databaseHelper;

  OfflineSyncService({SupabaseClient? supabase, DatabaseHelper? databaseHelper})
      : _supabase = supabase ?? Supabase.instance.client,
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // Enqueue
  // ---------------------------------------------------------------------------

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

  /// Insere ou ATUALIZA uma entrada na fila de sincronização.
  ///
  /// Deduplicação: se já existir um registro pendente (syncedAt IS NULL) para
  /// o mesmo (tableName, recordId), o payload e a operação são atualizados no
  /// lugar de criar uma nova linha — evitando sincronizações redundantes.
  Future<void> _enqueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    if (kIsWeb) return;
    final db = await _databaseHelper.db;

    // Verifica se já há entrada pendente para este registro
    final existing = await db.query(
      'sync_queue',
      columns: ['id'],
      where: 'tableName = ? AND recordId = ? AND syncedAt IS NULL',
      whereArgs: [tableName, recordId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Atualiza o registro existente (deduplicação): evita tarefas redundantes na fila
      await db.update(
        'sync_queue',
        {
          'operation': operation,
          'payload': jsonEncode(payload),
          'error': null,
          'createdAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
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
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  // Processa a fila: percorre registros locais e faz o upload para o Supabase
  Future<int> syncPending() async {
    if (kIsWeb) return 0;
    if (!await ConnectivityHelper.isOnline()) return 0;
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
          // No Web não atualizamos banco local
          if (!kIsWeb) {
            await db.update(
              tableName,
              syncPayload,
              where: 'id = ?',
              whereArgs: [recordId],
            );
          }
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

  // ---------------------------------------------------------------------------
  // Upload de evidências embutidas na fila
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _uploadEmbeddedEvidences({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    if (tableName != 'ordens_servico') return payload;

    final storage = EvidenceStorageService(supabase: _supabase);
    final syncedPayload = Map<String, dynamic>.from(payload);

    final keys = ['fotoAntesPath', 'fotoDepoisPath', 'assinaturaBase64'];
    final fileNames = ['foto_antes.jpg', 'foto_depois.jpg', 'assinatura.png'];
    final mimeTypes = ['image/jpeg', 'image/jpeg', 'image/png'];

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = syncedPayload[key] as String?;
      if (value == null || value.isEmpty) continue;

      if (_isDataUrl(value)) {
        syncedPayload[key] = await _uploadDataUrl(
          storage: storage,
          ordemId: recordId,
          fileName: fileNames[i],
          dataUrl: value,
        );
      } else if (!kIsWeb && _isAbsoluteLocalPath(value)) {
        // Path local absoluto (ex: /data/user/0/.../arquivo.jpg)
        final file = File(value);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          syncedPayload[key] = await storage.uploadBytes(
            ordemId: recordId,
            fileName: fileNames[i],
            bytes: bytes,
            contentType: mimeTypes[i],
          );
        }
      }
      // Se já for um path relativo do Supabase (ex: userId/ordens/…), não faz nada
    }

    return syncedPayload;
  }

  bool _isDataUrl(String? value) {
    return value != null && value.startsWith('data:') && value.contains(',');
  }

  /// Detecta paths locais absolutos no sistema de arquivos do dispositivo.
  ///
  /// No Android/iOS, paths locais são absolutos (começam com `/`).
  /// Paths relativos do Supabase como `userId/ordens/…` NÃO começam com `/`,
  /// então este método os trata corretamente.
  bool _isAbsoluteLocalPath(String value) {
    if (kIsWeb) return false;
    // Unix (Android/iOS/macOS/Linux): path absoluto começa com '/'
    if (value.startsWith('/')) return true;
    // Windows: path absoluto começa com letra de drive (ex: C:\...)
    if (value.length > 2 && value[1] == ':') return true;
    return false;
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

  // ---------------------------------------------------------------------------
  // Utilitários
  // ---------------------------------------------------------------------------

  Future<int> countPending() async {
    if (kIsWeb) return 0;
    final db = await _databaseHelper.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_queue WHERE syncedAt IS NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
