import 'package:book_voyage_demo/login.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget{
  final String uid;
  const HomePage({super.key, required this.uid});
  @override
  Widget build(BuildContext context) {
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
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(child: Text("Welcome", style: TextStyle(fontSize: 30),)),
              Center(
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF9B2226)),
                    onPressed: (){
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context)=> const LoginPage())
                      );
                    },
                    icon: const Icon(Icons.logout)
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

}