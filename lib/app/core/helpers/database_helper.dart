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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clientes (
            id TEXT PRIMARY KEY,
            userId TEXT,
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
            userId TEXT,
            clienteId TEXT NOT NULL,
            clienteNome TEXT NOT NULL,
            descricao TEXT,
            valor REAL,
            status TEXT,
            fotoAntesPath TEXT,
            fotoDepoisPath TEXT,
            assinaturaBase64 TEXT,
            createdAt TEXT
          )
        ''');
        await _createSyncQueue(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE clientes ADD COLUMN userId TEXT');
          await db.execute('ALTER TABLE ordens_servico ADD COLUMN userId TEXT');
          await db.execute(
            'ALTER TABLE ordens_servico ADD COLUMN fotoAntesPath TEXT',
          );
          await db.execute(
            'ALTER TABLE ordens_servico ADD COLUMN fotoDepoisPath TEXT',
          );
          await db.execute(
            'ALTER TABLE ordens_servico ADD COLUMN assinaturaBase64 TEXT',
          );
        }
        if (oldVersion < 3) {
          await _createSyncQueue(db);
        }
      },
    );
  }

  Future<void> _createSyncQueue(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        syncedAt TEXT,
        error TEXT
      )
    ''');
  }
}
