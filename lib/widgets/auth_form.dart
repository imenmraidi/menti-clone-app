import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:menti_clone/constants/style_constants.dart';
import 'package:flutter/services.dart';

class AuthForm extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const AuthForm({super.key, required this.onAuthSuccess});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == null || !isValid) return;

    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Signup
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      widget.onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.message ?? 'Authentication Error',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Call success callback
      widget.onAuthSuccess();
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Google Sign-In failed: ${e.toString()}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _toggleAuthMode() {
    // Animate transition between login and signup
    _animationController.reset();
    setState(() {
      _isLogin = !_isLogin;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: size.width > 600 ? 400 : size.width * 0.9,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Card(
              elevation: 8,
              shadowColor: AppColors.primaryBlue.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? 'Sign in to continue '
                          : 'Join menti clone to create and play quizzes',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email address',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.primaryBlue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.errorRed,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.errorRed,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),

                          if (!_isLogin) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Password must be at least 6 characters long',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),

                          // Action buttons
                          if (_isLoading)
                            Container(
                              height: 56,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                minimumSize: const Size(double.infinity, 50),
                                elevation: 0,
                              ),
                              child: Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Divider with "OR" text
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Google Sign In Button
                            _isGoogleLoading
                                ? Container(
                                  height: 50,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[600]!,
                                      ),
                                    ),
                                  ),
                                )
                                : ElevatedButton(
                                  onPressed: _signInWithGoogle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google_logo.png',
                                        height: 24,
                                        width: 24,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.g_mobiledata,
                                                  size: 24,
                                                ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _toggleAuthMode,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLogin
                                        ? 'Don\'t have an account? '
                                        : 'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _isLogin ? 'Sign Up' : 'Sign In',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
