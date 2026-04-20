import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/helpers/connectivity_helper.dart';
import '../../core/helpers/database_helper.dart';
import 'ordem_servico.model.dart';

class OrdemServicoRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'ordens_servico';

  Future<void> salvar(OrdemServico os) async {
    final id = os.id ?? const Uuid().v4();
    final data = {
      ...os.toMap(),
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

  Future<List<OrdemServico>> listar() async {
    final online = await ConnectivityHelper.isOnline();

    if (online) {
      final response = await _supabase.from(_table).select();
      return (response as List).map((e) => OrdemServico.fromMap(e)).toList();
    } else {
      final db = await DatabaseHelper.instance.db;
      final rows = await db.query(_table);
      return rows.map((e) => OrdemServico.fromMap(e)).toList();
    }
  }
}
