import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class LobbyPage extends StatelessWidget {
  final String quizId;
  final String code;

  const LobbyPage({required this.quizId, required this.code});

  void startQuiz() async {
    await FirebaseFirestore.instance.collection('quizzes').doc(quizId).update({
      'started': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final playersRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quizId)
        .collection('players');

    return Scaffold(
      appBar: AppBar(title: Text('Waiting Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Share this code:', style: TextStyle(fontSize: 20)),
            SelectableText(
              code,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              'URL: http://:8080/#/join',
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),
            Text('Players Joined:', style: TextStyle(fontSize: 20)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: playersRef.snapshots(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder:
                        (_, i) => ListTile(title: Text(docs[i]['name'])),
                  );
                },
              ),
            ),
            ElevatedButton(onPressed: startQuiz, child: Text('Start Quiz')),
          ],
        ),
      ),
    );
  }
}
