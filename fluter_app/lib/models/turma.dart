import 'package:json_annotation/json_annotation.dart';
import 'prova.dart';

part 'turma.g.dart';

@JsonSerializable(explicitToJson: true) // explicitToJson é necessário para listas de objetos
class Turma {
  final String id;
  String nome;
  int numeroDeAlunos;
  List<Prova> provas;

  Turma({
    required this.id,
    required this.nome,
    required this.numeroDeAlunos,
    required this.provas,
  });

  factory Turma.fromJson(Map<String, dynamic> json) => _$TurmaFromJson(json);
  Map<String, dynamic> toJson() => _$TurmaToJson(this);
}