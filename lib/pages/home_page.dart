import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:menti_clone/pages/create_quiz_page.dart';
import 'package:menti_clone/pages/landing_page.dart';
import 'package:menti_clone/pages/my_quizzes_page.dart';
import 'dart:math' as math;

// Menti-inspired color scheme
class MentiColors {
  static const Color primary = Color(0xFF5769E7); // Main blue
  static const Color secondary = Color(0xFFFF7471); // Coral red
  static const Color primaryLight = Color(0xFFD5DAF7); // Light blue
  static const Color secondaryLight = Color(0xFFFFDEDD); // Light coral
  static const Color background = Color(0xFFF9FAFC); // Off-white background
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF303952); // Dark text
  static const Color textSecondary = Color(0xFF8D93A6); // Lighter text
}

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: MentiColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.quiz_rounded,
              size: 35 + (_controller.value * 5),
              color: MentiColors.primary,
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: MentiColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: MentiColors.background,
      appBar: AppBar(
        backgroundColor: MentiColors.background,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MentiColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                    color: MentiColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
                Text(
                  userName,
                  style: TextStyle(
                    color: MentiColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: MentiColors.textSecondary,
              ),
              onPressed: () => _signOut(context),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _controller,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Welcome Section with Logo
                    Center(child: AnimatedLogo()),
                    const SizedBox(height: 20),
                    Text(
                      'Interactive Quizzes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: MentiColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create engaging quizzes for your audience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: MentiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Quick Action Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            title: 'Create Quiz',
                            description: 'Start from scratch',
                            icon: Icons.add_circle_rounded,
                            color: MentiColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateQuizPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            title: 'My Quizzes',
                            description: 'View your library',
                            icon: Icons.folder_rounded,
                            color: MentiColors.secondary,
                            onTap: () {
                              // Navigate to My Quizzes page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyQuizzesPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Recent Activity Section
                    Card(
                      elevation: 0,
                      color: MentiColors.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: MentiColors.primaryLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: MentiColors.textPrimary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Recent Activity',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: MentiColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 48,
                                      color: MentiColors.textSecondary
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No recent quizzes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: MentiColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create your first quiz to get started',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: MentiColors.textSecondary
                                            .withOpacity(0.7),
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
                    const SizedBox(height: 32),
                    // New Quiz Button
                    _AnimatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateQuizPage(),
                          ),
                        );
                      },
                      label: 'Create New Quiz',
                      icon: Icons.add_rounded,
                    ),
                    const SizedBox(height: 16),
                    // View My Quizzes Button
                    _AnimatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyQuizzesPage(),
                          ),
                        );
                      },
                      label: 'View My Quizzes',
                      icon: Icons.library_books_rounded,
                      isPrimary: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MentiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: MentiColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Button with Press Effect
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final bool isPrimary;

  const _AnimatedButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.isPrimary = true,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.isPrimary ? MentiColors.primary : Colors.white;
    final textColor = widget.isPrimary ? Colors.white : MentiColors.primary;
    final borderColor =
        widget.isPrimary ? Colors.transparent : MentiColors.primary;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: widget.isPrimary ? 0 : 2,
                ),
                boxShadow:
                    widget.isPrimary
                        ? [
                          BoxShadow(
                            color: MentiColors.primary.withOpacity(
                              _isPressed ? 0.2 : 0.4,
                            ),
                            blurRadius: _isPressed ? 8 : 15,
                            offset: Offset(0, _isPressed ? 2 : 5),
                            spreadRadius: _isPressed ? 0 : 2,
                          ),
                        ]
                        : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: textColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
