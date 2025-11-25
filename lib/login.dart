import 'package:book_voyage_demo/home.dart';
import 'package:book_voyage_demo/password_reset.dart';
import 'package:flutter/material.dart';
import 'package:book_voyage_demo/create_account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void>login() async{
    setState(() {
      isLoading = true;
    });
    try{
      if (_usernameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please Enter Username')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      if (_passwordController.text.isEmpty){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please Enter Password')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final DocumentSnapshot usernameDoc= await _firestore
          .collection('usernames').doc(_usernameController.text).get();

      if(!usernameDoc.exists){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Username")),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      final String email=usernameDoc['email'];

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context)=>const HomePage(uid: "",)),
      );
    }catch(e)
    {
      String errorMessage = "Invalid Credentials";
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    var theme=Theme.of(context);
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFECE2D0),Color(0xFFE07A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 30,),
                      Container(
                          height: 300,
                          width: 600,
                          child: Image.asset("assets/images/logo.png",)),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Center(child: Text("Welcome Back!", style: TextStyle(
                          fontSize: 23,
                          color:Color(0xFFB64242),
                          fontWeight: FontWeight.w500,
                        ),
                        ),
                        ),
                      ),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            hintText: 'Username'
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ) ,
                      ),
                      const SizedBox(height: 30),
                      isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: (){
                          login();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF9B2226),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Color(0xFFE07A5F).withOpacity(0.2);
                              }
                              return null;
                            },
                          ),
                        ),
                        child: const Text("Login",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context)=>PasswordResetPage())
                          );
                        },
                        child: const Center(
                            child: Text("Forgot Password?",
                              style: TextStyle(fontWeight: FontWeight.w500),)
                          ),
                      ),
                      const SizedBox(height:80),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text("New to Book Voyage?", style: theme.textTheme.bodyLarge,),
                              ),
                              InkWell(
                                  splashColor: theme.primaryColor.withOpacity(0.8),
                                  onTap: (){
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => CreateAccountPage()
                                        )
                                    );
                                  },
                                  child: Text("Create an account!",
                                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                                  )
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}