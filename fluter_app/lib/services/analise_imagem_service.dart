import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AnaliseImagemService {
  
  final String _baseUrl = 'https://corretor-gabarito-backend.onrender.com';

  Future<Map<String, String>> analisarImagem(File imagem) async {
    final uri = Uri.parse('$_baseUrl/analisar_prova');
    var request = http.MultipartRequest('POST', uri);
    
    request.files.add(await http.MultipartFile.fromPath('imagem', imagem.path));

    try { 
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      
      
      final dynamic decodedJson = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200) {
        // Verificamos se a resposta é um Mapa
        if (decodedJson is Map) {
          if (decodedJson.containsKey('erro')) {
            throw Exception('Erro no servidor: ${decodedJson['erro']}');
          }
          // Convertemos explicitamente o mapa para Map<String, String>
          // Isto garante que o tipo retornado é o correto.
          return decodedJson.map((key, value) => MapEntry(key.toString(), value.toString()));
        } else {
          // Se a resposta não for um mapa, é um erro inesperado.
          throw Exception('Resposta inesperada do servidor.');
        }
        // --- FIM DA CORREÇÃO ---
      } else {
        // Tentamos ler a mensagem de erro do JSON, se houver
        final erroMsg = (decodedJson is Map && decodedJson.containsKey('erro')) 
                          ? decodedJson['erro'] 
                          : 'Erro desconhecido';
        throw Exception('Falha na análise: $erroMsg');
      }
    } catch (e) {
      // O erro que você viu na tela foi apanhado aqui
      throw Exception('Erro de comunicação com o servidor: ${e.toString()}');
    }
  }
}
