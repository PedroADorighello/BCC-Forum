import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/materia_model.dart';

class FirebaseService {
  final CollectionReference _materiasRef = FirebaseFirestore.instance
      .collection('materias');

  Stream<List<Materia>> getMateriasStream() {
    return _materiasRef
        .where('ativo', isEqualTo: true)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Materia.fromFirestore(doc))
              .toList();
        });
  }

  Future<List<String>> obterMateriasAvaliadasPeloUsuario(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('avaliacoes')
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.reference.parent.parent!.id)
        .toList();
  }

  Future<void> computarVoto({
    required String materiaId,
    required String userId,
    required double novaDificuldade,
    required double novaAvaliacao,
    String? comentario,
  }) async {
    final materiaRef = _materiasRef.doc(materiaId);
    final avaliacaoRef = materiaRef.collection('avaliacoes').doc(userId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final materiaSnap = await transaction.get(materiaRef);
      final avaliacaoSnap = await transaction.get(avaliacaoRef);

      if (!materiaSnap.exists) throw Exception("Matéria não encontrada!");

      int votosAtuais = materiaSnap['votos'] ?? 0;
      double somaDifAtual = (materiaSnap['soma_dificuldade'] ?? 0).toDouble();
      double somaAvalAtual = (materiaSnap['soma_avaliacao'] ?? 0).toDouble();

      if (avaliacaoSnap.exists) {
        double difAntiga = (avaliacaoSnap['dificuldade'] ?? 0).toDouble();
        double avalAntiga = (avaliacaoSnap['avaliacao'] ?? 0).toDouble();

        transaction.update(materiaRef, {
          'soma_dificuldade': somaDifAtual - difAntiga + novaDificuldade,
          'soma_avaliacao': somaAvalAtual - avalAntiga + novaAvaliacao,
        });
      } else {
        transaction.update(materiaRef, {
          'votos': votosAtuais + 1,
          'soma_dificuldade': somaDifAtual + novaDificuldade,
          'soma_avaliacao': somaAvalAtual + novaAvaliacao,
        });
      }

      final dadosAvaliacao = <String, dynamic>{
        'userId': userId,
        'dificuldade': novaDificuldade,
        'avaliacao': novaAvaliacao,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (comentario != null) {
        dadosAvaliacao['comentario'] = comentario.trim();
      }

      transaction.set(avaliacaoRef, dadosAvaliacao);
    });
  }
}
