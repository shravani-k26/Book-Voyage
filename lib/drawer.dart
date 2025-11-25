import 'dart:io';
import 'package:book_voyage_demo/editProfile.dart';
import 'package:book_voyage_demo/favorites.dart';
import 'package:book_voyage_demo/interests_page.dart';
import 'package:book_voyage_demo/purchased.dart';
import 'package:book_voyage_demo/settingsPage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import 'login.dart';

class SideNavigation extends StatefulWidget{
  const SideNavigation({super.key});

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String userName="";
  String profileImageUrl = "";
  bool isLoading = false;
  Future<void> fetchUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = userData['username'] ?? user.email ?? "Unknown User";
          profileImageUrl = userData.containsKey('profile_image') ? userData['profile_image'] : ""; // Check for existence
        });
      } else {
        // If user document does not exist, create a default one
        await _firestore.collection("users").doc(user.uid).set({
          'username': user.email ?? "Unknown User",
          'profile_image': "",
        });
        setState(() {
          userName = user.email ?? "Unknown User";
          profileImageUrl = "";
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
  Future<void> uploadProfilePicture(String uid) async {
    setState(() {
      isLoading = true; // Set loading state to true
    });
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      String fileName = "user_$uid.jpg";
      try {
        TaskSnapshot uploadTask = await _storage.ref('profilePictures/$fileName').putFile(file);
        String downloadUrl = await uploadTask.ref.getDownloadURL();
        await _firestore.collection('users').doc(uid).update({
          'profile_image': downloadUrl,
        });
        Fluttertoast.showToast(msg: "Image uploaded successfully");
        setState(() {
          profileImageUrl = downloadUrl;// Update the UI with the new image
          isLoading = false;
        });
      } catch (e) {
        print("Error uploading profile picture: $e");
        Fluttertoast.showToast(msg: "Image cannot be uploaded");
        setState(() {
          isLoading = false;
        });
      }
    }
    else{
      setState(() {
        isLoading = false;
      });
    }
  }

  void showImageDialog(String uid, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey));
                },
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    uploadProfilePicture(uid);
                  },
                ),
              ),
            ),
            if (isLoading)
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    fetchUserName();
  }
  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
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
                    GestureDetector(
                      onTap: () {
                        if (user != null) {
                      showImageDialog(user.uid, profileImageUrl.isEmpty ? "assets/images/profile2.jpg" : profileImageUrl);
                    }
                  },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : const AssetImage("assets/images/profile2.jpg") as ImageProvider,
                        backgroundColor: Colors.white,
                      ),
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
              title: const Text('My Shelf'),
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FavoritesPage()),
                );
              },
            ),
          ),
          Material(
            color:Color(0xFFECE2D0),
            elevation: 0.5,
            shadowColor: Color(0xFFE07A5F),
            child: ListTile(
              leading: Image.asset('assets/images/shopping-cart.png', height: 28,),
              title: const Text('My Purchases'),
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PurchasedPage()),
                );
              },
            ),
          ),
          Material(
            color:Color(0xFFECE2D0),
            elevation: 0.5,
            shadowColor: Color(0xFFE07A5F),
            child: ListTile(
              leading: Icon(Icons.edit, size: 28,),
              title: const Text('Edit Profile'),
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                );
              },
            ),
          ),
          Material(
            color:Color(0xFFECE2D0),
            elevation: 0.5,
            shadowColor: Color(0xFFE07A5F),
            child: ListTile(
              leading: Icon(Icons.interests, size: 28,),
              title: const Text('Edit Your Interest'),
              onTap: (){
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InterestsPage(uid: user.uid),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User not logged in')),
                  );
                }
              },
            ),
          ),
          Material(
            color:Color(0xFFECE2D0),
            elevation: 0.5,
            shadowColor: Color(0xFFE07A5F),
            child: ListTile(
              leading: Icon(Icons.settings, size: 28,),
              title: const Text('Settings'),
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ),
          SizedBox(height: 24,),
          GestureDetector(
            onTap: ()=>_logout(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout),
                Text('Logout')
              ],
            ),
          ),
        ],
      ),
    );
  }
}