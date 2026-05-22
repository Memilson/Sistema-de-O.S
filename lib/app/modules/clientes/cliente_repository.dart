import '../../core/repositories/base_repository.dart';
import 'cliente.model.dart';
  // Implementação concreta do repositório de clientes (Supabase + SQLite)
class ClienteRepository extends BaseRepository<Cliente> {
  ClienteRepository({super.supabase, super.databaseHelper, super.offlineSyncService});
  @override
  String get tableName => 'clientes';
  @override
  bool get defaultAscending => true;
  @override
  Cliente fromMap(Map<String, dynamic> map) => Cliente.fromMap(map);
}
