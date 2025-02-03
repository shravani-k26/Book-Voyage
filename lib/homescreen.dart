import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'drawer.dart';

class HomeScreen extends StatefulWidget{
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Future<List<Map<String, String>>> getBooks() async{
  //   QuerySnapshot querySnapshot= await _firestore.collection('books').get();
  // }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(

    );
  }
}