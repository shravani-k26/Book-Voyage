import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';  // Import fluttertoast

class PasswordResetPage extends StatefulWidget {
  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final TextEditingController _emailController = TextEditingController();

  // Function to send password reset email
  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      Fluttertoast.showToast(
        msg: "Please enter a valid email.",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    try {
      print("Sending reset email to: $email");
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("Reset email sent.");
      Fluttertoast.showToast(
        msg: "Password reset email sent! Check your inbox.",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.code} - ${e.message}");
      Fluttertoast.showToast(
        msg: e.message ?? "An error occurred.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
            title: Text('Reset Password')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9B2226),
                  minimumSize: Size(double.infinity, 50),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color(0xFFE07A5F).withOpacity(0.2); // Splash effect color
                      }
                      return null; // Default splash color
                    },
                  ),
                ),
                onPressed: (){
                  _sendPasswordResetEmail();
                },
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Text("Send Reset Link", style: TextStyle(fontSize: 16, color: Colors.white),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
