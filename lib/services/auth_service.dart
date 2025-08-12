import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Вход через email и пароль
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Регистрация нового пользователя
  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Вход через Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      if (kIsWeb) {
        return await _auth.signInWithPopup(googleProvider);
      }
      return await _auth.signInWithProvider(googleProvider);
    } catch (e) {
      print('Ошибка при входе через Google: $e');
      return null;
    }
  }

  // Выход из аккаунта
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
