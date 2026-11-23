import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aula08_sqlite/database/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Valida insert, searchByTitulo (LIKE) e deleteAll no SQLite', () async {
    await DatabaseHelper.instance.deleteAll();
    await DatabaseHelper.instance.insert(
      const Tarefa(titulo: 'Estudar Flutter SQLite', descricao: 'Aula 08'),
    );
    await DatabaseHelper.instance.insert(
      const Tarefa(titulo: 'Revisar Dart JSON', descricao: 'Licao 09'),
    );

    final busca = await DatabaseHelper.instance.searchByTitulo('Flutter');
    expect(busca.length, 1);
    expect(busca.first.titulo, 'Estudar Flutter SQLite');

    await DatabaseHelper.instance.deleteAll();
    final aposLimpar = await DatabaseHelper.instance.getAll();
    expect(aposLimpar.isEmpty, true);
  });
}
