import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:menti_clone/constants/style_constants.dart';
import 'lobby_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage>
    with SingleTickerProviderStateMixin {
  final _quizTitleController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  final List<TextEditingController> _questionControllers = [];
  final List<List<TextEditingController>> _optionControllers = [];
  final List<TextEditingController> _timeLimitControllers = [];

  // Animation controllers
  late AnimationController _animationController;
  int _lastAddedQuestionIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _quizTitleController.dispose();
    // Dispose all question controllers
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    // Dispose all option controllers
    for (var optionList in _optionControllers) {
      for (var controller in optionList) {
        controller.dispose();
      }
    }
    // Dispose all time limit controllers
    for (var controller in _timeLimitControllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    HapticFeedback.mediumImpact();

    final questionController = TextEditingController();
    final timeLimitController = TextEditingController(text: '30');
    final optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    setState(() {
      _questions.add({
        'question': '',
        'options': ['', ''],
        'correctAnswer': 0,
        'timeLimit': 30,
      });
      _questionControllers.add(questionController);
      _optionControllers.add(optionControllers);
      _timeLimitControllers.add(timeLimitController);
      _lastAddedQuestionIndex = _questions.length - 1;
    });

    // Animate new question
    _animationController.reset();
    _animationController.forward();

    // Scroll to the newly added question
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _addOptionToQuestion(int questionIndex) {
    HapticFeedback.lightImpact();

    setState(() {
      _questions[questionIndex]['options'].add('');
      _optionControllers[questionIndex].add(TextEditingController());
    });
  }

  void _removeOptionFromQuestion(int questionIndex, int optionIndex) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_questions[questionIndex]['options'].length > 2) {
        _questions[questionIndex]['options'].removeAt(optionIndex);
        final controller = _optionControllers[questionIndex].removeAt(
          optionIndex,
        );
        controller.dispose();

        // Adjust correctAnswer if needed
        if (_questions[questionIndex]['correctAnswer'] == optionIndex) {
          _questions[questionIndex]['correctAnswer'] = 0;
        } else if (_questions[questionIndex]['correctAnswer'] > optionIndex) {
          _questions[questionIndex]['correctAnswer'] =
              _questions[questionIndex]['correctAnswer'] - 1;
        }
      }
    });
  }

  void _removeQuestion(int questionIndex) {
    HapticFeedback.mediumImpact();

    setState(() {
      _questions.removeAt(questionIndex);
      _questionControllers[questionIndex].dispose();
      _questionControllers.removeAt(questionIndex);
      for (var controller in _optionControllers[questionIndex]) {
        controller.dispose();
      }
      _optionControllers.removeAt(questionIndex);
      _timeLimitControllers[questionIndex].dispose();
      _timeLimitControllers.removeAt(questionIndex);
    });
  }

Future<void> _saveQuiz() async {
  HapticFeedback.heavyImpact();

  final title = _quizTitleController.text.trim();
  if (title.isEmpty || _questions.isEmpty) {
    _showErrorSnackbar('Quiz title and at least one question required');
    return;
  }

  // Validate all questions have content
  for (int i = 0; i < _questions.length; i++) {
    final question = _questions[i];
    if (question['question'].toString().trim().isEmpty) {
      _showErrorSnackbar('Question ${i + 1} is empty');
      return;
    }

    final options = question['options'] as List;
    for (int j = 0; j < options.length; j++) {
      if (options[j].toString().trim().isEmpty) {
        _showErrorSnackbar('Option ${j + 1} in Question ${i + 1} is empty');
        return;
      }
    }
  }

  // Show loading indicator
  _showLoadingDialog('Creating your quiz...');

  try {
    // Get current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackbar('User not logged in');
      return;
    }

    final code = _generateQuizCode();
    final quizDoc = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(code);

    await quizDoc.set({
      'title': title,
      'code': code,
      'createdBy': currentUser.uid, // Add user ID here
      'createdAt': Timestamp.now(),
      'started': false,
      'currentQuestionIndex': 0,
      'questions': _questions,
      'questionStartTime': null,
    });

    // Pop loading dialog
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                LobbyPage(quizId: code, code: code),
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
    _showErrorSnackbar('Failed to save quiz: ${e.toString()}');
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Create Quiz',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryBlue),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz title section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.quiz, color: AppColors.primaryBlue),
                        SizedBox(width: 10),
                        Text(
                          'Quiz Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _quizTitleController,
                      decoration: InputDecoration(
                        labelText: 'Quiz Title',
                        hintText: 'Enter a descriptive title for your quiz',
                        prefixIcon: Icon(
                          Icons.title,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Questions counter
              if (_questions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    '${_questions.length} ${_questions.length == 1 ? 'Question' : 'Questions'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

              // Questions list
              ..._questions.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> q = entry.value;
                bool isLastAdded = index == _lastAddedQuestionIndex;

                // Create question card with animation if it's the last added
                Widget questionCard = Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shadowColor: AppColors.primaryBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'Q${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: SizedBox()),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppColors.errorRed,
                              ),
                              onPressed: () => _removeQuestion(index),
                              tooltip: 'Remove question',
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Question text field
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Question Text',
                            hintText: 'Enter your question here',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          controller: _questionControllers[index],
                          onChanged:
                              (val) => setState(() => q['question'] = val),
                        ),

                        SizedBox(height: 16),

                        // Options divider
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppColors.primaryBlue,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Answer Options',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                indent: 8,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Options list
                        ...q['options'].asMap().entries.map((optEntry) {
                          int optIndex = optEntry.key;

                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                                  q['correctAnswer'] == optIndex
                                      ? AppColors.backgroundLightBlue
                                          .withOpacity(0.5)
                                      : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    q['correctAnswer'] == optIndex
                                        ? AppColors.primaryBlue
                                        : Colors.grey[300]!,
                                width: q['correctAnswer'] == optIndex ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Radio button for correct answer
                                Radio<int>(
                                  value: optIndex,
                                  groupValue: q['correctAnswer'],
                                  activeColor: AppColors.primaryBlue,
                                  onChanged:
                                      (val) => setState(
                                        () => q['correctAnswer'] = val!,
                                      ),
                                ),

                                // Option text field
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Option ${optIndex + 1}',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    controller:
                                        _optionControllers[index][optIndex],
                                    onChanged:
                                        (val) => setState(
                                          () => q['options'][optIndex] = val,
                                        ),
                                  ),
                                ),

                                // Remove option button
                                if (q['options'].length > 2)
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: AppColors.errorRed,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => _removeOptionFromQuestion(
                                          index,
                                          optIndex,
                                        ),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Remove option',
                                  ),
                              ],
                            ),
                          );
                        }).toList(),

                        // Add option button
                        TextButton.icon(
                          onPressed: () => _addOptionToQuestion(index),
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Add Option'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.green[300]!),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Time limit section
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, color: AppColors.primaryBlue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time Limit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Slider(
                                            value:
                                                (q['timeLimit'] as int)
                                                    .toDouble(),
                                            min: 5,
                                            max: 120,
                                            divisions: 23,
                                            activeColor: AppColors.primaryBlue,
                                            inactiveColor:
                                                AppColors.backgroundLightBlue,
                                            label: '${q['timeLimit']} seconds',
                                            onChanged: (value) {
                                              setState(() {
                                                q['timeLimit'] = value.round();
                                                _timeLimitControllers[index]
                                                        .text =
                                                    value.round().toString();
                                              });
                                            },
                                          ),
                                        ),
                                        Container(
                                          width: 60,
                                          child: TextField(
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              isDense: true,
                                              suffixText: 's',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            controller:
                                                _timeLimitControllers[index],
                                            textAlign: TextAlign.center,
                                            onChanged: (val) {
                                              final timeLimit =
                                                  int.tryParse(val) ?? 30;
                                              setState(
                                                () =>
                                                    q['timeLimit'] = timeLimit
                                                        .clamp(5, 120),
                                              );
                                            },
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
                      ],
                    ),
                  ),
                );

                // Apply animation if it's the last added question
                if (isLastAdded) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _animationController,
                      child: questionCard,
                    ),
                  );
                }

                return questionCard;
              }).toList(),

              SizedBox(height: 16),

              // Add question button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: Icon(Icons.add),
                  label: Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryBlue,
                    elevation: 2,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Save and present button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveQuiz,
                  icon: Icon(Icons.play_arrow),
                  label: Text(
                    'Save & Present',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
