import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'serviceflow.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clientes (
            id TEXT PRIMARY KEY,
            nome TEXT NOT NULL,
            cpfCnpj TEXT,
            email TEXT,
            telefone TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ordens_servico (
            id TEXT PRIMARY KEY,
            clienteId TEXT NOT NULL,
            clienteNome TEXT NOT NULL,
            descricao TEXT,
            valor REAL,
            status TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }
}
