import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/prova.dart';
import '../services/analise_imagem_service.dart';
import 'tela_resultado.dart';

class TelaExibirFoto extends StatefulWidget {
  final String imagePath;
  final Prova prova;
  final String nomeAluno;
  final VoidCallback onDadosAlterados;

  const TelaExibirFoto({
    super.key,
    required this.imagePath,
    required this.prova,
    required this.nomeAluno,
    required this.onDadosAlterados,
  });

  @override
  State<TelaExibirFoto> createState() => _TelaExibirFotoState();
}

class _TelaExibirFotoState extends State<TelaExibirFoto> {
  bool _isProcessing = false;

  Future<void> _analisarEObterResultado() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final originalImageFile = File(widget.imagePath);
      final imageBytes = await originalImageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception("Não foi possível decodificar a imagem.");
      }
      
      final resizedImage = img.copyResize(originalImage, width: 1080);
      final tempDir = await getTemporaryDirectory();
      final resizedImageFile = File('${tempDir.path}/resized_temp.jpg')
        ..writeAsBytesSync(img.encodeJpg(resizedImage));

      final analiseService = AnaliseImagemService();
      final Map<String, String> respostasDoAluno = await analiseService.analisarImagem(resizedImageFile);

      if (!mounted) return;

      // Espera por um resultado da tela de resultado
      final bool? correcaoConcluida = await Navigator.pushReplacement<bool, void>(
        context,
        MaterialPageRoute(
          builder: (context) => TelaResultado(
            respostasAluno: respostasDoAluno,
            gabaritoMestre: widget.prova.gabaritoOficial,
            totalQuestoes: widget.prova.numeroDeQuestoes,
            prova: widget.prova,
            nomeAluno: widget.nomeAluno,
            onDadosAlterados: widget.onDadosAlterados,
          ),
        ),
      );

      // Se o resultado for 'true', fecha esta tela e envia o sinal para trás
      if (correcaoConcluida == true) {
        if (mounted) Navigator.of(context).pop(true);
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na análise: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifique a Foto')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(widget.imagePath), fit: BoxFit.contain),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Analisando gabarito...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          decoration: TextDecoration.none),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _analisarEObterResultado,
        label: _isProcessing ? const Text("Aguarde...") : const Text("Corrigir Prova"),
        icon: _isProcessing
            ? const SizedBox.shrink()
            : const Icon(Icons.check_circle),
      ),
    );
  }
}