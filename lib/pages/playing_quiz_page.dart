import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../constants/style_constants.dart'; // Import the style constants

class PlayingQuizPage extends StatefulWidget {
  final String quizId;
  final String playerId;

  const PlayingQuizPage({required this.quizId, required this.playerId});

  @override
  _PlayingQuizPageState createState() => _PlayingQuizPageState();
}

class _PlayingQuizPageState extends State<PlayingQuizPage>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int? selectedOptionIndex;
  bool answerSubmitted = false;
  bool showResult = false;
  List<Map<String, dynamic>> questions = [];
  int timeRemaining = 0;
  Timer? countdownTimer;
  bool isFinished = false;
  bool isLoading = true;
  StreamSubscription? _quizSubscription;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Avatar generation
  Color getAvatarColor() {
    final playerIdValue = widget.playerId.hashCode;
    final colorIndex = playerIdValue % AppColors.avatarColors.length;
    return AppColors.avatarColors[colorIndex];
  }

  String getPlayerInitial() {
    return widget.playerId.isNotEmpty ? widget.playerId[0].toUpperCase() : '?';
  }

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _quizSubscription = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .snapshots()
        .listen((doc) {
          if (!mounted) return;

          final data = doc.data();
          if (data == null) return;

          final loadedQuestions = List<Map<String, dynamic>>.from(
            data['questions'],
          );
          final index = data['currentQuestionIndex'] ?? 0;
          final Timestamp? startTimestamp = data['questionStartTime'];
          final bool quizFinished =
              data['finished'] == true || index >= loadedQuestions.length;

          setState(() {
            questions = loadedQuestions;
            currentQuestionIndex = index;
            isFinished = quizFinished;
            isLoading = false;
          });

          if (isFinished) {
            countdownTimer?.cancel();
            return;
          }

          if (currentQuestionIndex < questions.length &&
              startTimestamp != null) {
            setState(() {
              selectedOptionIndex = null;
              answerSubmitted = false;
              showResult = false;
            });
            startCountdown(startTimestamp.toDate());

            // Trigger animation for question transition
            _animationController.reset();
            _animationController.forward();
          }
        });
  }

  void startCountdown(DateTime startTime) {
    countdownTimer?.cancel();

    if (currentQuestionIndex >= questions.length) return;

    final question = questions[currentQuestionIndex];
    final limit = question['timeLimit'] ?? 30;

    final now = DateTime.now();
    final elapsed = now.difference(startTime).inSeconds;
    final initialTimeRemaining = (limit - elapsed).clamp(0, limit);

    setState(() {
      timeRemaining = initialTimeRemaining;
    });

    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        timeRemaining = timeRemaining > 0 ? timeRemaining - 1 : 0;
      });

      if (timeRemaining <= 0) {
        timer.cancel();
        // Only submit if player answered
        if (selectedOptionIndex != null && !answerSubmitted) {
          submitAnswer(selectedOptionIndex!);
        }
        setState(() {
          showResult = true;
        });
      }
    });
  }

  void submitAnswer(int optionIndex) {
    if (answerSubmitted || currentQuestionIndex >= questions.length) return;

    // Haptic feedback (vibration)
    HapticFeedback.mediumImpact();

    setState(() {
      selectedOptionIndex = optionIndex;
      answerSubmitted = true;
    });

    FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('players')
        .doc(widget.playerId)
        .collection('answers')
        .doc('question_$currentQuestionIndex')
        .set({
          'selected': optionIndex,
          'correct': questions[currentQuestionIndex]['correctAnswer'],
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Color getOptionColor(int optionIndex) {
    if (showResult && selectedOptionIndex != null) {
      int correctIndex = questions[currentQuestionIndex]['correctAnswer'];
      if (optionIndex == correctIndex) return AppColors.backgroundLightBlue;
      if (optionIndex == selectedOptionIndex)
        return AppColors.backgroundLightRed;
    }

    if (selectedOptionIndex == optionIndex) {
      return AppColors.backgroundLightBlue;
    }

    return Colors.white;
  }

  Color getOptionBorderColor(int optionIndex) {
    if (showResult && selectedOptionIndex != null) {
      int correctIndex = questions[currentQuestionIndex]['correctAnswer'];
      if (optionIndex == correctIndex) return AppColors.primaryBlue;
      if (optionIndex == selectedOptionIndex) return AppColors.errorRed;
    }

    if (selectedOptionIndex == optionIndex) {
      return AppColors.primaryBlue;
    }

    return Colors.grey.shade300;
  }

  Widget? getOptionIcon(int index) {
    if (!showResult || selectedOptionIndex == null) return null;

    int correctIndex = questions[currentQuestionIndex]['correctAnswer'];

    if (index == correctIndex) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: AppColors.primaryBlue),
      );
    } else if (selectedOptionIndex == index) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close, color: AppColors.errorRed),
      );
    }

    return null;
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _quizSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text('Quiz', style: TextStyle(color: AppColors.primaryBlue)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Loading quiz...',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isFinished || currentQuestionIndex >= questions.length) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(
            'Quiz Complete',
            style: TextStyle(color: AppColors.primaryBlue),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Card(
            margin: EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.celebration,
                      size: 40,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Thanks for playing! 🎉',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'The quiz has ended.',
                    style: TextStyle(fontSize: 16, color: AppColors.textLight),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Return to Home',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];
    final limit = question['timeLimit'] ?? 30;
    final progress = (timeRemaining / limit).clamp(0.0, 1.0);
    final options = question['options'] as List;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: getAvatarColor(),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  getPlayerInitial(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Playing Quiz',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.quiz, color: AppColors.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                'Question ${currentQuestionIndex + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  timeRemaining < 10
                                      ? AppColors.backgroundLightRed
                                      : AppColors.backgroundLightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color:
                                      timeRemaining < 10
                                          ? AppColors.errorRed
                                          : AppColors.primaryBlue,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '$timeRemaining s',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        timeRemaining < 10
                                            ? AppColors.errorRed
                                            : AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            timeRemaining < 10
                                ? AppColors.errorRed
                                : AppColors.primaryBlue,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      SizedBox(height: 20),
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

                SizedBox(height: 24),

                // Status message
                if (!showResult && selectedOptionIndex != null)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Answer locked. Waiting for results...",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showResult)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Correct answer revealed!",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                (answerSubmitted || selectedOptionIndex != null)
                                    ? null
                                    : () => submitAnswer(index),
                            borderRadius: BorderRadius.circular(16),
                            splashColor: AppColors.backgroundLightBlue,
                            child: Ink(
                              decoration: BoxDecoration(
                                color: getOptionColor(index),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: getOptionBorderColor(index),
                                  width: selectedOptionIndex == index ? 2 : 1,
                                ),
                                boxShadow:
                                    selectedOptionIndex == index
                                        ? [
                                          BoxShadow(
                                            color: AppColors.primaryBlue
                                                .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            selectedOptionIndex == index
                                                ? AppColors.primaryBlue
                                                : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              selectedOptionIndex == index
                                                  ? AppColors.primaryBlue
                                                  : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${String.fromCharCode(65 + index)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color:
                                                selectedOptionIndex == index
                                                    ? Colors.white
                                                    : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                          fontWeight:
                                              selectedOptionIndex == index
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (getOptionIcon(index) != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: getOptionIcon(index),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom status indicator
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          size: 18,
                          color: AppColors.textLight,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Playing as ${widget.playerId}",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
