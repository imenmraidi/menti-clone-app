import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  final String quizId;

  const QuizPage({required this.quizId});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  bool _quizEnded = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  void _fetchQuestions() async {
    final quizRef = FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId);
    final quizSnapshot = await quizRef.get();
    final quizData = quizSnapshot.data() as Map<String, dynamic>;
    setState(() {
      _questions = List<Map<String, dynamic>>.from(quizData['questions']);
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _quizEnded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_quizEnded) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Ended')),
        body: Center(child: Text('The quiz has ended!')),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Quiz - ${currentQuestion['question']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(currentQuestion['question']),
            ...List.generate(4, (i) {
              return ElevatedButton(
                onPressed: () {},
                child: Text(currentQuestion['options'][i]),
              );
            }),
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text('Next Question'),
            ),
          ],
        ),
      ),
    );
  }
}
