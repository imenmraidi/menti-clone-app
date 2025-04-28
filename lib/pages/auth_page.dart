import 'package:flutter/material.dart';
import 'package:menti_clone/pages/home_page.dart';
import 'package:menti_clone/widgets/auth_form.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  void _handleAuthSuccess(BuildContext context) {
    // After successful login/signup
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Signup')),
      body: AuthForm(onAuthSuccess: () => _handleAuthSuccess(context)),
    );
  }
}
