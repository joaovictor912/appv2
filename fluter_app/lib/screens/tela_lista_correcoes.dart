import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/prova.dart';
import 'tela_detalhe_correcao.dart';

class TelaListaCorrecoes extends StatelessWidget {
  final Prova prova;

  const TelaListaCorrecoes({super.key, required this.prova});

  Future<void> _exportarRelatorioExcel(BuildContext context) async {
    if (prova.correcoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma correção para exportar.")),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Resultados'];

    // Define os estilos das células
    var headerStyle = CellStyle(bold: true);
    var redTextStyle = CellStyle(fontColorHex: "#FFFF0000"); // Vermelho

    // --- CÓDIGO CORRIGIDO E SIMPLIFICADO ---
    // Adiciona o cabeçalho diretamente.
    sheetObject.appendRow(['Nome do Aluno', 'Nota']);
    
    // Aplica o estilo ao cabeçalho.
    sheetObject.cell(CellIndex.indexByString("A1")).cellStyle = headerStyle;
    sheetObject.cell(CellIndex.indexByString("B1")).cellStyle = headerStyle;

    // Adiciona uma linha para cada correção
    for (int i = 0; i < prova.correcoes.length; i++) {
      final correcao = prova.correcoes[i];
      // Adiciona os valores (String e double) diretamente na lista.
      sheetObject.appendRow([correcao.nomeAluno, correcao.nota]);

      // Aplica a formatação condicional se a nota for menor que 6.
      if (correcao.nota < 6.0) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1));
        cell.cellStyle = redTextStyle;
      }
    }
    // --- FIM DA CORREÇÃO ---

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/relatorio_${prova.nome.replaceAll(' ', '_')}.xlsx";
      
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        await Share.shareXFiles([XFile(path)], text: 'Relatório da Prova: ${prova.nome}');
      }
    } catch (e) {
      print("Erro ao exportar Excel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correções Salvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Exportar Relatório',
            onPressed: () => _exportarRelatorioExcel(context),
          ),
        ],
      ),
      body: prova.correcoes.isEmpty
          ? const Center(
              child: Text( 'Nenhuma correção foi salva para esta prova ainda.' ),
            )
          : ListView.builder(
              itemCount: prova.correcoes.length,
              itemBuilder: (context, index) {
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