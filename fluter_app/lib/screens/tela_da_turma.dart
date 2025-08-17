import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prova.dart';
import '../models/turma.dart';
import 'tela_da_prova.dart';
import 'tela_gabarito_mestre.dart';

class TelaDaTurma extends StatefulWidget {
  final Turma turma;
  final CameraDescription camera;
  final VoidCallback onDadosAlterados;

  const TelaDaTurma({
    super.key,
    required this.turma,
    required this.camera,
    required this.onDadosAlterados,
  });

  @override
  State<TelaDaTurma> createState() => _TelaDaTurmaState();
}

class _TelaDaTurmaState extends State<TelaDaTurma> {
  // A função _mostrarDialogoNovaProva permanece exatamente a mesma.
  void _mostrarDialogoNovaProva() {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController questoesController = TextEditingController();
    DateTime dataSelecionada = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova Prova'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nome da Prova'),
                  ),
                  TextField(
                    controller: questoesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nº de Questões'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Data: '),
                      Text(
                        DateFormat('dd/MM/yyyy').format(dataSelecionada),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        onPressed: () async {
                          final DateTime? dataEscolhida = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (dataEscolhida != null) {
                            setDialogState(() {
                              dataSelecionada = dataEscolhida;
                            });
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nomeController.text.isNotEmpty) {
                      final int numeroDeQuestoes =
                          int.tryParse(questoesController.text) ?? 20;

                      setState(() {
                        widget.turma.provas.add(
                          Prova(
                            id: DateTime.now().toString(),
                            nome: nomeController.text,
                            data: DateFormat('dd/MM/yyyy').format(dataSelecionada),
                            numeroDeQuestoes: numeroDeQuestoes,
                          ),
                        );
                      });

                      widget.onDadosAlterados();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.turma.nome),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: widget.turma.provas.length,
        itemBuilder: (context, index) {
          final prova = widget.turma.provas[index];
          
          // --- INÍCIO DA ALTERAÇÃO ---
          // Envolvemos o Card num widget Dismissible
          return Dismissible(
            // A chave (key) é essencial para o Flutter identificar o item a ser removido
            key: Key(prova.id),
            // Define a direção do arrasto (da direita para a esquerda)
            direction: DismissDirection.endToStart,
            // O fundo que aparece ao arrastar
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete_sweep, color: Colors.white),
            ),
            // A função que é executada após o item ser removido da tela
            onDismissed: (direction) {
              // Guarda o nome da prova para a mensagem de confirmação
              final nomeProvaRemovida = prova.nome;
              
              // Remove a prova da lista e atualiza a interface
              setState(() {
                widget.turma.provas.removeAt(index);
              });

              // Chama a função para salvar o estado permanentemente
              widget.onDadosAlterados();

              // Mostra uma mensagem de confirmação
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${nomeProvaRemovida}" removida')),
              );
            },
            // O filho do Dismissible é o nosso Card original
            child: Card(
              child: ListTile(
                leading: Icon(
                  Icons.article_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
                title: Text(prova.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${prova.correcoes.length} correções • ${prova.numeroDeQuestoes} questões"),
                trailing: IconButton(
                  icon: const Icon(Icons.playlist_add_check),
                  tooltip: 'Editar Gabarito',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaGabaritoMestre(
                          prova: prova,
                          onGabaritoSalvo: widget.onDadosAlterados,
                        ),
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/telaDaProva'),
                      builder: (context) => TelaDaProva(
                        prova: prova,
                        camera: widget.camera,
                        onDadosAlterados: widget.onDadosAlterados,
                      ),
                    ),
                  ).then((_) => setState((){}));
                },
              ),
            ),
          );
          // --- FIM DA ALTERAÇÃO ---
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovaProva,
        label: const Text('Nova Prova'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}