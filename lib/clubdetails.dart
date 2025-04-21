import 'dart:io';

import 'package:book_voyage_demo/selectusers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class BookClubDetailsPage extends StatefulWidget {
  final String clubId;

  BookClubDetailsPage({required this.clubId});

  @override
  _BookClubDetailsPageState createState() => _BookClubDetailsPageState();
}

class _BookClubDetailsPageState extends State<BookClubDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, dynamic>? clubData;
  String? userId;
  bool isLoading = true;

  List<Map<String, dynamic>> _selectedUsers = [];
  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
    _fetchBookClubDetails();
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
    if (selectedUsers != null  && selectedUsers.isNotEmpty) {
      setState(() {
        _selectedUsers = selectedUsers;
      });
    }
      //Handle the addition of selected members
      _addMembersToClub(_selectedUsers);
  }
  Future<void> _addMembersToClub(List<Map<String, dynamic>> selectedUsers) async {
    try {
      DocumentSnapshot clubDoc = await FirebaseFirestore.instance.collection('bookClubs').doc(widget.clubId).get();
      Map<String, dynamic>? clubData = clubDoc.data() as Map<String, dynamic>?;
      List<dynamic> currentMembers = clubData?['members'] ?? [];
      for (var user in selectedUsers) {
        if (!currentMembers.contains(user['id'])) {
          await FirebaseFirestore.instance.collection('bookClubs').doc(
              widget.clubId).update({
            'members': FieldValue.arrayUnion([user['id']]),
            'membersCount': FieldValue.increment(1),
          });
          await FirebaseFirestore.instance.collection('users').doc(user['id']).update({
            'joinedClubs': FieldValue.arrayUnion([widget.clubId]),
          });
        }
      }
      // After adding members, refresh the member list
      _fetchBookClubDetails();
    } catch (e) {
      print("Error adding members: $e");
    }
  }
  Future<void> _fetchBookClubDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookClubs')
          .doc(widget.clubId)
          .get();
      setState(() {
        clubData = snapshot.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching club details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userSnapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error fetching user details for $userId: $e");
      return null;
    }
  }
  Future<void> leaveClub() async {
    if (clubData == null) return;
    List<dynamic> members = clubData!['members'] ?? [];
    if (!members.contains(userId)) return;

    try {
      await _firestore.collection('bookClubs').doc(widget.clubId).update({
        'members': FieldValue.arrayRemove([userId]),
        'membersCount': FieldValue.increment(-1),
      });
      await _firestore.collection('users').doc(userId).update({
        'joinedClubs': FieldValue.arrayRemove([widget.clubId]),
      });

      Fluttertoast.showToast(msg: "You have left the club.");
      Navigator.pop(context);
    } catch (e) {
      print("Error leaving club: $e");
      Fluttertoast.showToast(msg: "Failed to leave club.");
    }
  }
  Future<void> deleteClub() async {
    if (clubData == null) return;
    if (clubData!['creatorId'] != userId) return;

    try {
      List<dynamic> members = clubData!['members'] ?? [];
      for (String member in members) {
        await _firestore.collection('users').doc(member).update({
          'joinedClubs': FieldValue.arrayRemove([widget.clubId]),
        });
      }

      await _firestore.collection('users').doc(userId).update({
        'createdClubs': FieldValue.arrayRemove([widget.clubId]),
      });

      final messagesRef = _firestore
          .collection('bookClubs')
          .doc(widget.clubId)
          .collection('messages');

      final messagesSnapshot = await messagesRef.get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('bookClubs').doc(widget.clubId).delete();

      Fluttertoast.showToast(msg: "Book club deleted.");
      Navigator.pop(context);
    } catch (e) {
      print("Error deleting club: $e");
      Fluttertoast.showToast(msg: "Failed to delete club.");
    }
  }

  Future<void> _removeMember(String memberId) async {
    if (clubData == null) return;
    if (clubData!['creatorId'] != userId) return;

    try {
      await _firestore.collection('bookClubs').doc(widget.clubId).update({
        'members': FieldValue.arrayRemove([memberId]),
        'membersCount': FieldValue.increment(-1), // Decrease member count
      });

      await _firestore.collection('users').doc(memberId).update({
        'joinedClubs': FieldValue.arrayRemove([widget.clubId]),
      });

      Fluttertoast.showToast(msg: "Member removed.");
      _fetchBookClubDetails();
    } catch (e) {
      print("Error removing member: $e");
      Fluttertoast.showToast(msg: "Failed to remove member.");
    }
  }
  Future<void> uploadProfilePicture(String clubId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      String fileName = "club_$clubId.jpg";
      try {
        TaskSnapshot uploadTask = await _storage.ref('clubImages/$fileName').putFile(file);
        String downloadUrl = await uploadTask.ref.getDownloadURL();
        await _firestore.collection('bookClubs').doc(clubId).update({
          'clubImageUrl': downloadUrl,
        });
        Fluttertoast.showToast(msg: "Image uploaded successfully");
        setState(() {}); // Refresh UI
      } catch (e) {
        print("Error uploading profile picture: $e");
        Fluttertoast.showToast(msg: "Image cannot be uploaded");
      }
    }
  }
  void _showEditClubDialog() {
    final TextEditingController nameController = TextEditingController(text: clubData?['name'] ?? '');
    final TextEditingController descController = TextEditingController(text: clubData?['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Club Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Club Name',
                  labelStyle: TextStyle(
                    color: Color(0xFFE07A5F), // Set your desired label color here
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: descController,
                decoration: InputDecoration(labelText: 'Description',
                  labelStyle: TextStyle(
                      color: Color(0xFFE07A5F),// Set your desired label color here
                  ),
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',style: TextStyle(color: Color(0xFFE07A5F),),),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newDesc = descController.text.trim();

              if (newName.isNotEmpty && newDesc.isNotEmpty) {
                await _updateClubDetails(newName, newDesc);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9B2226),
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
            child: Text('Save', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }
  Future<void> _updateClubDetails(String newName, String newDesc) async {
    final clubDoc = FirebaseFirestore.instance.collection('bookClubs').doc(widget.clubId);

    Map<String, dynamic> updatedFields = {};

    if (newName.isNotEmpty && newName != clubData?['clubName']) {
      updatedFields['name'] = newName;
    }

    if (newDesc.isNotEmpty && newDesc != clubData?['clubDescription']) {
      updatedFields['description'] = newDesc;
    }

    if (updatedFields.isEmpty) {
      Fluttertoast.showToast(
          msg: "No changes to update.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
      );
      return;
    }
    try {
      await clubDoc.update(updatedFields);
      Fluttertoast.showToast(
        msg: "Club details updated successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      _fetchBookClubDetails(); // Refresh the data
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update club details: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void showImageDialog(String clubId, String imageUrl) {
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
                  return const Center(child: CircularProgressIndicator());
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
                    uploadProfilePicture(clubId);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFECE2D0),
          title: const Text("Book Club Details"),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditClubDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Club Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : clubData == null
            ? Center(child: Text("Failed to load book club details."))
            : ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Book Club Image
            Center(
              child: GestureDetector(
                onTap: ()=> showImageDialog(widget.clubId, clubData!['clubImageUrl']),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: clubData!['clubImageUrl'] != null
                      ? NetworkImage(clubData!['clubImageUrl'])
                      : AssetImage('assets/images/group.jpg') as ImageProvider,
                ),
              ),
            ),
            SizedBox(height: 16), // Book Club Name
            Center(
              child: Text(
                clubData!['name'] ?? 'N/A',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Total Members: ${(clubData!['members'] as List<dynamic>?)?.length ?? 0}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if(userId == clubData?['creatorId'])
              Column(
                children: [
                  const SizedBox(height: 16,),
                  ElevatedButton(
                    onPressed: _navigateToSelectUsersPage,
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Color(0xFF9B2226),
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
                        Icon(Icons.add, color: Colors.white,),
                        Text("Add Member", style: TextStyle(color: Colors.white),),
                      ],
                    ),
                  )
                ],
              ),
            const SizedBox(height: 24,),
            const Text(
              "Members",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (clubData!['members'] as List<dynamic>?)?.length ?? 0,
              itemBuilder: (context, index) {
                String memberID = clubData!['members'][index];
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUserDetails(memberID),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text("Loading..."),
                      );
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return const ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage('assets/images/group.jpg'),
                        ),
                        title: Text("Unknown Member"),
                      );
                    }
                    final userData = snapshot.data!;
                    String memberName = userData['username'] ?? 'Unknown';
                    String memberImage = userData['profile_image'] ?? '';
      
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: memberImage.isNotEmpty
                            ? NetworkImage(memberImage)
                            : AssetImage('assets/images/group.jpg') as ImageProvider,
                      ),
                      title: Row(
                        children: [
                          Text(memberName,style: TextStyle(fontWeight: FontWeight.bold), ),
                          if (userId == clubData!['creatorId'] && memberID == clubData!['creatorId'])
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE07A5F),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Creator',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: userId==clubData!['creatorId'] && memberID != clubData!['creatorId']
                                ? IconButton(
                                    icon: Icon(Icons.remove_circle, color: const Color(0xFF9B2226),),
                                    onPressed: () => _removeMember(memberID),
                        )
                          : null
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            if(userId!=null)
              Center(
                child: ElevatedButton(
                    onPressed: (){
                      if (userId == clubData?['creatorId']) {
                        deleteClub();
                      } else {
                        leaveClub();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: userId == clubData?['creatorId']
                        ? Color(0xFF9B2226)
                        : Color(0xFF9B2226)
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
                    child: Text(
                      userId == clubData?['creatorId']
                          ? "Delete Club"
                          : "Leave Club",
                      style: const TextStyle(color: Colors.white),
                    ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
