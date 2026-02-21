import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController(); // Novo controlador
  final _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validação da confirmação de senha antes de chamar o servidor
    if (!_isLogin && _senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem. Digite novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.login(_emailController.text, _senhaController.text);
        if (mounted) Navigator.pop(context);
      } else {
        await _authService.registrar(
          _emailController.text,
          _senhaController.text,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Conta criada! Enviamos um link de verificação para o seu e-mail.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro ao acessar a conta.';
      switch (e.code) {
        case 'invalid-email':
          mensagemErro = 'O formato do e-mail é inválido.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          mensagemErro = 'E-mail ou senha incorretos.';
          break;
        case 'email-already-in-use':
          mensagemErro = 'Este e-mail já está cadastrado. Faça login.';
          break;
        case 'weak-password':
          mensagemErro = 'A senha é muito fraca. Use pelo menos 6 caracteres.';
          break;
      }
      if (mounted) _mostrarErro(mensagemErro);
    } catch (e) {
      if (mounted) _mostrarErro(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acesso ao Sistema')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Avaliação de Matérias',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail Institucional',
                  hintText: 'nome@estudante.ufscar.br',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),

              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmarSenhaController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
              ] else ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _mostrarDialogRecuperarSenha,
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Entrar' : 'Criar Conta'),
                ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _senhaController.clear();
                    _confirmarSenhaController.clear();
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Não tem conta? Registre-se aqui'
                      : 'Já tem conta? Faça login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogRecuperarSenha() async {
    final TextEditingController emailRecuperacaoController =
        TextEditingController();
    emailRecuperacaoController.text = _emailController.text;

    bool enviando = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Recuperar Senha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Digite o seu e-mail institucional para receber o link de redefinição de senha.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailRecuperacaoController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail Institucional',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                if (!enviando)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                enviando
                    ? const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: CircularProgressIndicator(),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          final email = emailRecuperacaoController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Digite um e-mail válido.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setState(() => enviando = true);

                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: email,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Link enviado! Verifique sua caixa de entrada (e o spam).',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() => enviando = false);
                            String erro = 'Erro ao enviar e-mail.';
                            // Tratamento específico para e-mail não encontrado
                            if (e.code == 'user-not-found') {
                              erro =
                                  'Este e-mail não está cadastrado em nossa base.';
                            } else if (e.code == 'invalid-email') {
                              erro = 'O formato do e-mail é inválido.';
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(erro),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => enviando = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Enviar Link'),
                      ),
              ],
            );
          },
        );
      },
    );
  }
}
