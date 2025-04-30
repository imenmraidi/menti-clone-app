class Question {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final int durationSeconds;

  Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.durationSeconds,
  });

  // To convert Question to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'durationSeconds': durationSeconds,
    };
  }

  // To create a Question from Firestore data
  factory Question.fromMap(String id, Map<String, dynamic> map) {
    return Question(
      id: id,
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options']),
      correctOptionIndex: map['correctOptionIndex'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 30,
    );
  }
}
