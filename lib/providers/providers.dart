// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:secure_notes_app/data/repositories/auth_repository.dart';
import 'package:secure_notes_app/data/repositories/notes_repository.dart';
import 'package:secure_notes_app/data/services/notes_service.dart';
import 'package:secure_notes_app/domain/models/user_model.dart';
import 'package:secure_notes_app/presentation/view_models/auth_view_model.dart';
import 'package:secure_notes_app/presentation/view_models/notes_view_model.dart';

// Providers for repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

// Provider for service
final notesServiceProvider = Provider<NotesService>((ref) {
  return NotesService(ref.read(notesRepositoryProvider));
});

// ViewModel providers
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    ref.watch(authRepositoryProvider),  // Use watch instead of read
    ref.watch(notesServiceProvider),    // Use watch instead of read
  );
});

final notesViewModelProvider = StateNotifierProvider<NotesViewModel, NotesState>((ref) {
  return NotesViewModel(ref.watch(notesServiceProvider));  // Use watch instead of read
});

final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});