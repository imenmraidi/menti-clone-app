import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardWidget extends StatelessWidget {
  final String quizId;
  final int questionIndex;
  final List<String> options;
  
  const LeaderboardWidget({
    super.key,
    required this.quizId,
    required this.questionIndex,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final quizData = snapshot.data!.data() as Map<String, dynamic>;
        final questions = quizData['questions'] as List;
        final currentQuestion = questions[questionIndex];
        final answers = currentQuestion['answers'] ?? {};
        
        // Calculate answer counts
        Map<String, int> answerCounts = {};
        for (var option in options) {
          answerCounts[option] = 0;
        }
        
        answers.forEach((playerId, answerIndex) {
          if (answerIndex < options.length) {
            final option = options[answerIndex];
            answerCounts[option] = (answerCounts[option] ?? 0) + 1;
          }
        });

        // Sort options by count (descending)
        final sortedOptions = options.toList()
          ..sort((a, b) => (answerCounts[b] ?? 0).compareTo(answerCounts[a] ?? 0));

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              ...sortedOptions.map((option) {
                final count = answerCounts[option] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: LinearProgressIndicator(
                          value: count / (answers.length == 0 ? 1 : answers.length),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getColorForOption(options.indexOf(option)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Move to next question or end quiz
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorForOption(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}