import 'package:book_voyage_demo/home.dart';
import 'package:book_voyage_demo/interests_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}
class _CreateAccountState extends State<CreateAccountPage>{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  final _nameController=TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthdayController = TextEditingController();

  bool isLoading = false;

  Future<void>createAccount() async{
    setState(() {
      isLoading = true; // Start loading
    });
    const String defaultProfileImageUrl = "https://i.pinimg.com/736x/6c/eb/75/6ceb75052855a7c75e8134396f801f64.jpg";
    try{
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Full Name cannot be empty.')),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }
      if (_emailController.text.isEmpty || !RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address.')),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }
      final birthdayParts = _birthdayController.text.split('/');
      if (birthdayParts.length != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid birthday format! Use DD/MM/YYYY')),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }
      final day = int.tryParse(birthdayParts[0]);
      final month = int.tryParse(birthdayParts[1]);
      final year = int.tryParse(birthdayParts[2]);

      if (day == null || month == null || year == null || month < 1 || month > 12 || day < 1 || day > 31) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid birthday format! Use DD/MM/YYYY')),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }
      final birthdayDate = DateTime(year!, month!, day!);
      if (_usernameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username cannot be empty.')),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }
      final usernameSnapshot = await _firestore.collection('usernames').doc(_usernameController.text).get();
      if (usernameSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already in use. Please choose another one.')),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }

      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password should be at least 6 characters long.')),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match!'),
          ),
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        return;
      }
      final UserCredential userCredential=await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text
      );
      final String uid=userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'fullname': _nameController.text,
        'username':_usernameController.text,
        'email': _emailController.text,
        'birthday': Timestamp.fromDate(birthdayDate),
        'profile_image': defaultProfileImageUrl,
      });

      await _firestore.collection('usernames').doc(_usernameController.text).set({
        'email': _emailController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account Created Successfuly')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context)=>InterestsPage(uid: uid)),
      );
    }on FirebaseAuthException catch (e) {
      // Check for specific error code when email is already in use
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The email address is already in use.')),
        );
      } else {
        // For other FirebaseAuthException errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECE2D0),Color(0xFFE07A5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: Container(
                        child: Text("Create Account",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Container(height: 120,
                        width: 300,
                        child: Image.asset("assets/images/acc_logo.png")
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          hintText: "Full Name",
                          prefixIcon: Icon(Icons.person)
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          hintText: "Email",
                          prefixIcon: Icon(Icons.email)
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _birthdayController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_month),
                        hintText: "Enter your Birthday (DD/MM/YYYY)",
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        DateTime? pickedDate= await showDatePicker(
                          builder: (BuildContext context, Widget? child){
                            return Theme(
                                data: ThemeData(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFFE07A5F),
                                    onPrimary: Colors.white,
                                  ),
                                  textSelectionTheme: const TextSelectionThemeData(
                                    cursorColor: Color(0xFF9B2226),
                                    selectionColor: Color(0xFFCF6F72),
                                    selectionHandleColor: Color(0xFF9B2226),
                                  ),
                                  dialogBackgroundColor: const Color(0xFFFEF7DC),
                                  inputDecorationTheme: InputDecorationTheme(
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30.0),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE07A5F),
                                          width: 2,
                                        )
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFECE2D0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                child: child!,
                            );
                          },
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate!=null){
                          setState(() {
                            _birthdayController.text="${pickedDate.day.toString().padLeft(2,'0')}/${pickedDate.month.toString().padLeft(2,'0')}/${pickedDate.year.toString()}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                          hintText: "Create Username",
                          prefixIcon: Icon(Icons.person_2)
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "Password",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "Confirm Password",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    isLoading
                    ?Center(child: CircularProgressIndicator())
                    :ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
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
                        createAccount();
                      },
                      child: const Text("Create Account", style: TextStyle(fontSize: 18, color: Colors.white),),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text("Already have an account?", style: theme.textTheme.bodyLarge,),
                        ),
                        InkWell(
                          onTap: (){
                            Navigator.pop(context);
                          },
                          splashColor: theme.primaryColor.withOpacity(0.8),
                          child: Text("Login Here!",
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,)
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
