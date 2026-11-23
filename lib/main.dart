import 'package:flutter/material.dart';
import 'database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Aula08SqliteApp());
}

class Aula08SqliteApp extends StatelessWidget {
  const Aula08SqliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aula 08 - SQLite Relacional',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TarefasSqliteScreen(),
    );
  }
}

class TarefasSqliteScreen extends StatefulWidget {
  const TarefasSqliteScreen({super.key});

  @override
  State<TarefasSqliteScreen> createState() => _TarefasSqliteScreenState();
}

class _TarefasSqliteScreenState extends State<TarefasSqliteScreen> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _buscaController = TextEditingController();

  List<Tarefa> _tarefas = [];
  int _totalNoBanco = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _atualizarLista() async {
    final todas = await DatabaseHelper.instance.getAll();
    final termo = _buscaController.text.trim();
    final filtradas = termo.isEmpty
        ? todas
        : await DatabaseHelper.instance.searchByTitulo(termo);

    if (!mounted) return;
    setState(() {
      _totalNoBanco = todas.length;
      _tarefas = filtradas;
      _carregando = false;
    });
  }

  Future<void> _adicionarTarefa() async {
    final titulo = _tituloController.text.trim();
    final descricao = _descricaoController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o título da tarefa.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await DatabaseHelper.instance.insert(
      Tarefa(
        titulo: titulo,
        descricao: descricao.isEmpty ? 'Sem descrição adicional' : descricao,
      ),
    );

    _tituloController.clear();
    _descricaoController.clear();
    await _atualizarLista();
  }

  // Exercicio 02: Aciona deleteAll() pelo botao da AppBar
  Future<void> _limparTodasTarefas() async {
    await DatabaseHelper.instance.deleteAll();
    _buscaController.clear();
    await _atualizarLista();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas as tarefas foram removidas via deleteAll().'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas SQLite - Aula 08'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Exercicio 02: Botao na AppBar para limpar todas as tarefas do SQLite
          IconButton(
            tooltip: 'Limpar todas as tarefas (deleteAll)',
            icon: const Icon(Icons.delete_forever),
            onPressed: _totalNoBanco == 0 ? null : _limparTodasTarefas,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulario de cadastro no SQLite
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título da Tarefa',
                        prefixIcon: Icon(Icons.task_alt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descricaoController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              prefixIcon: Icon(Icons.notes),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _adicionarTarefa,
                          icon: const Icon(Icons.add),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Exercicio 03: Campo de busca utilizando WHERE titulo LIKE %...%
            TextField(
              controller: _buscaController,
              onChanged: (_) => _atualizarLista(),
              decoration: InputDecoration(
                labelText: 'Buscar por título (WHERE titulo LIKE %...%)',
                hintText: 'Digite para filtrar no SQLite...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          _atualizarLista();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Lista de registros do banco relacional
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _tarefas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma tarefa encontrada no banco SQLite.',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tarefas.length,
                          itemBuilder: (context, index) {
                            final tarefa = _tarefas[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text(
                                    '#${tarefa.id}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  tarefa.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(tarefa.descricao),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    if (tarefa.id != null) {
                                      await DatabaseHelper.instance
                                          .deleteById(tarefa.id!);
                                      await _atualizarLista();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // Exercicio 01: Contador visual no rodape indicando a quantidade total de tarefas no banco
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          border: Border(top: BorderSide(color: Colors.indigo.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storage, color: Colors.indigo, size: 20),
            const SizedBox(width: 8),
            Text(
              'Total de tarefas registradas no SQLite: $_totalNoBanco',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
