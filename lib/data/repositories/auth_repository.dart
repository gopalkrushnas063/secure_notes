// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secure_notes_app/domain/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user != null) {
        return UserModel(id: user.uid, email: user.email!);
      }
      return null;
    });
  }

  // Update the error handling in auth_repository.dart
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email!,
      );
    } catch (e) {
      // Properly handle FirebaseAuthException
      if (e is FirebaseAuthException) {
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
      throw FirebaseAuthException(code: 'unknown-error', message: e.toString());
    }
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email!,
      );
    } catch (e) {
      // Properly handle FirebaseAuthException
      if (e is FirebaseAuthException) {
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
      throw FirebaseAuthException(code: 'unknown-error', message: e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      return UserModel(id: user.uid, email: user.email!);
    }
    return null;
  }
}
