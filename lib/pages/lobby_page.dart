import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'admin_quiz_page.dart';
import '../constants/style_constants.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add this package to pubspec.yaml

class LobbyPage extends StatefulWidget {
  final String quizId;
  final String code;

  const LobbyPage({super.key, required this.quizId, required this.code});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _buttonController;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();

    // Animation for the quiz code pulse effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Animation for button press
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _copyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _codeCopied = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _codeCopied = false;
        });
      }
    });
  }

  void startQuiz(BuildContext context) async {
    _buttonController.forward().then((_) => _buttonController.reverse());

    await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .update({'started': true, 'currentQuestionIndex': 0});

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, animation, secondaryAnimation) =>
                AdminQuizPage(quizId: widget.quizId),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playersRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('players');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Waiting Room',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('How to Join'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. Go to the URL shown below'),
                          Text('2. Enter the code: ${widget.code}'),
                          Text('3. Choose a name and join'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Got it'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Top Card - Quiz Code
            Card(
                  elevation: 6,
                  margin: EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              color: AppColors.primaryBlue,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Share this code',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 30,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLightBlue
                                    .withOpacity(
                                      0.7 + _pulseController.value * 0.3,
                                    ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SelectableText(
                                widget.code,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              SizedBox(width: 12),
                              IconButton(
                                icon: Icon(
                                  _codeCopied ? Icons.check_circle : Icons.copy,
                                  color:
                                      _codeCopied
                                          ? Colors.green
                                          : AppColors.primaryBlue,
                                ),
                                onPressed: _copyCodeToClipboard,
                                tooltip: 'Copy code',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.link,
                              color: AppColors.textLight,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'http://localhost:8080/#/join',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fade(duration: 500.ms)
                .slideY(begin: -0.3, end: 0, duration: 500.ms),

            // Player List Section
            Expanded(
              child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Players Joined',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: playersRef.snapshots(),
                              builder: (_, snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryBlue,
                                    ),
                                  );
                                }

                                final docs = snapshot.data!.docs;

                                if (docs.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.hourglass_empty,
                                          size: 48,
                                          color: AppColors.textLight,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Waiting for players to join...',
                                          style: TextStyle(
                                            color: AppColors.textLight,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder: (_, i) {
                                    final playerName =
                                        docs[i]['name'] as String;
                                    // Calculate a consistent color for each player
                                    final Color avatarColor =
                                        AppColors.avatarColors[playerName
                                                .hashCode %
                                            AppColors.avatarColors.length];

                                    return Card(
                                      elevation: 1,
                                      margin: EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: avatarColor,
                                          child: Text(
                                            playerName[0].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          playerName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        trailing: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                      ),
                                    ).animate().fade(
                                      duration: 300.ms,
                                      delay: (i * 100).ms,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fade(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.3, end: 0, duration: 500.ms),
            ),

            SizedBox(height: 24),

            // Start Quiz Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1.0,
                  end: 0.95,
                ).animate(_buttonController),
                child: ElevatedButton.icon(
                  onPressed: () => startQuiz(context),
                  icon: Icon(Icons.play_arrow_rounded, size: 28),
                  label: Text(
                    'Start Quiz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ).animate().fade(duration: 500.ms, delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
