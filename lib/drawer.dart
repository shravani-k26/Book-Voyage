import 'package:book_voyage_demo/favorites.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';

class SideNavigation extends StatefulWidget{
  const SideNavigation({super.key});

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
          const SizedBox(height: 20),
          Material(
            color:Color(0xFFECE2D0),
            elevation: 0.5,
            shadowColor: Color(0xFFE07A5F),
            child: ListTile(
              leading: Image.asset('assets/images/shelf.png', height: 28,),
              title: const Text('Your Shelf'),
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FavoritesPage()),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: ()=>_logout(context),
                  icon: Icon(Icons.logout)
              ),
              const Text('Logout')
            ],
          ),
        ],
      ),
    );
  }
}