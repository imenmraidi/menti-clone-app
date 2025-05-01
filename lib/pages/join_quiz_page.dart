import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'playing_quiz_page.dart';
import '../constants/style_constants.dart';

class JoinQuizPage extends StatefulWidget {
  const JoinQuizPage({super.key});

  @override
  State<JoinQuizPage> createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorMessage;
  String? _quizId;
  String? _playerId;
  bool _navigated = false;
  bool _isJoining = false;
  FocusNode _codeFocusNode = FocusNode();
  FocusNode _nameFocusNode = FocusNode();
  late AnimationController _loadingController;
  late AnimationController _buttonController;

  Stream<DocumentSnapshot>? _quizStream;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    Future.delayed(Duration(milliseconds: 300), () {
      _codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _codeFocusNode.dispose();
    _nameFocusNode.dispose();
    _loadingController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void joinQuiz() async {
    _buttonController.forward().then((_) => _buttonController.reverse());

    final code = _codeController.text.trim();
    final name = _nameController.text.trim();

    if (code.isEmpty || name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both your name and the quiz code';

        if (code.isEmpty) {
          _codeFocusNode.requestFocus();
        } else {
          _nameFocusNode.requestFocus();
        }
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('quizzes')
              .where('code', isEqualTo: code)
              .get();

      if (query.docs.isEmpty) {
        setState(() {
          _errorMessage =
              'Quiz not found. Please check the code and try again.';
          _isJoining = false;
        });
        return;
      }

      final quizDoc = query.docs.first;
      final quizId = quizDoc.id;

      setState(() {
        _quizId = quizId;
        _quizStream =
            FirebaseFirestore.instance
                .collection('quizzes')
                .doc(quizId)
                .snapshots();
      });

      final playerRef =
          FirebaseFirestore.instance
              .collection('quizzes')
              .doc(quizId)
              .collection('players')
              .doc();

      await playerRef.set({'name': name, 'joinedAt': Timestamp.now()});

      setState(() {
        _playerId = playerRef.id;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(
            'Join Quiz',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.quiz_rounded,
                  size: 80,
                  color: AppColors.primaryBlue,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                SizedBox(height: 16),

                Text(
                  'Enter a code to join a quiz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).animate().fade(duration: 400.ms),

                SizedBox(height: 8),

                Text(
                  'Ask your presenter for the quiz code',
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                ).animate().fade(duration: 400.ms, delay: 100.ms),

                SizedBox(height: 32),

                if (_playerId == null) ...[
                  Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quiz Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _codeController,
                                focusNode: _codeFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'Enter the 6-digit code',
                                  prefixIcon: Icon(
                                    Icons.tag,
                                    color: AppColors.primaryBlue,
                                  ),
                                  errorText:
                                      (_errorMessage != null &&
                                              _codeController.text.isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                onSubmitted:
                                    (_) => _nameFocusNode.requestFocus(),
                              ),

                              SizedBox(height: 24),

                              Text(
                                'Your Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'How should we call you?',
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: AppColors.primaryBlue,
                                  ),
                                  errorText:
                                      (_errorMessage != null &&
                                              _nameController.text.isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => joinQuiz(),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms),

                  SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1.0,
                        end: 0.95,
                      ).animate(_buttonController),
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : joinQuiz,
                        icon:
                            _isJoining
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(Icons.login_rounded),
                        label: Text(
                          _isJoining ? 'Joining...' : 'Join Quiz',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 400.ms, delay: 300.ms),
                ],

                if (_errorMessage != null &&
                    !(_errorMessage!.contains('Required'))) ...[
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLightRed,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.errorRed.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.errorRed),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppColors.errorRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(duration: 300.ms),
                ],

                if (_quizStream != null) ...[
                  SizedBox(height: 32),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _quizStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }

                      final quizData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final started = quizData['started'] == true;
                      final quizName = quizData['title'] ?? 'Quiz';

                      if (started &&
                          !_navigated &&
                          _quizId != null &&
                          _playerId != null) {
                        _navigated = true;
                        Future.microtask(() {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (_, animation, __) => PlayingQuizPage(
                                    quizId: _quizId!,
                                    playerId: _playerId!,
                                  ),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration: Duration(milliseconds: 500),
                            ),
                          );
                        });
                      }

                      return Card(
                            color: AppColors.backgroundLightBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Youve joined',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    quizName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  AnimatedBuilder(
                                    animation: _loadingController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        size: Size(200, 10),
                                        painter: LoadingBarPainter(
                                          progress: _loadingController.value,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.7),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Waiting for presenter to start...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate(target: _playerId != null ? 1 : 0)
                          .fade()
                          .scale();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingBarPainter extends CustomPainter {
  final double progress;

  LoadingBarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint =
        Paint()
          ..color = AppColors.primaryBlue.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    canvas.drawRRect(trackRect, trackPaint);

    final progressPaint =
        Paint()
          ..color = AppColors.primaryBlue
          ..style = PaintingStyle.fill;

    double startX = progress * size.width * 2 - size.width * 0.3;
    if (startX > size.width) {
      startX = size.width * 2 - startX;
    } else if (startX < -size.width * 0.3) {
      startX = -size.width * 0.3 * 2 - startX;
    }

    final progressWidth = size.width * 0.3;

    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, 0, progressWidth, size.height),
      Radius.circular(size.height / 2),
    );

    canvas.drawRRect(progressRect, progressPaint);
  }

  @override
  bool shouldRepaint(LoadingBarPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
