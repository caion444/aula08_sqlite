import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Tarefa {
  final int? id;
  final String titulo;
  final String descricao;

  const Tarefa({
    this.id,
    required this.titulo,
    required this.descricao,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
    };
  }

  factory Tarefa.fromMap(Map<String, Object?> map) {
    return Tarefa(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      descricao: map['descricao'] as String,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Fallback em memoria caso rode em ambiente Web sem driver nativo SQLite
  final List<Tarefa> _webMemoryStore = [];
  int _webAutoIncrement = 1;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tarefas_aula08.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tarefas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(Tarefa tarefa) async {
    if (kIsWeb) {
      final nova = Tarefa(
        id: _webAutoIncrement++,
        titulo: tarefa.titulo,
        descricao: tarefa.descricao,
      );
      _webMemoryStore.insert(0, nova);
      return nova.id!;
    }
    final db = await instance.database;
    return await db.insert('tarefas', tarefa.toMap());
  }

  Future<List<Tarefa>> getAll() async {
    if (kIsWeb) {
      return List<Tarefa>.from(_webMemoryStore);
    }
    final db = await instance.database;
    final result = await db.query('tarefas', orderBy: 'id DESC');
    return result.map((map) => Tarefa.fromMap(map)).toList();
  }

  // Exercicio 03: Busca por texto simples utilizando a clausula WHERE titulo LIKE %...%
  Future<List<Tarefa>> searchByTitulo(String termo) async {
    if (kIsWeb) {
      final query = termo.toLowerCase();
      return _webMemoryStore
          .where((t) => t.titulo.toLowerCase().contains(query))
          .toList();
    }
    final db = await instance.database;
    final result = await db.query(
      'tarefas',
      where: 'titulo LIKE ?',
      whereArgs: ['%$termo%'],
      orderBy: 'id DESC',
    );
    return result.map((map) => Tarefa.fromMap(map)).toList();
  }

  Future<int> deleteById(int id) async {
    if (kIsWeb) {
      _webMemoryStore.removeWhere((t) => t.id == id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'tarefas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Exercicio 02: Metodo deleteAll() para limpar todas as tarefas do SQLite
  Future<int> deleteAll() async {
    if (kIsWeb) {
      final count = _webMemoryStore.length;
      _webMemoryStore.clear();
      return count;
    }
    final db = await instance.database;
    return await db.delete('tarefas');
  }
}
