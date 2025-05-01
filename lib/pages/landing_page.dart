import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'dart:math' as math;

class MentiColors {
  static const Color primary = Color(0xFF5769E7);      // Main blue
  static const Color secondary = Color(0xFFFF7471);    // Coral red
  static const Color primaryLight = Color(0xFFD5DAF7); // Light blue
  static const Color secondaryLight = Color(0xFFFFDEDD); // Light coral
  static const Color background = Color(0xFFF9FAFC);   // Off-white background
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF303952);  // Dark text
  static const Color textSecondary = Color(0xFF8D93A6); // Lighter text
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _logoRotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Content animations
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MentiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - 32, // Account for SafeArea padding
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and decorative elements
                  AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _logoRotationAnimation.value,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildLogo(),
                  ),
                  const SizedBox(height: 48),
                  
                  // Content card with slide and fade animations
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeInAnimation,
                      child: _buildContentCard(context),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Decorative shapes at bottom
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDecorativeShape(MentiColors.primaryLight, 8),
                        const SizedBox(width: 16),
                        _buildDecorativeShape(MentiColors.secondaryLight, 12),
                        const SizedBox(width: 16),
                        _buildDecorativeShape(MentiColors.primaryLight, 16),
                        const SizedBox(width: 16),
                        _buildDecorativeShape(MentiColors.secondaryLight, 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background blurred circles
        Positioned(
          left: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MentiColors.primaryLight.withOpacity(0.6),
            ),
          ),
        ),
        Positioned(
          right: -60,
          bottom: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MentiColors.secondaryLight.withOpacity(0.6),
            ),
          ),
        ),
        
        // Main logo container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: MentiColors.primary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: MentiColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.quiz_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      color: MentiColors.cardBackground,
      shadowColor: MentiColors.primary.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with gradient effect
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [MentiColors.primary, MentiColors.primary.withBlue(255)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'MentiClone',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Feature icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureIcon(Icons.question_answer_rounded, 'Create'),
                _buildFeatureIcon(Icons.groups_rounded, 'Present'),
                _buildFeatureIcon(Icons.analytics_rounded, 'Analyze'),
              ],
            ),
            const SizedBox(height: 32),
            
            // Description text
            Text(
              'Create and present interactive quizzes with real-time audience participation and instant visual feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: MentiColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            
            // Action buttons
            _AnimatedGradientButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const AuthPage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      var begin = const Offset(1.0, 0.0);
                      var end = Offset.zero;
                      var curve = Curves.easeOutCubic;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
              label: 'Get Started',
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Join as participant flow
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('This feature is coming soon!'),
                    backgroundColor: MentiColors.secondary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: MentiColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_rounded, size: 16, color: MentiColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Join as Participant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MentiColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: MentiColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MentiColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeShape(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 3),
      ),
    );
  }
}

class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _AnimatedGradientButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  _AnimatedGradientButtonState createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MentiColors.primary,
                    MentiColors.primary.withBlue(255),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: MentiColors.primary.withOpacity(_isPressed ? 0.2 : 0.4),
                    blurRadius: _isPressed ? 8 : 15,
                    offset: Offset(0, _isPressed ? 2 : 5),
                    spreadRadius: _isPressed ? 0 : 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
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