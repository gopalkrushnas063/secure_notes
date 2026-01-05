// Create a new file: lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_notes_app/domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';



final authStateProvider = StreamProvider<UserModel?>((ref) {  
  
  final firebaseAuth = FirebaseAuth.instance;
  
  return firebaseAuth.authStateChanges().map((user) {
    if (user != null && user.email != null) {
      return UserModel(id: user.uid, email: user.email!);
    }
    return null;
  });
});