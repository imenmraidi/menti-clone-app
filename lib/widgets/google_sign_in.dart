import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';  // Import the auth service we created
import 'package:firebase_auth/firebase_auth.dart';  // Import FirebaseAuth for User class

class GoogleSignInButton extends StatefulWidget {
  final Function(User?) onSignIn;  // Callback for when sign-in completes
  
  const GoogleSignInButton({Key? key, required this.onSignIn}) : super(key: key);

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final AuthService _authService = AuthService();
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _isSigningIn
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : OutlinedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              onPressed: () async {
                setState(() {
                  _isSigningIn = true;
                });

                // Call the signInWithGoogle method from our AuthService
                final userCredential = await _authService.signInWithGoogle();
                
                setState(() {
                  _isSigningIn = false;
                });

                // Call the callback with the signed-in user
                if (userCredential != null) {
                  widget.onSignIn(userCredential.user);
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.network(
                      'https://www.freepnglogos.com/uploads/google-logo-png/google-logo-png-google-icon-logo-png-transparent-svg-vector-bie-supply-14.png',
                      height: 24.0,
                      width: 24.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}