import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';

class SideNavigation extends StatefulWidget{
  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userName="";
  Future<void>fetchUserName() async{
    User? user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      DocumentSnapshot userDoc= await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if(userDoc.exists){
        setState(() {
          userName=userDoc['username'] ?? userDoc['email'] ?? "Unknown User";
        });
      }
    }
  }
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
  @override
  void initState() {
    super.initState();
    fetchUserName();
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children:[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFECE2D0),Color(0xFFE07A5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
              ),
            ),
            child: SizedBox(
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("assets/images/profile.png") ,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 10,),
                    Text("$userName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color:Colors.white ),),
                    const SizedBox(height: 10,)
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                  onPressed: ()=>_logout(context),
                  icon: Icon(Icons.logout)
              )
            ],
          )
        ],
      ),
    );
  }
}