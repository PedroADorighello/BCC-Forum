import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListaComentariosDialog extends StatefulWidget {
  final String materiaId;
  final String nomeMateria;

  const ListaComentariosDialog({
    super.key,
    required this.materiaId,
    required this.nomeMateria,
  });

  @override
  State<ListaComentariosDialog> createState() => _ListaComentariosDialogState();
}

class _ListaComentariosDialogState extends State<ListaComentariosDialog> {
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    Widget conteudoDialog;

    if (user == null) {
      conteudoDialog = Center(
        child: Text(
          'Faça login com um email institucional para ver os comentários.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: (larguraTela * 0.015).clamp(12.0, 16.0)),
        ),
      );
    } else if (!user!.emailVerified) {
      conteudoDialog = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Verificação Necessária',
              style: TextStyle(
                fontSize: (larguraTela * 0.015).clamp(16.0, 20.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor, verifique a sua caixa de entrada e clique no link de confirmação para libertar os comentários.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (larguraTela * 0.015).clamp(12.0, 16.0),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Reenviar Link'),
              onPressed: () async {
                await user!.sendEmailVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-mail reenviado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } else {
      conteudoDialog = StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('materias')
            .doc(widget.materiaId)
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
            return Center(
              child: Text(
                'Nenhum comentário ainda. Seja o primeiro!',
                style: TextStyle(
                  fontSize: (larguraTela * 0.015).clamp(12.0, 16.0),
                ),
              ),
            );
          }

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: RawScrollbar(
              thumbVisibility: true,
              thumbColor: Colors.grey[350],
              controller: _scrollController,
              thickness: 4,
              child: ListView.separated(
                padding: const EdgeInsets.only(right: 8.0),
                controller: _scrollController,
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            final children = [
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: (avaliacao['dificuldade'] ?? 0)
                                        .toDouble(),
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.redAccent,
                                    ),
                                    itemCount: 5,
                                    itemSize: (larguraTela * 0.012).clamp(
                                      14.0,
                                      16.0,
                                    ),
                                    direction: Axis.horizontal,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dificuldade',
                                    style: TextStyle(
                                      fontSize: (larguraTela * 0.012).clamp(
                                        12.0,
                                        14.0,
                                      ),
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: (avaliacao['avaliacao'] ?? 0)
                                        .toDouble(),
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: (larguraTela * 0.012).clamp(
                                      14.0,
                                      16.0,
                                    ),
                                    direction: Axis.horizontal,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Qualidade',
                                    style: TextStyle(
                                      fontSize: (larguraTela * 0.012).clamp(
                                        12.0,
                                        14.0,
                                      ),
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ];
                            return isMobile
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: children,
                                  )
                                : Row(children: [...children]);
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        avaliacao['comentario'],
                        style: TextStyle(
                          fontSize: (larguraTela * 0.012).clamp(14.0, 16.0),
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }

    return AlertDialog(
      title: Text(
        'Comentários - ${widget.nomeMateria}',
        style: TextStyle(fontSize: (larguraTela * 0.015).clamp(18.0, 22.0)),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: conteudoDialog,
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
