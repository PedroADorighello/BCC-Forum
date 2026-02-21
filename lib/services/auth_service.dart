import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> registrar(String email, String password) async {
    final dominio = email.trim().toLowerCase();

    if (!dominio.endsWith('@estudante.ufscar.br') &&
        !dominio.endsWith('@ufscar.br')) {
      throw Exception(
        'Apenas e-mails institucionais da UFSCar são permitidos.',
      );
    }

    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await cred.user?.sendEmailVerification();

    return cred;
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
