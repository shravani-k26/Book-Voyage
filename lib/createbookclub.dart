import 'package:book_voyage_demo/selectusers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';

class CreateBookClubPage extends StatefulWidget {
  final String userId;

  CreateBookClubPage({required this.userId});

  @override
  _CreateBookClubPageState createState() => _CreateBookClubPageState();
}

class _CreateBookClubPageState extends State<CreateBookClubPage> {
  final _clubNameController = TextEditingController();
  final _clubDescriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Map<String, dynamic>> _selectedUsers = [];
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;

  Future<void> createBookClub() async {
    String clubName = _clubNameController.text.trim();
    String clubDescription = _clubDescriptionController.text.trim();
    String defaultImageUrl = "https://i.pinimg.com/1200x/c9/43/67/c94367e107ee3c63a14ef1164479726f.jpg";

    if (clubName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Club name cannot be empty!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedImage != null) {
        String fileName = 'book_club_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        UploadTask uploadTask = _storage.ref(fileName).putFile(_selectedImage!);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        _imageUrl = await snapshot.ref.getDownloadURL();
      }
      else{
        _imageUrl = defaultImageUrl;
      }

      List<String> memberIds = [widget.userId, ..._selectedUsers.map((user) => user['id']).toList()];

      DocumentReference clubRef = await _firestore.collection('bookClubs').add({
        'name': clubName,
        'description': clubDescription,
        'creatorId': widget.userId,
        'members': memberIds,
        'membersCount': memberIds.length,
        'clubImageUrl': _imageUrl ?? "",
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(widget.userId).update({
        'createdClubs': FieldValue.arrayUnion([clubRef.id]),
      });

      for (var user in _selectedUsers) {
        await _firestore.collection('users').doc(user['id']).update({
          'joinedClubs': FieldValue.arrayUnion([clubRef.id]),
        });
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Book club created successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating book club: $e")),
      );
    }
    finally{
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }
  Future<void> _navigateToSelectUsersPage() async {
    final selectedUsers = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectUsersPage(
          initialSelectedUsers: _selectedUsers,
        ),
      ),
    );

    if (selectedUsers != null) {
      setState(() {
        _selectedUsers = selectedUsers;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xFFE8A391),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            iconTheme: const IconThemeData(
                size: 30,
                color: Color(0xFFECE2D0),
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black45,
                    offset: Offset(1.0, 1.0),
                  ),
                ]
            ),
            title: const Text(
                "Create Book Club",
                style: TextStyle(
                    color: Color(0xFFF8F0E3),
                    fontSize:25,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),]
                )
            ),
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _clubNameController,
                    decoration: const InputDecoration(hintText: 'Book Club Name'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _clubDescriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Book Club Description'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF9B2226),
                        minimumSize: Size(double.infinity, 50),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Color(0xFFE07A5F).withOpacity(0.2); // Splash effect color
                            }
                            return null; // Default splash color
                          },
                        ),
                      ),
                      child: const Text("Upload Image", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Image.file(_selectedImage!, height: 100, width: 100, fit: BoxFit.cover)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _navigateToSelectUsersPage,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF9B2226),
                      minimumSize: Size(double.infinity, 50),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Color(0xFFE07A5F).withOpacity(0.2); // Splash effect color
                          }
                          return null; // Default splash color
                        },
                      ),
                    ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            Text("Add Members", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                  ),
                if (_selectedUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selected Members:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _selectedUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user['profile_image'] != null
                                    ? NetworkImage(user['profile_image'])
                                    : const AssetImage('assets/images/profile2.png') as ImageProvider,
                                backgroundColor: Colors.white,
                              ),
                              title: Text(user['username']),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedUsers.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: createBookClub,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF9B2226),
                      minimumSize: Size(double.infinity, 50),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Color(0xFFE07A5F).withOpacity(0.2); // Splash effect color
                          }
                          return null; // Default splash color
                        },
                      ),
                    ),
                    child: const Text("Create", style: TextStyle(color: Colors.white)),
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