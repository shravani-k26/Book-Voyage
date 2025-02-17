import 'dart:math';
import 'package:book_voyage_demo/bookdetails.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Text(
                'Most Popular Books on Book Voyage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('books').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No books available'));
                }
                List<Map<String, dynamic>> books = snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  data['book_id'] = doc.id;
                  return {
                    'title': data['title'] ?? 'Unknown Title',
                    'author': (data['authors'] as List<dynamic>).join(', '),
                    'cover_url': data['thumbnail'] ?? Image.asset("assets/images/book.png"),
                    'book_id': doc.id,
                  };
                }).toList();
                books.shuffle(Random());
                List<Map<String, dynamic>> randomBooks = books.take(10).toList();
                return CarouselSlider(
                  items: randomBooks.map((book) {
                    return GestureDetector(
                      onTap: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context)=>BookDetailsPage(bookId: book['book_id']!),
                            )
                        );
                      },
                      child: Container(
                        height: 500,
                        width: double.infinity,
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                          color: Color(0xFFECE2D0),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  book['cover_url']!,
                                  height: 250,
                                  width: 170,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/book.png',
                                      height: 250,
                                      width: 170,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                book['title']!,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                book['author']!,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 350,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 2 / 3,
                    enableInfiniteScroll: true,
                    autoPlayInterval: Duration(seconds: 4),
                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                  ),
                );
              },
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: widget.uid.isNotEmpty
                  ? _firestore.collection('users').doc(widget.uid).snapshots()
                  : null, // Prevents Firestore query when UID is empty
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return SizedBox.shrink();
                }
                var userDoc = snapshot.data!;
                List<String> interests = List<String>.from(userDoc['interests'] ?? []);
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('books').snapshots(),
                  builder: (context, bookSnapshot) {
                    if (!bookSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    List<Map<String, dynamic>> books = bookSnapshot.data!.docs.map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      data['book_id'] = doc.id;
                      return data;
                    }).where((book) {
                      List<String> bookGenres = List<String>.from(book['genre'] ?? []);
                      return bookGenres.any((genre) => interests.contains(genre));
                    }).toList();

                    books.shuffle(Random());
                    List<Map<String, dynamic>> recommendedBooks = books.take(10).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recommendedBooks.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                            child: Text(
                              'Recommended for You',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: recommendedBooks.map((book) {
                                List<String> authors = List<String>.from(book['authors'] ?? []);
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: (){
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context)=>BookDetailsPage(bookId: book['book_id'] )
                                              )
                                          );
                                        },
                                        child: Container(
                                          width: 100,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(book['thumbnail'] ?? ''),
                                              fit: BoxFit.cover,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          book['title'] ?? 'Unknown Title',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          authors.isNotEmpty ? authors.join(', ') : 'Unknown Author',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
               stream: _firestore.collection('trendingBooks').snapshots(),
               builder: (context, bookSnapshot){
                 if (!bookSnapshot.hasData) {
                   return Center(child: CircularProgressIndicator());
                 }
                 List<Map<String, dynamic>> books = bookSnapshot.data!.docs.map((doc) {
                   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                   data['book_id'] = doc.id;
                   return {
                     'title': data['title'] ?? 'Unknown Title',
                     'author': (data['authors'] as List<dynamic>).join(', '),
                     'cover_url': data['thumbnail'] ?? Image.asset("assets/images/book.png"),
                     'book_id': doc.id,
                   };
                 }).toList();
                 books.shuffle(Random());
                 List<Map<String, dynamic>> trendingBooks = books.take(5).toList();
                 return Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     if (trendingBooks.isNotEmpty) ...[
                       const Padding(
                         padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                         child: Text(
                           'Trending Books',
                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                         ),
                       ),
                       SingleChildScrollView(
                         scrollDirection: Axis.horizontal,
                         child: Row(
                           children: trendingBooks.map((book) {
                             return Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Column(
                                 children: [
                                   GestureDetector(
                                     onTap: (){
                                       Navigator.push(
                                           context,
                                           MaterialPageRoute(
                                               builder: (context)=>BookDetailsPage(bookId: book['book_id'] )
                                           )
                                       );
                                     },
                                     child: Container(
                                       width: 100,
                                       height: 150,
                                       decoration: BoxDecoration(
                                         image: DecorationImage(
                                           image: NetworkImage(book['cover_url'] ?? ''),
                                           fit: BoxFit.cover,
                                         ),
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                     ),
                                   ),
                                   SizedBox(height: 8),
                                   SizedBox(
                                     width: 120,
                                     child: Text(
                                       book['title'] ?? 'Unknown Title',
                                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                       maxLines: 1,
                                       overflow: TextOverflow.ellipsis,
                                       textAlign: TextAlign.center,
                                     ),
                                   ),
                                   SizedBox(
                                     width: 120,
                                     child: Text(
                                       book['author'],
                                       style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                       maxLines: 1,
                                       overflow: TextOverflow.ellipsis,
                                       textAlign: TextAlign.center,
                                     ),
                                   )
                                 ],
                               ),
                             );
                           }).toList(),
                         ),
                       ),
                     ],
                   ],
                 );
               }
           ),
            StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(widget.uid)
                    .collection('favorites')
                    .snapshots(),
                builder: (context, favoriteSnapshot){
                  if(!favoriteSnapshot.hasData){
                    return Center(child: CircularProgressIndicator());
                  }
                  List<String> favoriteBookIds = favoriteSnapshot.data!.docs
                      .map((doc) => doc.id)
                      .toList();
                  return StreamBuilder<QuerySnapshot>(
                      stream:  _firestore.collection('books').snapshots(),
                      builder: (context, bookSnapshot){
                        if(!bookSnapshot.hasData){
                          return Center(child: CircularProgressIndicator());
                        }
                        List<Map<String, dynamic>> favoriteBooks = bookSnapshot.data!.docs.map((doc) {
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          data['book_id'] = doc.id;
                          return data;
                        }).where((book) => favoriteBookIds.contains(book['book_id'])).toList();
                        favoriteBooks.shuffle(Random());
                        List<Map<String, dynamic>> fBooks = favoriteBooks.take(10).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fBooks.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                                child: Text(
                                  'Your Shelf',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: fBooks.map((book) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context)=>BookDetailsPage(bookId: book['book_id']),
                                                  )
                                              );
                                            },
                                            child: Container(
                                              width: 100,
                                              height: 150,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: NetworkImage(book['thumbnail'] ?? ''),
                                                  fit: BoxFit.cover,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              book['title'] ?? 'Unknown Title',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              book['authors']!=null
                                              ?(book['authors'] is List)
                                                ?(book['authors']as List<dynamic>).join(', ')
                                                :book['authors'].toString()
                                              :'Unknown Author',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        );
                      }
                  );
                }
            )
          ],
        ),
      ),
    );
  }
}
