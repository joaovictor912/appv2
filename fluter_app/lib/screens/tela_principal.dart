import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/turma.dart';
import 'tela_da_turma.dart';
import '../services/persistencia_service.dart';

// Define que esta tela será um StatefulWidget, pois o seu conteúdo (a lista de turmas) pode mudar.
class TelaPrincipal extends StatefulWidget {
  // Recebe a instância da câmera inicializada no main.dart.
  final CameraDescription camera;
  const TelaPrincipal({super.key, required this.camera});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

// A classe que gere o estado (os dados) da TelaPrincipal.
class _TelaPrincipalState extends State<TelaPrincipal> {
  // Lista que armazena as turmas em memória.
  List<Turma> _turmas = [];
  // Variável para mostrar um indicador de carregamento enquanto os dados são lidos do disco.
  bool _isLoading = true;
  // Instância do serviço que sabe como ler e escrever no armazenamento do dispositivo.
  final PersistenciaService _persistenciaService = PersistenciaService();

  // Função chamada uma única vez quando a tela é criada.
  @override
  void initState() {
    super.initState();
    // Inicia o processo de carregar as turmas salvas.
    _carregarDados();
  }

  // Função assíncrona para ler os dados salvos no dispositivo.
  Future<void> _carregarDados() async {
    final turmasSalvas = await _persistenciaService.carregarTurmas();
    // Atualiza o estado da tela com os dados carregados e desativa o loading.
    setState(() {
      _turmas = turmasSalvas;
      _isLoading = false;
    });
  }

  // Função assíncrona para salvar a lista atual de turmas no dispositivo.
  Future<void> _salvarDados() async {
    await _persistenciaService.salvarTurmas(_turmas);
    print("Dados salvos com sucesso!");
  }

  // Função que exibe a janela de diálogo para criar ou editar uma turma.
  void _mostrarDialogoTurma({Turma? turmaExistente}) {
    final bool isEditing = turmaExistente != null;
    final nomeController = TextEditingController(text: isEditing ? turmaExistente.nome : '');
    final alunosController = TextEditingController(text: isEditing ? turmaExistente.numeroDeAlunos.toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Turma' : 'Nova Turma'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nomeController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome da Turma'),
            ),
            TextField(
              controller: alunosController,
              decoration: const InputDecoration(labelText: 'Nº de Alunos'),
              keyboardType: TextInputType.number,
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text;
                final numeroDeAlunos = int.tryParse(alunosController.text) ?? 0;
                if (nome.isNotEmpty) {
                  setState(() {
                    if (isEditing) {
                      turmaExistente.nome = nome;
                      turmaExistente.numeroDeAlunos = numeroDeAlunos;
                    } else {
                      _turmas.add(Turma(
                        id: DateTime.now().toString(),
                        nome: nome,
                        numeroDeAlunos: numeroDeAlunos,
                        provas: [],
                      ));
                    }
                  });
                  _salvarDados();
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Constrói a aparência visual da tela.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Turmas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _turmas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma turma cadastrada.\nClique no botão + para adicionar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _turmas.length,
                  itemBuilder: (context, index) {
                    final turma = _turmas[index];
                    return Dismissible(
                      key: Key(turma.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete_sweep, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          _turmas.removeAt(index);
                        });
                        _salvarDados();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${turma.nome} removida')),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            child: Text(turma.nome.substring(0, 1).toUpperCase()),
                          ),
                          title: Text(turma.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${turma.provas.fold(0, (total, prova) => total + prova.correcoes.length)} correções • ${turma.provas.length} provas"),
                          
                          // --- CORREÇÃO APLICADA AQUI ---
                          trailing: IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => _mostrarDialogoTurma(turmaExistente: turma),
                          ),
                          // --- FIM DA CORREÇÃO ---

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TelaDaTurma(
                                  turma: turma,
                                  camera: widget.camera,
                                  onDadosAlterados: _salvarDados,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoTurma,
        tooltip: 'Adicionar Turma',
        child: const Icon(Icons.add),
      ),
    );
  }
}