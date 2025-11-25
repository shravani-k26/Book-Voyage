import 'package:book_voyage_demo/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Voyage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF9B2226),
        scaffoldBackgroundColor: const Color(0xFFFEF7DC),
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
          prefixIconColor: const Color(0xFFE07A5F),
          suffixIconColor: const Color(0xFFE07A5F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0XFF9B2226),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF9B2226),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF9B2226),
          selectionColor: Color(0xFFCF6F72),
          selectionHandleColor: Color(0xFF9B2226),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor:Color(0xFFECE2D0)
        )
      ),
      home: Auth_Page(),
    );
  }
}
