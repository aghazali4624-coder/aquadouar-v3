// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User?        get currentUser       => _auth.currentUser;
  static bool         get isLoggedIn        => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());

  static Future<void> signOut() => _auth.signOut();

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
