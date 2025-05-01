import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../constants/style_constants.dart';

class AdminQuizPage extends StatefulWidget {
  final String quizId;

  const AdminQuizPage({required this.quizId});

  @override
  _AdminQuizPageState createState() => _AdminQuizPageState();
}

class _AdminQuizPageState extends State<AdminQuizPage>
    with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  Map<int, int> optionCounts = {}; // Changed to int keys for option indexes
  Map<int, int> previousOptionCounts =
      {}; // Track previous counts to detect changes
  List<Map<String, dynamic>> questions = [];
  bool isFinished = false;
  StreamSubscription? _quizSubscription;
  StreamSubscription? _playersSubscription;
  bool isLoading = true;
  Timer? _refreshTimer;
  bool showLeaderboard = true;
  int totalResponses = 0;
  int previousTotalResponses = 0; // Track previous response count

  // Animation controllers
  late AnimationController _pageTransitionController;
  late AnimationController _barAnimationController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _barAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start quiz with active timer for first question
    _startQuiz();

    // Listen for quiz updates
    _quizSubscription = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .snapshots()
        .listen((doc) {
          final data = doc.data();
          if (data == null) return;

          setState(() {
            questions = List<Map<String, dynamic>>.from(data['questions']);
            currentQuestionIndex = data['currentQuestionIndex'] ?? 0;
            isFinished = currentQuestionIndex >= questions.length;
            isLoading = false;
          });

          // Update leaderboard data
          updateLeaderboard();
        });
  }

  void _startQuiz() async {
    final quizRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId);

    // Set initial state for quiz
    await quizRef.update({
      'started': true,
      'currentQuestionIndex': 0,
      'questionStartTime': FieldValue.serverTimestamp(),
    });

    // Start periodic refresh of leaderboard data
    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!isFinished) updateLeaderboard();
    });
  }

  void updateLeaderboard() async {
    if (isFinished || currentQuestionIndex >= questions.length) return;

    final playersSnapshot =
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .collection('players')
            .get();

    Map<int, int> counts = {};
    int responseCount = 0;

    for (var playerDoc in playersSnapshot.docs) {
      final answerDoc =
          await FirebaseFirestore.instance
              .collection('quizzes')
              .doc(widget.quizId)
              .collection('players')
              .doc(playerDoc.id)
              .collection('answers')
              .doc('question_$currentQuestionIndex')
              .get();

      if (answerDoc.exists && answerDoc.data()?['selected'] != null) {
        final selected = answerDoc.data()!['selected'];
        counts[selected] = (counts[selected] ?? 0) + 1;
        responseCount++;
      }
    }

    if (mounted) {
      // Check if there are new responses
      bool hasNewResponses = responseCount > previousTotalResponses;

      // Check if the distribution has changed
      bool distributionChanged = false;
      if (counts.length != previousOptionCounts.length) {
        distributionChanged = true;
      } else {
        for (var entry in counts.entries) {
          if (previousOptionCounts[entry.key] != entry.value) {
            distributionChanged = true;
            break;
          }
        }
      }

      setState(() {
        optionCounts = counts;
        totalResponses = responseCount;

        // Only animate bars when new responses are submitted
        if (hasNewResponses || distributionChanged) {
          _barAnimationController.reset();
          _barAnimationController.forward();

          // Update previous values for next comparison
          previousTotalResponses = responseCount;
          previousOptionCounts = Map<int, int>.from(counts);
        }
      });
    }
  }

  void nextQuestion() async {
    if (isFinished) return;

    // Animate page transition
    _pageTransitionController.forward().then((_) {
      setState(() {
        showLeaderboard = true;
        currentQuestionIndex++;
        isFinished = currentQuestionIndex >= questions.length;
        // Clear leaderboard data for the next question
        optionCounts = {};
        previousOptionCounts = {};
        totalResponses = 0;
        previousTotalResponses = 0;
      });

      _pageTransitionController.reset();

      if (!isFinished) {
        _updateFirestoreQuestionIndex();
      } else {
        _markQuizAsFinished();
      }
    });
  }

  void _updateFirestoreQuestionIndex() async {
    final quizRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId);

    await quizRef.update({
      'currentQuestionIndex': currentQuestionIndex,
      'questionStartTime': FieldValue.serverTimestamp(),
    });
  }

  void _markQuizAsFinished() async {
    final quizRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId);

    await quizRef.update({
      'currentQuestionIndex': currentQuestionIndex,
      'finished': true,
    });
  }

  List<Widget> _buildLeaderboardView() {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return [
        Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
        ),
      ];
    }

    final question = questions[currentQuestionIndex];
    final options = question['options'] as List;

    // Calculate total responses for percentage
    int maxCount = 0;
    for (int i = 0; i < options.length; i++) {
      final count = optionCounts[i] ?? 0;
      if (count > maxCount) maxCount = count;
    }

    List<Widget> leaderboardWidgets = [];

    for (int i = 0; i < options.length; i++) {
      final count = optionCounts[i] ?? 0;
      final isCorrect = question['correctAnswer'] == i;
      final percentage =
          totalResponses > 0 ? (count / totalResponses * 100).toInt() : 0;

      // Calculate bar width as percentage
      final barPercentage = maxCount > 0 ? count / maxCount : 0;

      leaderboardWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isCorrect
                              ? AppColors.backgroundLightBlue
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          isCorrect
                              ? Border.all(
                                color: AppColors.primaryBlue,
                                width: 2,
                              )
                              : null,
                    ),
                    child: Text(
                      String.fromCharCode(65 + i), // A, B, C, D, etc.
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isCorrect
                                ? AppColors.primaryBlue
                                : AppColors.textLight,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      options[i].toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isCorrect ? FontWeight.bold : FontWeight.normal,
                        color:
                            isCorrect
                                ? AppColors.primaryBlue
                                : AppColors.textDark,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isCorrect
                              ? AppColors.primaryBlue
                              : AppColors.textDark,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 48,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              // Animated bar
              Stack(
                children: [
                  // Background track
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Animated Progress Bar
                  AnimatedBuilder(
                    animation: _barAnimationController,
                    builder: (context, child) {
                      return Container(
                        height: 12,
                        width:
                            MediaQuery.of(context).size.width *
                            0.8 * // Adjust for padding
                            barPercentage *
                            _barAnimationController.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isCorrect
                                    ? [
                                      AppColors.primaryBlue.withOpacity(0.7),
                                      AppColors.primaryBlue,
                                    ]
                                    : [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow:
                              isCorrect
                                  ? [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return leaderboardWidgets;
  }

  @override
  void dispose() {
    _quizSubscription?.cancel();
    _playersSubscription?.cancel();
    _refreshTimer?.cancel();
    _pageTransitionController.dispose();
    _barAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: Text('Admin Panel')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              SizedBox(height: 24),
              Text(
                'Loading quiz data...',
                style: TextStyle(color: AppColors.textLight, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (isFinished) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: Text('Quiz Finished')),
        body: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(32),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    size: 64,
                    color: AppColors.primaryBlue,
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  SizedBox(height: 24),
                  Text(
                    'Quiz Completed!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All players have been notified that the quiz is finished.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.textLight),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst),
                      icon: Icon(Icons.home_rounded),
                      label: Text(
                        'Return to Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fade(duration: 400.ms).scale(begin: Offset(0.9, 0.9)),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: Text('Admin Panel')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.errorRed.withOpacity(0.7),
              ),
              SizedBox(height: 24),
              Text(
                'No questions available',
                style: TextStyle(fontSize: 18, color: AppColors.textDark),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];

    return AnimatedBuilder(
      animation: _pageTransitionController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(
              'Admin Panel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded),
                onPressed: updateLeaderboard,
                tooltip: 'Refresh Results',
              ),
            ],
          ),
          body: FadeTransition(
            opacity: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(_pageTransitionController),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question progress header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLightBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Question ${currentQuestionIndex + 1}/${questions.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      Spacer(),
                      // Response counter
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '$totalResponses response${totalResponses != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Question card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question:',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            question['question'] ?? 'No Question Text',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Leaderboard header
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),

                  Divider(height: 32, color: AppColors.dividerColor),

                  // Results view - scrollable if many options
                  Expanded(
                    child:
                        totalResponses > 0
                            ? ListView(children: _buildLeaderboardView())
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Waiting for responses...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),

                  SizedBox(height: 20),

                  // Button row with counter
                  Row(
                    children: [
                      // Question counter
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQuestionIndex < questions.length - 1
                                ? 'Next: Question ${currentQuestionIndex + 2}'
                                : 'Final Question',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            currentQuestionIndex < questions.length - 1
                                ? (questions[currentQuestionIndex +
                                                1]['question'] ??
                                            'Next Question')
                                        .toString()
                                        .substring(
                                          0,
                                          (questions[currentQuestionIndex +
                                                              1]['question'] ??
                                                          'Next Question')
                                                      .toString()
                                                      .length >
                                                  30
                                              ? 30
                                              : (questions[currentQuestionIndex +
                                                          1]['question'] ??
                                                      'Next Question')
                                                  .toString()
                                                  .length,
                                        ) +
                                    ((questions[currentQuestionIndex +
                                                        1]['question'] ??
                                                    'Next Question')
                                                .toString()
                                                .length >
                                            30
                                        ? '...'
                                        : '')
                                : 'End of quiz',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: nextQuestion,
                          icon: Icon(
                            currentQuestionIndex < questions.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_circle_rounded,
                          ),
                          label: Text(
                            currentQuestionIndex < questions.length - 1
                                ? 'Next Question'
                                : 'Finish Quiz',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                currentQuestionIndex < questions.length - 1
                                    ? AppColors.primaryBlue
                                    : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
