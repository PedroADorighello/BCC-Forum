import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/materia_model.dart';
import '../services/firebase_service.dart';
import '../widgets/votacao_dialog.dart';
import '../widgets/lista_comentarios_dialog.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'login_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService firebaseService = FirebaseService();

  String _termoPesquisa = '';
  String _criterioOrdenacao = 'Mais Avaliadas';
  String _filtroCategoria = 'Todas';

  bool _mostrarApenasMinhas = false;
  List<String> _minhasMateriasIds = [];

  StreamSubscription<User?>? _authSubscription;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _carregarMinhasAvaliacoes(user.uid);
      } else {
        setState(() {
          _minhasMateriasIds.clear();
          _mostrarApenasMinhas = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _carregarMinhasAvaliacoes(String uid) async {
    try {
      final ids = await firebaseService.obterMateriasAvaliadasPeloUsuario(uid);
      if (mounted) {
        setState(() {
          _minhasMateriasIds = ids;
        });
      }
    } catch (e) {
      print('Erro ao carregar avaliações em segundo plano: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double tamanhoTitulo = (larguraTela * 0.025).clamp(16.0, 22.0);
    double tamanhoSubtitulo = (larguraTela * 0.015).clamp(14.0, 16.0);
    ScrollController scrollController2 = ScrollController();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BCC UFSCar - Fórum',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Ordenar disciplinas',
            onSelected: (valor) {
              setState(() {
                _criterioOrdenacao = valor;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Nome (A-Z)',
                child: Text('Nome (A-Z)'),
              ),
              const PopupMenuItem(
                value: 'Melhor Avaliadas',
                child: Text('Melhor Avaliadas'),
              ),
              const PopupMenuItem(
                value: 'Pior Avaliadas',
                child: Text('Pior Avaliadas'),
              ),
              const PopupMenuItem(
                value: 'Mais Difíceis',
                child: Text('Mais Difíceis'),
              ),
              const PopupMenuItem(
                value: 'Mais Fáceis',
                child: Text('Mais Fáceis'),
              ),
              const PopupMenuItem(
                value: 'Mais Avaliadas',
                child: Text('Mais Avaliadas'),
              ),
            ],
          ),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Terminar sessão',
                  onPressed: () => FirebaseAuth.instance.signOut(),
                );
              } else {
                return TextButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Entrar',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar disciplina...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (valor) {
                setState(() {
                  _termoPesquisa = valor.toLowerCase();
                });
              },
            ),
          ),

          RawScrollbar(
            controller: scrollController2,
            thumbVisibility: true,
            thumbColor: Colors.grey[300],
            thickness: larguraTela > 600 ? 0 : 3.0,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: scrollController2,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        right: 16.0,
                        bottom: larguraTela < 600 ? 4.0 : 0,
                      ),
                      child: FilterChip(
                        label: const Text('Minhas Avaliações'),
                        selected: _mostrarApenasMinhas,
                        selectedColor: Colors.amber[200],
                        checkmarkColor: Colors.black87,
                        onSelected: (selecionado) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Faça login para ver suas avaliações.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setState(() => _mostrarApenasMinhas = selecionado);
                        },
                      ),
                    ),
                    ...['Todas', 'Obrigatória', 'Optativa 1', 'Optativa 2'].map(
                      (categoria) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: 8.0,
                            bottom: larguraTela < 600 ? 4.0 : 0,
                          ),
                          child: ChoiceChip(
                            label: Text(categoria),
                            selected: _filtroCategoria == categoria,
                            onSelected: (selecionado) {
                              if (selecionado) {
                                setState(() => _filtroCategoria = categoria);
                              }
                            },
                            selectedColor: Colors.blue[100],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lista de Disciplinas
          Expanded(
            child: StreamBuilder<List<Materia>>(
              stream: firebaseService.getMateriasStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma disciplina encontrada.'),
                  );
                }

                // 1. Filtrar pela pesquisa
                List<Materia> materiasFiltradas = snapshot.data!.where((
                  materia,
                ) {
                  final condicaoPesquisa = materia.nome.toLowerCase().contains(
                    _termoPesquisa,
                  );
                  final condicaoCategoria =
                      _filtroCategoria == 'Todas' ||
                      materia.categoria == _filtroCategoria;

                  final condicaoMinhasAvaliacoes =
                      !_mostrarApenasMinhas ||
                      _minhasMateriasIds.contains(materia.id);

                  return condicaoPesquisa &&
                      condicaoCategoria &&
                      condicaoMinhasAvaliacoes;
                }).toList();

                // 2. Ordenar consoante o critério escolhido
                materiasFiltradas.sort((a, b) {
                  switch (_criterioOrdenacao) {
                    case 'Melhor Avaliadas':
                      return b.mediaAvaliacao.compareTo(a.mediaAvaliacao);
                    case 'Pior Avaliadas':
                      if (a.votos == 0 && b.votos > 0) return 1;
                      if (b.votos == 0 && a.votos > 0) return -1;
                      return a.mediaAvaliacao.compareTo(b.mediaAvaliacao);
                    case 'Mais Difíceis':
                      return b.mediaDificuldade.compareTo(a.mediaDificuldade);
                    case 'Mais Fáceis':
                      if (a.votos == 0 && b.votos > 0) return 1;
                      if (b.votos == 0 && a.votos > 0) return -1;
                      return a.mediaDificuldade.compareTo(b.mediaDificuldade);
                    case 'Mais Avaliadas':
                      return b.votos.compareTo(a.votos);
                    case 'Nome (A-Z)':
                    default:
                      return a.nome.compareTo(b.nome);
                  }
                });

                if (materiasFiltradas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma disciplina corresponde à pesquisa.'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        'Exibindo ${materiasFiltradas.length} disciplina(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: Expanded(
                        child: RawScrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          thumbColor: Colors.grey[350],
                          thickness: 8.0,
                          radius: const Radius.circular(8),
                          child: ListView.builder(
                            itemCount: materiasFiltradas.length,
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 16.0),
                            itemBuilder: (context, index) {
                              final materia = materiasFiltradas[index];
                              double larguraTela = MediaQuery.of(
                                context,
                              ).size.width;
                              bool jaAvaliou = _minhasMateriasIds.contains(
                                materia.id,
                              );
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              materia.categoria == 'Obrigatória'
                                              ? Colors.blue[50]
                                              : materia.categoria ==
                                                    'Optativa 2'
                                              ? Colors.orange[50]
                                              : Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          materia.categoria,
                                          style: TextStyle(
                                            fontSize: tamanhoSubtitulo,
                                            color:
                                                materia.categoria ==
                                                    'Obrigatória'
                                                ? Colors.blue[800]
                                                : materia.categoria ==
                                                      'Optativa 2'
                                                ? Colors.orange[800]
                                                : Colors.green[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4.0),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              materia.nome,
                                              style: TextStyle(
                                                fontSize: tamanhoTitulo,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (larguraTela < 600) ...[
                                            // Botão de Fórum/Comentários
                                            Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.forum_outlined,
                                                        color: Colors.grey,
                                                      ),
                                                      tooltip:
                                                          'Ver comentários',
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              ListaComentariosDialog(
                                                                materiaId:
                                                                    materia.id,
                                                                nomeMateria:
                                                                    materia
                                                                        .nome,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                    // Botão de Votar
                                                    IconButton(
                                                      icon: Icon(
                                                        jaAvaliou
                                                            ? Icons.how_to_vote
                                                            : Icons
                                                                  .how_to_vote_outlined,
                                                        color: jaAvaliou
                                                            ? Colors.green
                                                            : Colors.blue,
                                                      ),
                                                      tooltip: jaAvaliou
                                                          ? 'Editar avaliação'
                                                          : 'Avaliar disciplina',
                                                      onPressed: () =>
                                                          _verificarEAbrirVotacao(
                                                            context,
                                                            materia,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${materia.votos} votos',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ] else ...[
                                            Text(
                                              '${materia.votos} votos',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),

                                            // Botão de Fórum/Comentários
                                            IconButton(
                                              icon: const Icon(
                                                Icons.forum_outlined,
                                                color: Colors.grey,
                                              ),
                                              tooltip: 'Ver comentários',
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      ListaComentariosDialog(
                                                        materiaId: materia.id,
                                                        nomeMateria:
                                                            materia.nome,
                                                      ),
                                                );
                                              },
                                            ),

                                            // Botão de Votar
                                            IconButton(
                                              icon: Icon(
                                                jaAvaliou
                                                    ? Icons.how_to_vote
                                                    : Icons
                                                          .how_to_vote_outlined,
                                                color: jaAvaliou
                                                    ? Colors.green
                                                    : Colors.blue,
                                              ),
                                              tooltip: jaAvaliou
                                                  ? 'Editar avaliação'
                                                  : 'Avaliar disciplina',
                                              onPressed: () =>
                                                  _verificarEAbrirVotacao(
                                                    context,
                                                    materia,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildRatingInfo(
                                            'Dificuldade',
                                            materia.mediaDificuldade,
                                            Colors.redAccent,
                                          ),
                                          _buildRatingInfo(
                                            'Qualidade',
                                            materia.mediaAvaliacao,
                                            Colors.amber,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingInfo(String label, double rating, Color color) {
    double larguraTela = MediaQuery.of(context).size.width;
    double tamanhoSubtitulo = (larguraTela * 0.015).clamp(14.0, 16.0);
    double tamanhoLegenda = (larguraTela * 0.012).clamp(12.0, 14.0);
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: tamanhoSubtitulo)),
        const SizedBox(height: 4),
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) => Icon(Icons.star, color: color),
          itemCount: 5,
          itemSize: tamanhoSubtitulo + 4,
          direction: Axis.horizontal,
        ),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: tamanhoLegenda,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _verificarEAbrirVotacao(
    BuildContext context,
    Materia materia,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Acesso Restrito'),
          content: const Text(
            'Precisa de iniciar sessão com um e-mail institucional para fazer uma avaliação.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Iniciar Sessão'),
            ),
          ],
        ),
      );
      return;
    }

    await user.reload();
    final utilizadorAtualizado = FirebaseAuth.instance.currentUser!;

    if (!utilizadorAtualizado.emailVerified) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verificação Necessária'),
            content: const Text(
              'Por favor, verifique a sua caixa de correio e clique no link de confirmação.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await utilizadorAtualizado.sendEmailVerification();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('E-mail reenviado!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Reenviar Link'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => VotacaoDialog(materia: materia),
      );

      _carregarMinhasAvaliacoes(utilizadorAtualizado.uid);
    }
  }
}
