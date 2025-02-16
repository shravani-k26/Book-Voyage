import 'package:book_voyage_demo/bookdetails.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatefulWidget{
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> favoriteBooks = [];
  bool isLoading = true;
  @override
  void initState(){
    super.initState();
    _fetchFavorites();
  }
  Future<void>_fetchFavorites() async{
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    QuerySnapshot favoritesSnapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .get();

    List<Map<String, dynamic>> books = [];
    for(var favorite in favoritesSnapshot.docs){
      DocumentSnapshot bookSnapshot = await _firestore
          .collection('books')
          .doc(favorite.id)
          .get();
      if(bookSnapshot.exists){
        Map<String, dynamic> bookData = bookSnapshot.data() as Map<String, dynamic>;
        bookData['id'] = bookSnapshot.id;
        books.add(bookData);
      }
    }
    setState(() {
      favoriteBooks = books;
      isLoading = false;
    });
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
              ]
            ),
            title: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Your Shelf',
                style:TextStyle(
                    fontSize:25, color: Color(0xFFF8F0E3),
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),]) ,
              ),
            ),
          ),
          body: isLoading
          ? const Center(
            child: CircularProgressIndicator(),
          )
              :favoriteBooks.isEmpty
            ? const Center(child: Text('Your shelf is empty'))
              :Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                itemCount: favoriteBooks.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 15.0,
                    childAspectRatio: 0.6,
                ),
                            itemBuilder: (context, index){
                  final book=favoriteBooks[index];
                  return GestureDetector(
                    onTap: (){
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context)=>BookDetailsPage(bookId: book['id']),
                          )
                      );
                    },
                    child: Card(
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(book['thumbnail'],
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              book['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  },
                ),
              )
        )
      ),
    );
  }
}