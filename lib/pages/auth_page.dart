// auth_page.dart
import 'package:flutter/material.dart';
import 'package:menti_clone/pages/home_page.dart';
import 'package:menti_clone/constants/style_constants.dart';
import 'package:menti_clone/widgets/auth_form.dart';
import 'package:menti_clone/constants/style_constants.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  void _handleAuthSuccess(BuildContext context) {
    // After successful login/signup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Authentication successful!', 
              style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/logo.png', // Add a logo asset to your project
                height: 30,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.quiz, color: AppColors.primaryBlue, size: 30),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Menti Clone',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: AppColors.primaryBlue),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.backgroundLightBlue.withOpacity(0.5),
            ],
          ),
        ),
        child: AuthForm(onAuthSuccess: () => _handleAuthSuccess(context)),
      ),
    );
  }
}

// auth_form.dart
