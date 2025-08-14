import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/prova.dart';
import 'tela_detalhe_correcao.dart'; // Tela que vamos criar a seguir

class TelaListaCorrecoes extends StatelessWidget {
  final Prova prova;

  const TelaListaCorrecoes({super.key, required this.prova});

  Future<void> _exportarRelatorioSimples(BuildContext context) async {
    if (prova.correcoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma correção para exportar.")),
      );
      return;
    }

    List<List<dynamic>> linhas = [];
    // Cabeçalho simplificado como você pediu
    linhas.add(["Nome do Aluno", "Nota"]);

    for (var correcao in prova.correcoes) {
      linhas.add([
        correcao.nomeAluno,
        correcao.nota.toStringAsFixed(1),
      ]);
    }

    String csv = const ListToCsvConverter().convert(linhas);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/relatorio_simplificado_${prova.nome.replaceAll(' ', '_')}.csv";
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Relatório da Prova: ${prova.nome}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correções Salvas'),
        actions: [
          // Botão para exportar o relatório simplificado
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Exportar CSV (Nome e Nota)',
            onPressed: () => _exportarRelatorioSimples(context),
          ),
        ],
      ),
      body: prova.correcoes.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma correção foi salva para esta prova ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: prova.correcoes.length,
              itemBuilder: (context, index) {
                // Ordena da mais recente para a mais antiga
                final correcao = prova.correcoes.reversed.toList()[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      correcao.nomeAluno,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Nota: ${correcao.nota.toStringAsFixed(1)}'),
                    trailing: Text('${correcao.acertos}/${prova.numeroDeQuestoes}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaDetalheCorrecao(
                            correcao: correcao,
                            gabaritoMestre: prova.gabaritoOficial,
                            totalQuestoes: prova.numeroDeQuestoes,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}