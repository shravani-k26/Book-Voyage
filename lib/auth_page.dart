import 'package:book_voyage_demo/home.dart';
import 'package:book_voyage_demo/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth_Page extends StatelessWidget{
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user has logged in
          if(snapshot.hasData){
            return HomePage(uid: snapshot.data!.uid);
          }
          //user has not logged in
          else{
            return LoginPage();
          }
        },
      ),
    );
  }
  
}