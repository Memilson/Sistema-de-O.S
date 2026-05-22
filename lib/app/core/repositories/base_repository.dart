import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../base/base.model.dart';
import '../helpers/connectivity_helper.dart';
import '../helpers/database_helper.dart';
import '../services/offline_sync_service.dart';
abstract class BaseRepository<T extends BaseModel> {
  final SupabaseClient supabase;
  final DatabaseHelper databaseHelper;
  final OfflineSyncService offlineSyncService;
  BaseRepository({
    SupabaseClient? supabase,
    DatabaseHelper? databaseHelper,
    OfflineSyncService? offlineSyncService,
  })  : supabase = supabase ?? Supabase.instance.client,
        databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        offlineSyncService = offlineSyncService ?? OfflineSyncService();
  String get tableName;
  String get defaultOrderBy => 'createdAt';
  bool get defaultAscending => true;
  T fromMap(Map<String, dynamic> map);
  // Ponto de entrada unificado para salvar objetos (Cliente, O.S., etc)
  Future<String> salvar(T item) async {
    final data = _prepareData(item);
    await salvarMap(data);
    return data['id'] as String;
  }

  // Gerencia o fluxo Offline-First: decide entre Supabase (online) ou SQLite (offline)
  Future<void> salvarMap(Map<String, dynamic> data) async {
    final online = await ConnectivityHelper.isOnline();
    if (online) {
      await supabase.from(tableName).upsert(data);
      // Salva localmente para cache, mas sem marcar para sincronizar
      await _saveLocal(data, enqueue: false);
      return;
    }
    // Modo Offline: garante persistência local e entra na fila de sincronismo
    await _saveLocal(data, enqueue: true);
  }

  // Recupera dados: tenta nuvem primeiro, faz fallback para banco local se offline
  Future<List<T>> listar({String? orderBy, bool? ascending}) async {
    final user = _currentUserOrThrow();
    final online = await ConnectivityHelper.isOnline();
    if (online) {
      final response = await supabase.from(tableName).select().eq('userId', user.id).order(
        orderBy ?? defaultOrderBy,
        ascending: ascending ?? defaultAscending,
      );
      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map(fromMap).toList();
    }
    
    // Fallback para o banco de dados local do dispositivo
    if (kIsWeb) throw const AuthException('Sem conexão para consultar dados no Web');
    final db = await databaseHelper.db;
    final rows = await db.query(
      tableName,
      where: 'userId = ?',
      whereArgs: [user.id],
      orderBy: '${orderBy ?? defaultOrderBy} ${(ascending ?? defaultAscending) ? 'ASC' : 'DESC'}',
    );
    return rows.map(fromMap).toList();
  }
  Future<T?> buscarPorId(String id) async {
    final user = _currentUserOrThrow();
    final online = await ConnectivityHelper.isOnline();
    if (online) {
      final response = await supabase.from(tableName).select().eq('id', id).eq('userId', user.id).maybeSingle();
      if (response == null) return null;
      return fromMap(response);
    }
    if (kIsWeb) throw const AuthException('Sem conexão para consultar dados no Web');
    final db = await databaseHelper.db;
    final rows = await db.query(tableName, where: 'id = ? AND userId = ?', whereArgs: [id, user.id], limit: 1);
    if (rows.isEmpty) return null;
    return fromMap(rows.first);
  }
  Future<void> excluir(String id) async {
    final user = _currentUserOrThrow();
    final online = await ConnectivityHelper.isOnline();
    if (online) {
      await supabase.from(tableName).delete().eq('id', id).eq('userId', user.id);
      await _deleteLocal(id);
      return;
    }
    if (kIsWeb) throw const AuthException('Sem conexão para excluir dados no Web');
    await _deleteLocal(id);
    await offlineSyncService.enqueueDelete(tableName: tableName, recordId: id, payload: {'id': id, 'userId': user.id});
  }
  Map<String, dynamic> _prepareData(T item) {
    final user = _currentUserOrThrow();
    final data = item.toMap();
    final id = item.id ?? data['id'] as String? ?? const Uuid().v4();
    final createdAt = item.createdAt?.toIso8601String() ?? data['createdAt'] as String? ?? DateTime.now().toIso8601String();
    return {...data, 'id': id, 'userId': user.id, 'createdAt': createdAt};
  }
  Future<void> _saveLocal(Map<String, dynamic> data, {required bool enqueue}) async {
    if (kIsWeb) {
      if (enqueue) throw const AuthException('Sem conexão para salvar dados no Web');
      return;
    }
    final db = await databaseHelper.db;
    await db.insert(tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
    if (enqueue) {
      await offlineSyncService.enqueueUpsert(tableName: tableName, recordId: data['id'] as String, payload: data);
    }
  }
  Future<void> _deleteLocal(String id) async {
    if (kIsWeb) return;
    final db = await databaseHelper.db;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
  User _currentUserOrThrow() {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Usuario nao autenticado');
    return user;
  }
}
