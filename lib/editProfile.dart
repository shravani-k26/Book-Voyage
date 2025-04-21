import 'dart:io';
import 'package:book_voyage_demo/login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _emailController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _usernameController=TextEditingController();
  File? _imageFile;
  DateTime? _selectedBirthdate;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Load current user profile data
  Future<void> _loadCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _emailController.text = userData['email'] ?? '';
          _usernameController.text = userData['username'] ?? '';

          if (userData['birthday'] != null) {
            Timestamp timestamp = userData['birthday'];
            _selectedBirthdate = timestamp.toDate();
            _birthdateController.text =
            "${_selectedBirthdate!.day.toString().padLeft(2, '0')}-${_selectedBirthdate!.month.toString().padLeft(2, '0')}-${_selectedBirthdate!.year}";
          }

          _profileImageUrl = userData['profile_image'] ?? '';
        });
      }
    }
  }


  // Function to pick a new profile image
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to update profile (email, profile picture, birthdate)
  Future<void> _updateProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update email
        if (_emailController.text.isNotEmpty) {
          await user.updateEmail(_emailController.text);
        }

        // Convert birthdate to Timestamp and update it
        if (_selectedBirthdate != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'birthday': Timestamp.fromDate(_selectedBirthdate!),
            'email': _emailController.text,
          });
          await _firestore.collection('usernames').doc(_usernameController.text).update({
            'email': _emailController.text,
          });
        }

        // Update profile picture if there's a new one
        if (_imageFile != null) {
          String imageUrl = await _uploadImage(_imageFile!);
          await _firestore.collection('users').doc(user.uid).update({
            'profile_image': imageUrl,
          });
        }

        Fluttertoast.showToast(msg: "Profile updated successfully.");
        Navigator.pop(context);// Close the EditProfile page
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error updating profile: $e");
    }
  }

  // Function to upload the image to Firebase Storage
  Future<String> _uploadImage(File image) async {
    try {
      String fileName = "profile_${DateTime.now().millisecondsSinceEpoch}.jpg";
      TaskSnapshot uploadTask = await _storage.ref('profilePictures/$fileName').putFile(image);
      String downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Error uploading image: $e");
    }
  }

  // Function to pick birthdate
  Future<void> _pickBirthdate(BuildContext context) async {
    DateTime initialDate = _selectedBirthdate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != initialDate) {
      setState(() {
        _selectedBirthdate = pickedDate;
        // Format the date as DD-MM-YYYY
        _birthdateController.text = "${pickedDate.day.toString().padLeft(2,'0')}/${pickedDate.month.toString().padLeft(2,'0')}/${pickedDate.year.toString()}";
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Edit Profile"),
          leading: BackButton(),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: (_imageFile == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                        ? const Icon(Icons.camera_alt, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  enabled: false,
                  decoration: InputDecoration(
                      labelText: "Username",
                      disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: const BorderSide(
                            color: Color(0xFF9B2226),
                            width: 2,
                      )
                  ),
                ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email",
                    labelStyle: TextStyle(
                      color: Color(0xFFE07A5F),// Set your desired label color here
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _birthdateController,
                  decoration: const InputDecoration(labelText: "Birthdate",
                    labelStyle: TextStyle(
                      color: Color(0xFFE07A5F),// Set your desired label color here
                    ),
                  ),
                  onTap: () {
                    _pickBirthdate(context);
                  },
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9B2226),
                    minimumSize: Size(double.infinity, 50),
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
                    _updateProfile();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
