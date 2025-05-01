import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:menti_clone/models/quiz.dart';
import 'package:menti_clone/models/question.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection Reference for Quizzes
  final String collectionName = 'quizzes';

  // Create or Update a Quiz
  Future<void> createQuiz(Quiz quiz) async {
    try {
      final quizRef = _db.collection(collectionName).doc(quiz.id);

      // Add the current user's ID as the creator
      final Map<String, dynamic> quizData = quiz.toMap();
      quizData['createdBy'] = _auth.currentUser?.uid;

      // Save the quiz data
      await quizRef.set(quizData);
    } catch (e) {
      print('Error creating quiz: $e');
      throw e;
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
          .map((doc) => Quiz.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error retrieving all quizzes: $e');
      return [];
    }
  }

  // Retrieve quizzes created by the current user
  Future<List<Quiz>> getUserQuizzes() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return [];
      }

      final quizQuerySnapshot =
          await _db
              .collection(collectionName)
              .where('createdBy', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .get();

      return quizQuerySnapshot.docs
          .map((doc) => Quiz.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error retrieving user quizzes: $e');
      return [];
    }
  }

  // Delete a quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _db.collection(collectionName).doc(quizId).delete();
    } catch (e) {
      print('Error deleting quiz: $e');
      throw e;
    }
  }

  // Update quiz presentation status
  Future<void> updateQuizPresentationStatus(
    String quizId, {
    bool started = false,
    int currentQuestionIndex = 0,
  }) async {
    try {
      await _db.collection(collectionName).doc(quizId).update({
        'started': started,
        'currentQuestionIndex': currentQuestionIndex,
        'questionStartTime': null,
        'lastPresented': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating quiz presentation status: $e');
      throw e;
    }
  }
}
