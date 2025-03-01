import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectUsersPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelectedUsers;

  SelectUsersPage({required this.initialSelectedUsers});

  @override
  _SelectUsersPageState createState() => _SelectUsersPageState();
}

class _SelectUsersPageState extends State<SelectUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _suggestedUsers = [];

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.initialSelectedUsers);
    _fetchSuggestedUsers(); // Fetch suggested users on page load
  }

  Future<void> _fetchSuggestedUsers() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await _firestore.collection('users').where(FieldPath.documentId, isNotEqualTo: currentUserId).limit(5).get();
      setState(() {
        _suggestedUsers = snapshot.docs.map((DocumentSnapshot doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'username': data['username'] ?? '',
            'fullname': data['fullname'] ?? '',
            'profile_image': data['profile_image'] ?? '',
          };
        }).toList();
      });
      print("Fetched suggested users: $_suggestedUsers");
    } catch (e) {
      print("Error fetching suggested users: $e");
    }
  }


  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    if (query.isEmpty) return [];
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'username': doc.get('username'),
        'fullname': doc.get('fullname'),
        'profile_image': doc.get('profile_image'),
      };
    }).toList();
  }

  void _toggleUserSelection(Map<String, dynamic> user) {
    setState(() {
      final existingUserIndex = _selectedUsers.indexWhere((u) => u['id'] == user['id']);
      if (existingUserIndex != -1) {
        _selectedUsers.removeAt(existingUserIndex);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
            ],),
          backgroundColor:  const Color(0xFFE07A5F),
          title: const Text(
              "Select Users",
            style: TextStyle(
                color: Color(0xFFF8F0E3),
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),]
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedUsers);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(hintText: "Search Users"),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
            if (_searchQuery.isEmpty && _suggestedUsers.isNotEmpty) // Show suggestions when no search is active
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Suggestions:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestedUsers.length,
                      itemBuilder: (context, index) {
                        var user = _suggestedUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                              backgroundImage: user['profile_image'] != null
                                  ? NetworkImage(user['profile_image'])
                                  : const AssetImage('assets/images/profile2.png') as ImageProvider,
                              backgroundColor: Colors.white,
                          ),
                          title: Text(user['username']),
                          subtitle: Text(user['fullname']),
                          trailing: Checkbox(
                            value: _selectedUsers.any((selectedUser) => selectedUser['id'] == user['id']),
                            onChanged: (value) => _toggleUserSelection(user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _searchUsers(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("An error occurred"));
                  }
                  List<Map<String, dynamic>> users = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                            backgroundImage: user['profile_image'] != null
                                ? NetworkImage(user['profile_image'])
                                : const AssetImage('assets/images/profile2.png') as ImageProvider,
                            backgroundColor: Colors.white,
                        ),
                        title: Text(user['username']),
                        subtitle: Text(user['fullname']),
                        trailing: Checkbox(
                          value: _selectedUsers.any((selectedUser) => selectedUser['id'] == user['id']),
                          onChanged: (value) => _toggleUserSelection(user),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
