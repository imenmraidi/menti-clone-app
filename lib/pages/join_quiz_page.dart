import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinQuizPage extends StatefulWidget {
  const JoinQuizPage({super.key});

  @override
  State<JoinQuizPage> createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorMessage;

  void joinQuiz() async {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();

    final query = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('code', isEqualTo: code)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz not found')));
      return;
    }

    final quizDoc = query.docs.first;
    final quizId = quizDoc.id;

    // Check if quiz is started
    if (quizDoc['started'] != true) {
      setState(() {
        _errorMessage = 'Waiting for the admin to start the quiz';
      });
      return;
    }

    final playerRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quizId)
        .collection('players')
        .doc();

    await playerRef.set({
      'name': name,
      'joinedAt': Timestamp.now(),
    });

    Navigator.pushReplacementNamed(context, '/playing', arguments: {
      'quizId': quizId,
      'playerId': playerRef.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Your Name'),
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Enter Quiz Code'),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 20),
              Text(_errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16)),
            ],
            ElevatedButton(
              onPressed: joinQuiz,
              child: Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
