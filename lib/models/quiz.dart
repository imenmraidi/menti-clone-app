import 'question.dart';

class Quiz {
  final String id;
  final String title;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
  });

  // To convert Quiz to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  // To create a Quiz from Firestore data
  factory Quiz.fromMap(String id, Map<String, dynamic> map) {
    return Quiz(
      id: id,
      title: map['title'] ?? '',
      questions: List<Question>.from(
        map['questions']?.map((item) => Question.fromMap(id, item)) ?? [],
      ),
    );
  }
}
