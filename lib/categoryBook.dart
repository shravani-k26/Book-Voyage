import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:book_voyage_demo/bookdetails.dart';

class CategoryBooksPage extends StatefulWidget{
  final String category;
  const CategoryBooksPage({super.key, required this.category});
  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  late Stream<QuerySnapshot> _booksStream;
  @override
  void initState(){
    super.initState();
    _booksStream = FirebaseFirestore.instance
        .collection('books')
        .where('genre', arrayContains: widget.category)
        .snapshots();
  }
  @override
  Widget build(BuildContext context) {
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
            title:Text("${widget.category} Books", style: const TextStyle(
                fontSize:25, color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),]),),
          ),
          body: StreamBuilder<QuerySnapshot>(
              stream: _booksStream,
              builder: (context, snapshot){
                if(snapshot.connectionState==ConnectionState.waiting){
                  return Center(child: CircularProgressIndicator());
                }
                if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
                  return Center(child: Text("No books found in this category."));
                }
                var books = snapshot.data!.docs;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index){
                        var book=books[index];
                        return GestureDetector(
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsPage(
                                  bookId: book.id, // Pass book document ID
                                ),
                              ),
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
                                )
                              ],
                            ),
                          ),
                        );
                      }
                  ),
                );
              }
          ),
        ),
      ),
    );
  }
}