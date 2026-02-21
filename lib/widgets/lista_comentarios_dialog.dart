import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ListaComentariosDialog extends StatelessWidget {
  final String materiaId;
  final String nomeMateria;

  const ListaComentariosDialog({
    super.key,
    required this.materiaId,
    required this.nomeMateria,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Comentários - $nomeMateria'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('materias')
              .doc(materiaId)
              .collection('avaliacoes')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final comentarios = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey('comentario') &&
                  (data['comentario'] as String).trim().isNotEmpty;
            }).toList();

            if (comentarios.isEmpty) {
              return const Center(
                child: Text('Nenhum comentário ainda. Seja o primeiro!'),
              );
            }

            return ListView.separated(
              itemCount: comentarios.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final avaliacao =
                    comentarios[index].data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: (avaliacao['dificuldade'] ?? 0).toDouble(),
                            itemBuilder: (context, _) =>
                                const Icon(Icons.star, color: Colors.redAccent),
                            itemCount: 5,
                            itemSize: 14,
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Dificuldade',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          RatingBarIndicator(
                            rating: (avaliacao['avaliacao'] ?? 0).toDouble(),
                            itemBuilder: (context, _) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 14,
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Qualidade',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      avaliacao['comentario'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
