import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:menti_clone/models/quiz.dart';
import 'package:menti_clone/models/question.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection Reference for Quizzes
  final String collectionName = 'quizzes';

  // Create or Update a Quiz
  Future<void> createQuiz(Quiz quiz) async {
    try {
      final quizRef = _db.collection(collectionName).doc(quiz.id);

      // Save the quiz data
      await quizRef.set(quiz.toMap());
    } catch (e) {
      print('Error creating quiz: $e');
    }
  }

  // Retrieve a Quiz by ID
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final quizRef = _db.collection(collectionName).doc(quizId);
      final docSnapshot = await quizRef.get();

      if (docSnapshot.exists) {
        return Quiz.fromMap(
          docSnapshot.id,
          docSnapshot.data() as Map<String, dynamic>,
        );
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving quiz: $e');
      return null;
    }
  }

  // Retrieve all quizzes (useful for showing all available quizzes)
  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final quizQuerySnapshot = await _db.collection(collectionName).get();
      return quizQuerySnapshot.docs
          .map(
            (doc) => Quiz.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error retrieving all quizzes: $e');
      return [];
    }
  }
}
