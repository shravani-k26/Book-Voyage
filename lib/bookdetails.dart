import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookDetailsPage extends StatefulWidget{
  final String bookId;
  const BookDetailsPage({super.key, required this.bookId});
  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isFavorite = false;
  bool isPurchased = false;
  bool isFree=true;
  bool isExpanded = false;
  num averageRating = 0.0;
  int ratingCount = 0;
  Map<String, dynamic>? bookData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  @override
  void initState(){
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this ,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchBookDetails();
  }
  Future<void>_fetchBookDetails()async{
    DocumentSnapshot bookSnapshot=await _firestore.collection('books').doc(widget.bookId).get();
    if(bookSnapshot.exists){
      setState(() {
        bookData=bookSnapshot.data() as Map<String, dynamic>;
        isFree = bookData?['isfree'] ?? false;
        averageRating=bookData?['rating']??0.0;
        ratingCount = bookSnapshot['ratingCount'] ?? 0;
      });
      _checkIfFavorite();
      _checkIfPurchased();
      _animationController.forward();
    }
  }
  void _checkIfFavorite() async{
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    DocumentSnapshot favoriteSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.bookId) // Check if this book exists in favorites
        .get();
    setState(() {
      isFavorite = favoriteSnapshot.exists;
    });
  }

  void _checkIfPurchased() async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    DocumentSnapshot purchaseSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc(widget.bookId)
        .get();
    setState(() {
      isPurchased = purchaseSnapshot.exists;
    });
  }
  Future<void> addToFavorites() async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.bookId)
        .set({}); // Empty data, as we only care about existence

    setState(() {
      isFavorite = true;
    });
  }
  Future<void> removeFromFavorites() async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.bookId)
        .delete();

    setState(() {
      isFavorite = false;
    });
  }
  List<Widget> _buildStarRating(num averageRating) {
    int fullStars = averageRating.floor(); // Full stars based on averageRating
    bool hasHalfStar = (averageRating - fullStars) >= 0.5;

    List<Widget> stars = [];

    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.amber[300], size: 26.0));
    }

    // Add half star if necessary
    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.amber[300], size: 26.0));
    }

    // Fill remaining stars with empty outline
    while (stars.length < 5) {
      stars.add(Icon(Icons.star_border, color: Colors.amber[300], size: 26.0));
    }

    return stars;
  }
  @override
  Widget build(BuildContext context) {
    if(bookData==null)
    {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    List<dynamic> authors = bookData!['authors'] ?? [];
    String authorsText = authors.join(", ");
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: Color(0xFFE8A391),
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
              ],),// Ch
            backgroundColor: Colors.transparent,
            title: Text(bookData?['title'] ?? 'Book Details', style:const TextStyle(
                fontSize:25, color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),])),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _fadeAnimation.value,
                                      child:Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16.0),
                                          border: Border.all(
                                            color: Color(0xFFECE2D0),
                                            width: 2.0,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16.0),
                                          child: Image.network(
                                            bookData?['thumbnail'],
                                            width: 120,
                                            height: 180,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  );
                                }
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookData?['title'] ?? 'No title',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Author: ${authorsText ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: Color(0xFFECE2D0).withOpacity(0.5),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Ensures minimal vertical space is used
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min, // Ensures Row takes minimal space
                                  mainAxisAlignment: MainAxisAlignment.center, // Centers the stars
                                  children: _buildStarRating(averageRating),
                                ),
                                Text('$averageRating',style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w400),),
                                const SizedBox(height: 8),
                                Text(
                                  "($ratingCount ratings)",
                                  style: const TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Divider(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('BOOK DESCRIPTION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Divider(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height:10),
                      Container(
                        decoration: BoxDecoration(
                         color:  const Color(0xFFECE2D0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            bookData?['description'] ?? 'No description available.',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          bottomNavigationBar: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   if (!isFree && !isPurchased)
                     Expanded(
                       child: ElevatedButton(
                         onPressed: (){},
                         child: const Text("Buy Now"),
                         style: ElevatedButton.styleFrom(
                           minimumSize: Size(double.infinity, 50), // Full-width button
                         ),
                       ),
                     ),
                   if (isPurchased || isFree)
                     Expanded(
                       child: Padding(
                         padding: const EdgeInsets.only(right: 4.0),
                         child: ElevatedButton.icon(
                           onPressed: (){},
                           icon: const Icon(Icons.book, color: Colors.white),
                           label: const Text("Read Book",style: TextStyle(color: Colors.white) ),
                           style: ElevatedButton.styleFrom(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                             padding: EdgeInsets.symmetric(vertical: 16),
                             backgroundColor: Color(0xFF9B2226),
                           ),
                         ),
                       ),
                     ),
                   if (isFree || isPurchased)
                     Expanded(
                       child: Padding(
                         padding: const EdgeInsets.only(left: 4.0),
                         child: ElevatedButton.icon(
                           onPressed: (){},
                           icon: const Icon(Icons.headphones, color: Colors.white),
                           label: const Text("Audio Book", style: TextStyle(color: Colors.white),),
                           style: ElevatedButton.styleFrom(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                             padding: EdgeInsets.symmetric(vertical: 16),
                             backgroundColor: Color(0xFF9B2226)
                           ),
                         ),
                       ),
                     ),
                 ],
               ),
           ),
          ),
        ),
        );
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}