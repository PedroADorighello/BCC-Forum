import 'package:cloud_firestore/cloud_firestore.dart';

class Materia {
  final String id;
  final String nome;
  final String categoria;
  final int votos;
  final double somaDificuldade;
  final double somaAvaliacao;

  Materia({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.votos,
    required this.somaDificuldade,
    required this.somaAvaliacao,
  });

  factory Materia.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Materia(
      id: doc.id,
      nome: data['nome'] ?? '',
      categoria: data['categoria'] ?? 'Obrigatória',
      votos: data['votos'] ?? 0,
      somaDificuldade: (data['soma_dificuldade'] ?? 0).toDouble(),
      somaAvaliacao: (data['soma_avaliacao'] ?? 0).toDouble(),
    );
  }

  double get mediaDificuldade => votos == 0 ? 0 : somaDificuldade / votos;
  double get mediaAvaliacao => votos == 0 ? 0 : somaAvaliacao / votos;
}
