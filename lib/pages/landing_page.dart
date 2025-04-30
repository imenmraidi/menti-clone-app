import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'join_quiz_page.dart'; // You'll create this later

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Menti Clone')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              },
              child: const Text('Login to Create a Quiz'),
            ),
            const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const JoinQuizPage()),
            //     );
            //   },
            //   child: const Text('Join Quiz with Code'),
            // ),
          ],
        ),
      ),
    );
  }
}
