// lib/presentation/view_models/auth_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:secure_notes_app/data/repositories/auth_repository.dart';
import 'package:secure_notes_app/data/services/notes_service.dart';
import 'package:secure_notes_app/domain/models/user_model.dart';
import 'package:secure_notes_app/providers/providers.dart';

// Define AuthState class first
class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  factory AuthState.initial() {
    return const AuthState(
      user: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
    );
  }

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Then define the ViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final NotesService _notesService;

  AuthViewModel(this._authRepository, this._notesService)
      : super(AuthState.initial()) {
    // Initialize with current user
    _checkCurrentUser();
  }

  // Check current user and set up listener
  void _checkCurrentUser() {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      _notesService.setCurrentUser(currentUser.id);
      state = state.copyWith(
        user: currentUser,
        isAuthenticated: true,
      );
    }
    
    // Listen to auth state changes
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _notesService.setCurrentUser(user.id);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        _notesService.clearCurrentUser();
        state = AuthState.initial();
      }
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Manually update state after successful sign up
      _notesService.setCurrentUser(user.id);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Manually update state after successful sign in
      _notesService.setCurrentUser(user.id);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.signOut();
      
      // Manually update state after sign out
      _notesService.clearCurrentUser();
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }
}

// Provider definition
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(
    ref.read(authRepositoryProvider),
    ref.read(notesServiceProvider),
  ),
);