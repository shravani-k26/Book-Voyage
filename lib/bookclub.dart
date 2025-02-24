import 'dart:io';
import 'package:book_voyage_demo/bookclubchat.dart';
import 'package:book_voyage_demo/createbookclub.dart';
import 'package:book_voyage_demo/searchbookclub.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class BookClubListPage extends StatefulWidget {
  final String userId;
  const BookClubListPage({super.key, required this.userId});

  @override
  State<BookClubListPage> createState() => _BookClubListPageState();
}

class _BookClubListPageState extends State<BookClubListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isLoading = true;
  List<String> _allClubIds = [];

  @override
  void initState() {
    super.initState();
    _fetchUserClubs();
  }

  void _fetchUserClubs() async {
    DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(widget.userId).get();
    if (userSnapshot.exists) {
      var userData = userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _allClubIds = [
          ...List<String>.from(userData['joinedClubs'] ?? []),
          ...List<String>.from(userData['createdClubs'] ?? []),
        ];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
  Stream<List<Map<String, dynamic>>> fetchUserClubs() {
    if (_allClubIds.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('bookClubs')
        .where(FieldPath.documentId, whereIn: _allClubIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return {
        "id": doc.id,
        "name": doc['name'],
        "clubImageUrl": doc.get('clubImageUrl') ?? "",
        "description": doc['description'],
        "creatorId": doc['creatorId'],
      };
    }).toList());
  }
  Future<void> deleteBookClub(String clubId) async {
    try {
      await _firestore.collection('bookClubs').doc(clubId).delete();
      QuerySnapshot userSnapshots = await _firestore.collection('users').get();
      for (var user in userSnapshots.docs) {
        await _firestore.collection('users').doc(user.id).update({
          'joinedClubs': FieldValue.arrayRemove([clubId]),
          'createdClubs': FieldValue.arrayRemove([clubId]),
        });
      }
      await _storage.ref('clubImages/club_$clubId.jpg').delete();
      _fetchUserClubs();
      Fluttertoast.showToast(msg: "Book club deleted successfully.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting club: $e");
    }
  }

  Future<void> leaveBookClub(String clubId) async {
    DocumentSnapshot clubSnapshot = await _firestore.collection('bookClubs').doc(clubId).get();
    if (clubSnapshot.exists) {
      var clubData = clubSnapshot.data() as Map<String, dynamic>;
      List<String> members = List<String>.from(clubData['members'] ?? []);
      if (members.length == 1 && members.contains(widget.userId)) {
        await deleteBookClub(clubId);
      } else {
        await _firestore.collection('bookClubs').doc(clubId).update({
          'members': FieldValue.arrayRemove([widget.userId]),
          'memberCount': FieldValue.increment(-1),
        });
        await _firestore.collection('users').doc(widget.userId).update({
          'joinedClubs': FieldValue.arrayRemove([clubId]),
        });
        Fluttertoast.showToast(msg: "You left the club");
        _fetchUserClubs();
      }
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
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xFFE8A391),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allClubIds.isEmpty
              ? const Center(child: Text("You haven't joined or created any book clubs yet."))
              : StreamBuilder(
            stream: fetchUserClubs(),
            builder: (context, clubSnapshot) {
              if (clubSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (clubSnapshot.hasError) {
                return const Center(child: Text("An error occurred. Please try again later."));
              }
              if (!clubSnapshot.hasData || clubSnapshot.data!.isEmpty) {
                return const Center(child: Text("No book clubs found."));
              }
              List<Map<String, dynamic>> clubs = clubSnapshot.data!;
              return ListView.builder(
                itemCount: clubs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: const Color(0xFFECE2D0),
                      child: ListTile(
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context)=>BookClubChatPage(clubId: clubs[index]['id'], clubName: clubs[index]['name'], clubImageUrl: clubs[index]['clubImageUrl'],))
                          );
                        },
                        leading: GestureDetector(
                          onTap: () => showImageDialog(clubs[index]['id'], clubs[index]['clubImageUrl']),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: clubs[index]['clubImageUrl'] != ""
                                ? NetworkImage(clubs[index]['clubImageUrl'])
                                : null,
                            backgroundColor: const Color(0xFFECE2D0),
                            child: clubs[index]['clubImageUrl'] == ""
                                ? const Icon(Icons.group, color: Colors.white)
                                : null,
                          ),
                        ),
                        title: Text(clubs[index]['name']),
                        subtitle: Text(clubs[index]['description']),
                        trailing: PopupMenuButton(
                            onSelected: (value){
                              if(value=='delete'){
                                deleteBookClub(clubs[index]['id']);
                              }else if(value=='leave'){
                                leaveBookClub(clubs[index]['id']);
                              }
                            },
                            itemBuilder: (context) =>[
                              if (clubs[index]['creatorId'] == widget.userId)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text("Delete Club"),
                                )
                              else
                                const PopupMenuItem(
                                  value: 'leave',
                                  child: Text("Leave Club"),
                                ),
                            ]
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFFECE2D0),
                  heroTag: 'Search',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchBookClubPage(userId: widget.userId)),
                    ).then((_) => _fetchUserClubs());
                  },
                  tooltip: "Search Book Clubs",
                  child: const Icon(Icons.search_sharp, color: Color(0xFF9B2226) ),
                ),
              ),
              FloatingActionButton(
                backgroundColor: Color(0xFFECE2D0),
                heroTag: 'Create',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateBookClubPage(userId: widget.userId)),
                  ).then((_) => _fetchUserClubs());
                },
                tooltip: "Create New Book Club",
                child: const Icon(Icons.add, color: Color(0xFF9B2226),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
