import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:menti_clone/constants/style_constants.dart';
import 'package:flutter/services.dart';
import 'package:menti_clone/pages/lobby_page.dart';

class MyQuizzesPage extends StatefulWidget {
  const MyQuizzesPage({Key? key}) : super(key: key);

  @override
  _MyQuizzesPageState createState() => _MyQuizzesPageState();
}

class _MyQuizzesPageState extends State<MyQuizzesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('You need to be logged in to view your quizzes');
        return;
      }

      print('Fetching quizzes for user ID: ${currentUser.uid}'); // Debug line

      final querySnapshot =
          await _firestore
              .collection('quizzes')
              .where('createdBy', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .get();

      print('Found ${querySnapshot.docs.length} quizzes'); // Debug line

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _quizzes = [];
          _isLoading = false;
        });
        return;
      }

      final quizzes =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            // Format date
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            final formattedDate = DateFormat('MMM d, yyyy').format(createdAt);

            return {
              'id': doc.id,
              'code': data['code'] ?? doc.id,
              'title': data['title'] ?? 'Untitled Quiz',
              'createdAt': formattedDate,
              'questionCount': (data['questions'] as List?)?.length ?? 0,
              'lastPresented':
                  data['lastPresented'] != null
                      ? DateFormat(
                        'MMM d, yyyy',
                      ).format((data['lastPresented'] as Timestamp).toDate())
                      : 'Never presented',
            };
          }).toList();

      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Failed to load quizzes: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _presentQuiz(String quizId, String code) async {
    HapticFeedback.mediumImpact();

    // Show loading dialog
    _showLoadingDialog('Setting up your quiz...');

    try {
      // Reset the quiz state for a new presentation
      await _firestore.collection('quizzes').doc(quizId).update({
        'started': false,
        'currentQuestionIndex': 0,
        'questionStartTime': null,
        'lastPresented': Timestamp.now(),
      });

      // Pop loading dialog
      Navigator.pop(context);

      // Navigate to lobby page
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  LobbyPage(quizId: quizId, code: code),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      // Pop loading dialog and show error
      Navigator.pop(context);
      _showErrorSnackbar('Failed to present quiz: ${e.toString()}');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
                SizedBox(width: 24),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteQuiz(String quizId) async {
    // Show confirmation dialog
    bool confirmDelete =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete Quiz?'),
                content: Text('This action cannot be undone.'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                    ),
                    child: Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmDelete) {
      HapticFeedback.mediumImpact();

      try {
        await _firestore.collection('quizzes').doc(quizId).delete();

        // Remove from local list
        setState(() {
          _quizzes.removeWhere((quiz) => quiz['id'] == quizId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        _showErrorSnackbar('Failed to delete quiz: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Quizzes',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryBlue),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadQuizzes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.backgroundLightBlue.withOpacity(0.3),
            ],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                )
                : _quizzes.isEmpty
                ? _buildEmptyState()
                : _buildQuizzesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: AppColors.primaryBlue.withOpacity(0.5),
          ),
          SizedBox(height: 24),
          Text(
            'No Quizzes Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'You haven\'t created any quizzes yet. Start by creating your first quiz!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.add),
            label: Text('Create Quiz'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList() {
    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return _buildQuizCard(quiz);
        },
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: AppColors.primaryBlue.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and question count
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz['title'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${quiz['questionCount']} ${quiz['questionCount'] == 1 ? 'Question' : 'Questions'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tag, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          quiz['code'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quiz details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date info
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Created: ${quiz['createdAt']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.history, size: 16, color: AppColors.textLight),
                      SizedBox(width: 8),
                      Text(
                        'Last presented: ${quiz['lastPresented']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Delete button
                      OutlinedButton.icon(
                        onPressed: () => _deleteQuiz(quiz['id']),
                        icon: Icon(Icons.delete_outline, size: 18),
                        label: Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: BorderSide(color: AppColors.errorRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),

                      // Present button
                      ElevatedButton.icon(
                        onPressed: () => _presentQuiz(quiz['id'], quiz['code']),
                        icon: Icon(Icons.present_to_all, size: 18),
                        label: Text('Present Quiz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
