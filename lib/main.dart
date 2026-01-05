// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_notes_app/firebase_options.dart';
import 'package:secure_notes_app/presentation/screens/auth_screen.dart';
import 'package:secure_notes_app/presentation/screens/notes_screen.dart';
import 'package:secure_notes_app/presentation/view_models/auth_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch AuthViewModel instead of the direct Firebase stream
    final authState = ref.watch(authViewModelProvider);
    
    return MaterialApp(
      title: 'Secure Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    // Show loading while checking auth state
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If authenticated, show NotesScreen
    if (authState.isAuthenticated) {
      return const NotesScreen();
    }

    // Otherwise, show AuthScreen
    return const AuthScreen();
  }
}