import 'package:flutter/material.dart';

class AuthToggleButton extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onPressed;

  const AuthToggleButton({
    super.key,
    required this.isLogin,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: RichText(
          text: TextSpan(
            text: isLogin
                ? "Don't have an account? "
                : "Already have an account? ",
            style: TextStyle(color: Colors.grey.shade600),
            children: [
              TextSpan(
                text: isLogin ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}