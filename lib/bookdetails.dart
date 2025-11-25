import 'package:book_voyage_demo/audiobook.dart';
import 'package:book_voyage_demo/payment_services.dart';
import 'package:book_voyage_demo/webPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'openbook.dart';

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
  bool showReadMore = false;
  num averageRating = 0.0;
  int ratingCount = 0;
  int bookPrice = 0;
  String userId = "";
  String userEmail = "";
  String? previewUrl;
  String? pdfUrl;
  Map<String, dynamic>? bookData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PaymentService _paymentService = PaymentService();
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
    _fetchUserDetails();
    _checkIfPurchased();
    _checkIfFavorite();
  }
  Future<void>_fetchBookDetails() async {
    DocumentSnapshot bookSnapshot=await _firestore.collection('books').doc(widget.bookId).get();
    if(bookSnapshot.exists){
      setState(() {
        bookData=bookSnapshot.data() as Map<String, dynamic>;
        previewUrl = bookData?['previewLink'];
        pdfUrl=bookData?['pdf_url'];
        isFree = bookData?['isfree'] ?? false;
        averageRating=bookData?['rating']??0.0;
        ratingCount = bookSnapshot['ratingCount'] ?? 0;
        bookPrice=bookData?['price'];
      });
      _checkIfFavorite();
      _checkIfPurchased();
      _animationController.forward();
    }
  }
  void _fetchUserDetails() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        userId = currentUser.uid;
      });

      var userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userSnapshot.exists) {
        setState(() {
          userEmail = userSnapshot.data()?['email'] ?? "";
        });
      }
    }
  }
  void openAudiobookPage() {
    String uid = _auth.currentUser?.uid ?? "";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudiobookTTSPage(
          bookId: widget.bookId,
          userId: uid,
        ),
      ),
    );
  }
  void _openBook() {
    if (pdfUrl != null && pdfUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
              pdfStoragePath: pdfUrl!,
              bookId: widget.bookId,
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: "PDF not available for this book.",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
  void _openPreview() {
    if (previewUrl != null && previewUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookPreviewWebView(previewUrl: previewUrl!),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: "No preview available for this book.",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
      );
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
    if (purchaseSnapshot.exists) {
      var data = purchaseSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('isPurchased') && data['isPurchased'] == true) {
        setState(() {
          isPurchased = true;
        });
      }
    }
  }
  void _handlePaymentSuccess() {
    setState(() {
      isPurchased = true;
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
      stars.add(Icon(Icons.star, color: Colors.amber[400], size: 26.0));
    }

    // Add half star
    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.amber[400], size: 26.0));
    }

    while (stars.length < 5) {
      stars.add(Icon(Icons.star_border, color: Colors.amber[400], size: 26.0));
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
                                    const SizedBox(height: 10,),
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFF8F0E3),
                                      child: IconButton(
                                        icon: Icon(
                                          isFavorite ? Icons.favorite: Icons.favorite_border,
                                          color: isFavorite? Colors.red : Colors.black,
                                        ),
                                        onPressed: ()async{
                                          if(isFavorite){
                                           await removeFromFavorites();
                                           Fluttertoast.showToast(
                                             msg: "Removed from Shelf",
                                             toastLength: Toast.LENGTH_SHORT,
                                             backgroundColor: Color(0xFFECE2D0).withOpacity(0.9),
                                             textColor:Colors.black,
                                             fontSize: 16.0,
                                           );
                                          }
                                          else{
                                            await addToFavorites();
                                            Fluttertoast.showToast(
                                              msg: "Added to Shelf",
                                              toastLength: Toast.LENGTH_SHORT,
                                              backgroundColor: Color(0xFFECE2D0).withOpacity(0.9),
                                              textColor:Colors.black,
                                              fontSize: 16.0,
                                            );
                                          }
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                          decoration: BoxDecoration(
                            color:Color(0xFFECE2D0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Ensures minimal vertical space is used
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min, // Ensures Row takes minimal space
                                  mainAxisAlignment: MainAxisAlignment.center, // Centers the stars
                                  children: _buildStarRating(averageRating),
                                ),
                                Text('$averageRating',style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
                                const SizedBox(height: 5),
                                Text(
                                  "($ratingCount ratings)",
                                  style: const TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20,),
                      InkWell(
                        onTap: (){
                          _openPreview();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:Color(0xFF9B2226),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Ensures minimal vertical space is used
                              children: [
                                 Padding(
                                   padding: const EdgeInsets.all(8.0),
                                   child: Image.asset('assets/images/books.png',height: 26,),
                                 ),
                                const Padding(
                                  padding: EdgeInsets.only(top:2, bottom: 8, right: 8,left: 8),
                                  child: Text('Preview', style: TextStyle(color:Color(0xFFECE2D0),fontSize: 14, fontWeight: FontWeight.bold),),
                                ),
                              ],
                            ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
                                  builder: (context, constraints){
                                    final span = TextSpan(
                                      text: bookData?['description'] ?? 'No description available.',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                    final textPainter = TextPainter(
                                      text: span,
                                      maxLines: 10,
                                      textDirection: TextDirection.ltr,
                                    );
                                    textPainter.layout(maxWidth: constraints.maxWidth);
                                    showReadMore = textPainter.didExceedMaxLines;
                                    return Text(
                                      bookData?['description'] ?? 'No description available.',
                                      maxLines: isExpanded ? null : 10,
                                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                              ),
                              if (showReadMore)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isExpanded = !isExpanded;
                                    });
                                  },
                                  child: Text(
                                    isExpanded ? "Read Less" : "Read More..",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9B2226),
                                    ),
                                  ),
                                ),
                            ],
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
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   if (!isFree && !isPurchased)
                     Expanded(
                       child: ElevatedButton(
                         onPressed: (){
                           _paymentService.processPayment(
                               context: context,
                               userId: userId,
                               userEmail: userEmail,
                               bookId: widget.bookId,
                               price: bookPrice,
                               onSuccess: _handlePaymentSuccess,
                           );
                         },
                         style: ElevatedButton.styleFrom(
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                           backgroundColor: Color(0xFF9B2226),
                           minimumSize: Size(double.infinity, 50), // Full-width button
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
                         child: const Text("Buy Now", style: TextStyle(color: Colors.white),),
                       ),
                     ),
                   if (isPurchased || isFree)
                     Expanded(
                       child: Padding(
                         padding: const EdgeInsets.only(right: 4.0),
                         child: ElevatedButton.icon(
                           onPressed: _openBook,
                           icon: const Icon(Icons.book, color: Colors.white),
                           label: const Text("Read Book",style: TextStyle(color: Colors.white) ),
                           style: ElevatedButton.styleFrom(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                             padding: EdgeInsets.symmetric(vertical: 16),
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
                         ),
                       ),
                     ),
                   if (isFree || isPurchased)
                     Expanded(
                       child: Padding(
                         padding: const EdgeInsets.only(left: 4.0),
                         child: ElevatedButton.icon(
                           onPressed: openAudiobookPage,
                           icon: const Icon(Icons.headphones, color: Colors.white),
                           label: const Text("Audio Book", style: TextStyle(color: Colors.white),),
                           style: ElevatedButton.styleFrom(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                             padding: EdgeInsets.symmetric(vertical: 16),
                             backgroundColor: Color(0xFF9B2226)
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