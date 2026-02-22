import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/materia_model.dart';
import '../services/firebase_service.dart';

class VotacaoDialog extends StatefulWidget {
  final Materia materia;

  const VotacaoDialog({super.key, required this.materia});

  @override
  State<VotacaoDialog> createState() => _VotacaoDialogState();
}

class _VotacaoDialogState extends State<VotacaoDialog> {
  double notaDificuldade = 3.0;
  double notaAvaliacao = 3.0;
  final TextEditingController _comentarioController = TextEditingController();

  bool isSubmitting = false;
  bool isLoadingAnterior = true;
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseService _firebaseService = FirebaseService();
  bool _comentarioExcluido = false;

  @override
  void initState() {
    super.initState();
    _buscarVotoAnterior();
  }

  Future<void> _buscarVotoAnterior() async {
    final doc = await FirebaseFirestore.instance
        .collection('materias')
        .doc(widget.materia.id)
        .collection('avaliacoes')
        .doc(_userId)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        notaDificuldade = (data['dificuldade'] ?? 3).toDouble();
        notaAvaliacao = (data['avaliacao'] ?? 3).toDouble();

        if (data.containsKey('comentario')) {
          _comentarioController.text = data['comentario'];
          _comentarioExcluido = false;
        } else {
          _comentarioExcluido = true;
        }
      });
    }
    if (mounted) setState(() => isLoadingAnterior = false);
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text(
        'Avaliar: ${widget.materia.nome}',
        style: TextStyle(fontSize: (larguraTela * 0.015).clamp(18.0, 22.0)),
      ),
      content: isLoadingAnterior
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dificuldade:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RatingBar.builder(
                    initialRating: notaDificuldade,
                    minRating: 1,
                    itemCount: 5,
                    itemSize: 28,
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.redAccent),
                    onRatingUpdate: (rating) =>
                        setState(() => notaDificuldade = rating),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Qualidade:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RatingBar.builder(
                    initialRating: notaAvaliacao,
                    minRating: 1,
                    itemCount: 5,
                    itemSize: 28,
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) =>
                        setState(() => notaAvaliacao = rating),
                  ),
                  const SizedBox(height: 16),
                  _comentarioExcluido
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.block, color: Colors.redAccent),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'O seu comentário foi excluído pela moderação.',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextField(
                          controller: _comentarioController,
                          maxLength: 250,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Comentário (Opcional)',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                ],
              ),
            ),
      actions: [
        if (!isSubmitting)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        if (!isSubmitting)
          ElevatedButton(
            onPressed: () async {
              setState(() => isSubmitting = true);
              await _firebaseService.computarVoto(
                materiaId: widget.materia.id,
                userId: _userId,
                novaDificuldade: notaDificuldade,
                novaAvaliacao: notaAvaliacao,
                comentario: _comentarioExcluido
                    ? null
                    : _comentarioController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avaliação salva com sucesso!')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
      ],
    );
  }
}
