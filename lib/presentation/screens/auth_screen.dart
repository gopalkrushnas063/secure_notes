// lib/presentation/screens/auth_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_notes_app/presentation/screens/notes_screen.dart';
import 'package:secure_notes_app/presentation/widgets/auth/auth_button.dart';
import 'package:secure_notes_app/presentation/widgets/auth/auth_container.dart';
import 'package:secure_notes_app/presentation/widgets/auth/auth_form.dart';
import 'package:secure_notes_app/presentation/widgets/auth/auth_header.dart';
import 'package:secure_notes_app/presentation/widgets/auth/auth_logo.dart';
import 'package:secure_notes_app/presentation/widgets/auth/auth_toggle_button.dart';
import 'package:secure_notes_app/providers/providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
    });
  }

  void _setupAuthListener() {
    final authStream = ref.read(authRepositoryProvider).authStateChanges;
    authStream.listen((user) {
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NotesScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          await ref
              .read(authRepositoryProvider)
              .signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );
        } else {
          await ref
              .read(authRepositoryProvider)
              .signUpWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );
        }
      } catch (e) {
        final error = e as FirebaseAuthException;
        String errorMessage = _getErrorMessage(error.code);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'An error occurred. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthContainer(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const AuthLogo(),
                const SizedBox(height: 40),
                AuthHeader(isLogin: _isLogin),
                const SizedBox(height: 40),
                AuthForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isLogin: _isLogin,
                  obscurePassword: _obscurePassword,
                  onTogglePasswordVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 30),
                AuthButton(
                  isLogin: _isLogin,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                AuthToggleButton(
                  isLogin: _isLogin,
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _emailController.clear();
                      _passwordController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}