import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'lobby_page.dart'; // Add this import

class CreateQuizPage extends StatefulWidget {
  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _quizTitleController = TextEditingController();
  List<Map<String, dynamic>> _questions = [];

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': '',
        'options': ['', '', '', ''],
        'correctAnswer': 0,
        'timeLimit': 30,
      });
    });
  }

  Future<void> _saveQuiz() async {
    final title = _quizTitleController.text.trim();
    if (title.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz title and questions required')),
      );
      return;
    }

    final code = _generateQuizCode();

    final quizDoc = FirebaseFirestore.instance.collection('quizzes').doc(code);

    await quizDoc.set({
      'title': title,
      'code': code,
      'createdAt': Timestamp.now(),
      'started': false,
      'questions': _questions,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LobbyPage(quizId: code, code: code)),
    );
  }

  String _generateQuizCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    return List.generate(
      6,
      (i) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _quizTitleController,
              decoration: InputDecoration(labelText: 'Quiz Title'),
            ),
            const SizedBox(height: 16),
            ..._questions.asMap().entries.map((entry) {
              int index = entry.key;
              var q = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Question ${index + 1}',
                        ),
                        onChanged: (val) => q['question'] = val,
                      ),
                      ...List.generate(4, (i) {
                        return TextField(
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                          ),
                          onChanged: (val) => q['options'][i] = val,
                        );
                      }),
                      DropdownButton<int>(
                        value: q['correctAnswer'],
                        onChanged:
                            (val) => setState(() {
                              q['correctAnswer'] = val!;
                            }),
                        items: List.generate(
                          4,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text('Correct Answer: Option ${i + 1}'),
                          ),
                        ),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Time Limit (seconds)',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (val) => q['timeLimit'] = int.tryParse(val) ?? 30,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addQuestion,
              child: Text('Add Question'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _saveQuiz, child: Text('Save & Present')),
          ],
        ),
      ),
    );
  }
}
