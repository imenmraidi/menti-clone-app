import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerWaitingPage extends StatelessWidget {
  final String quizId;

  const PlayerWaitingPage({required this.quizId});

  @override
  Widget build(BuildContext context) {
    final quizDoc = FirebaseFirestore.instance.collection('quizzes').doc(quizId);

    return Scaffold(
      appBar: AppBar(title: Text('Waiting for Quiz to Start')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: quizDoc.snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final quizData = snapshot.data!.data() as Map<String, dynamic>;
          if (quizData['started'] == true) {
            // Navigate to quiz question screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/play_quiz', arguments: quizId);
            });
          }

          return Center(child: Text('Waiting for host to start the quiz...'));
        },
      ),
    );
  }
}
