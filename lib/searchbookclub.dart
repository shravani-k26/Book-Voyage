import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SearchBookClubPage extends StatefulWidget {
  final String userId;

  SearchBookClubPage({required this.userId});

  @override
  _SearchBookClubPageState createState() => _SearchBookClubPageState();
}

class _SearchBookClubPageState extends State<SearchBookClubPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _searchResults = [];
  List<QueryDocumentSnapshot> _recommendedClubs = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      searchClubs(_searchController.text);
    });
    fetchRecommendedClubs();
  }

  /// Fetch recommended book clubs (e.g., most popular)
  Future<void> fetchRecommendedClubs() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookClubs')
          .orderBy('membersCount', descending: true) // Most popular clubs
          .limit(5)
          .get();

      setState(() {
        _recommendedClubs = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching recommended clubs: $e")),
      );
    }
  }

  /// Search book clubs based on user input
  Future<void> searchClubs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false; // Show recommended clubs
      });
      return;
    }

    setState(() {
      _isSearching = true; // Hide recommended clubs
    });

    try {
      QuerySnapshot snapshot = await _firestore.collection('bookClubs').get();

      setState(() {
        _searchResults = snapshot.docs.where((doc) {
          String name = doc['name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching search results: $e")),
      );
    }
  }

  /// Join a book club
  Future<void> joinClub(String clubId) async {
    DocumentSnapshot clubSnapshot = await _firestore.collection('bookClubs').doc(clubId).get();
    List members = clubSnapshot['members'] ?? [];

    if (members.contains(widget.userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You are already a member of this club!")),
      );
      return;
    }

    await _firestore.collection('bookClubs').doc(clubId).update({
      'members': FieldValue.arrayUnion([widget.userId]),
      'membersCount': FieldValue.increment(1),
    });

    await _firestore.collection('users').doc(widget.userId).update({
      'joinedClubs': FieldValue.arrayUnion([clubId]),
    });

    Fluttertoast.showToast(msg: "Successfully joined the club!");
    Navigator.pop(context);
  }

  /// UI Layout
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
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(
              size: 30,
              color: Color(0xFFECE2D0),
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black45,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
            title: const Text(
              "Search Book Clubs",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF8F0E3),
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search",
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),

                // Display Recommended Clubs if not searching
                if (!_isSearching && _recommendedClubs.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recommended Clubs",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _recommendedClubs.length,
                        itemBuilder: (context, index) {
                          var club = _recommendedClubs[index];
                          String imageUrl = club['clubImageUrl'] ?? '';
                          return buildClubCard(club, imageUrl);
                        },
                      ),
                    ],
                  ),

                // Display Search Results
                // Display Search Results or No Results Found
                if (_isSearching)
                  _searchResults.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        "No book clubs found",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var club = _searchResults[index];
                      String imageUrl = club['clubImageUrl'] ?? '';
                      return buildClubCard(club, imageUrl);
                    },
                  ),
              ],
              ),
            ),
          ),
      ),
    );
  }

  /// Helper function to build a club card
  Widget buildClubCard(QueryDocumentSnapshot club, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        color: const Color(0xFFECE2D0),
        child: ListTile(
          leading: imageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(50.0),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 50),
            ),
          )
              : Icon(Icons.image, size: 50),
          title: Text(club['name']),
          trailing: ElevatedButton(
            onPressed: () => joinClub(club.id),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(vertical: 10),
              backgroundColor: Color(0xFF9B2226),
            ),
            child: Text("Join", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
