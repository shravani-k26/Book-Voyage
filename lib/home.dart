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
        color: Color(0xFFE8A391),
        child: SingleChildScrollView(
          child: const Scaffold(
            drawer: ,
            backgroundColor: Colors.transparent,
            body:
          ),
        ),
      ),
    );
  }

}