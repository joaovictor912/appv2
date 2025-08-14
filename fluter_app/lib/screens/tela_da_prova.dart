import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/prova.dart';
import 'tela_da_camera.dart';
import 'tela_lista_correcoes.dart';

class TelaDaProva extends StatefulWidget {
  final Prova prova;
  final CameraDescription camera;
  final VoidCallback onDadosAlterados;

  const TelaDaProva({
    super.key,
    required this.prova,
    required this.camera,
    required this.onDadosAlterados,
  });

  @override
  State<TelaDaProva> createState() => _TelaDaProvaState();
}

class _TelaDaProvaState extends State<TelaDaProva> {
  // O controlador foi removido daqui para ser criado dentro da função.
  // final TextEditingController _nomeAlunoController = TextEditingController();

  Future<void> _iniciarCorrecao() async {
    // --- MUDANÇA 1: O controlador é criado aqui ---
    // Isto garante um controlador novo e vazio a cada chamada.
    final nomeAlunoController = TextEditingController();

    final nomeAluno = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Correção'),
        content: TextField(
          // --- MUDANÇA 2: Usamos o novo controlador local ---
          controller: nomeAlunoController,
          autofocus: true,
          style: const TextStyle(color: Colors.black), 
          decoration: const InputDecoration(hintText: 'Nome do Aluno'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            child: const Text('Continuar'),
            onPressed: () {
              if (nomeAlunoController.text.isNotEmpty) {
                Navigator.pop(context, nomeAlunoController.text);
              }
            },
          ),
        ],
      ),
    );

    // O controlador local é descartado automaticamente quando a função termina.

    if (nomeAluno != null && nomeAluno.isNotEmpty) {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/telaDaProva'),
          builder: (context) => TelaDaCamera(
            prova: widget.prova,
            camera: widget.camera,
            nomeAluno: nomeAluno,
            onDadosAlterados: widget.onDadosAlterados,
          ),
        ),
      );
      
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prova.nome),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Nova Correção'),
                onPressed: _iniciarCorrecao,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                icon: const Icon(Icons.history),
                label: Text('Ver Correções (${widget.prova.correcoes.length})'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaListaCorrecoes(prova: widget.prova),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}