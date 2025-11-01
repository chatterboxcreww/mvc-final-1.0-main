// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\auth\screens\sign_in_screen.dart

// lib/features/auth/screens/sign_in_screen.dart

import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  final VoidCallback onSignIn;

  const SignInScreen({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: onSignIn,
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}

