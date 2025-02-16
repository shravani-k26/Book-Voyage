import 'package:book_voyage_demo/categoryBook.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget{
  final ValueNotifier<String> searchQueryNotifier;
  const DiscoverPage({super.key, required this.searchQueryNotifier});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}
class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: Color(0xFFE8A391),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: ValueListenableBuilder<String>(
            valueListenable: widget.searchQueryNotifier,
            builder: (context, searchQuery, child) {
              if (searchQuery.isEmpty) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      categoryTile("Mystery", "assets/images/mystery.jpg"),
                      categoryTile("Romance", "assets/images/romantic.jpg"),
                      categoryTile("Self Help", "assets/images/self.jpg"),
                      categoryTile("Educational", "assets/images/educational.jpg"),
                      categoryTile("Adventure", "assets/images/adventure.jpg"),
                    ],
                  ),
                );
              } else {
                // Show Search Results when user types
                return StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('books').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No books found"));
                    }

                    var books = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      var title = data.containsKey('title') ? data['title'].toString().toLowerCase() : "";
                      var authors = data.containsKey('authors')
                          ? (data['authors'] as List<dynamic>).join(", ").toLowerCase()
                          : "";
                      return searchQuery.isEmpty || title.contains(searchQuery.toLowerCase()) || authors.contains(searchQuery.toLowerCase());
                    }).toList();

                    if (books.isEmpty) {
                      return Center(child: Text("No matching books found"));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        var data = books[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Material(
                            color: Color(0xFFECE2D0).withOpacity(0.7),
                            elevation: 4,
                            shadowColor: Colors.grey.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                                leading: Container(
                                  height: 150,
                                  child: Image.network(
                                    data['thumbnail'] ?? 'https://via.placeholder.com/50',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  data.containsKey('title') ? data['title'] : 'Unknown Title',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(data.containsKey('authors') ? (data['authors'] as List<dynamic>).join(", ") : "Unknown Author"),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

// Reusable widget for categories
  Widget categoryTile(String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategoryBooksPage(category: title)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFF8F0E3),
              width: 5,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.75,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(3.0, 3.0),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}