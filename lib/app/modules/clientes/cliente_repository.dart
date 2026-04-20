import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/helpers/connectivity_helper.dart';
import '../../core/helpers/database_helper.dart';
import 'cliente.model.dart';

class ClienteRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'clientes';

  Future<void> salvar(Cliente cliente) async {
    final id = cliente.id ?? const Uuid().v4();
    final data = {
      ...cliente.toMap(),
      'id': id,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final online = await ConnectivityHelper.isOnline();

    if (online) {
      await _supabase.from(_table).upsert(data);
    } else {
      final db = await DatabaseHelper.instance.db;
      await db.insert(
        _table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Cliente>> listar() async {
    final online = await ConnectivityHelper.isOnline();

    if (online) {
      final response = await _supabase.from(_table).select();
      return (response as List).map((e) => Cliente.fromMap(e)).toList();
    } else {
      final db = await DatabaseHelper.instance.db;
      final rows = await db.query(_table);
      return rows.map((e) => Cliente.fromMap(e)).toList();
    }
  }
}
