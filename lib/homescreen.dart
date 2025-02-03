import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'drawer.dart';

class HomeScreen extends StatefulWidget{
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent ,
      body: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('books').limit(10).snapshots(),
          builder: (context, snapshot){
            if(snapshot.connectionState==ConnectionState.waiting)
              {
                return Center(child: CircularProgressIndicator());
              }
            if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
              return Center(child: Text('No books available'));
            }
            final books=snapshot.data!.docs.map((doc){
              return{
                'title': doc.get('title') ?? 'Unknown Title',
                'author':(doc.get('authors') as List<dynamic>).join(', '),
                'cover_url': doc.get('thumbnail') ?? Image.asset("assets/images/book.png")
              };
            }).toList();
            return CarouselSlider(
                items: books.map((book){
                  return Container(
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
                          SizedBox(height: 10,),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              book['cover_url']!,
                              height: 250,
                              width: 170,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 10,),
                          Text(
                            book['title']!,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10,),
                          Text(
                            book['author']!,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
          }
      )
    );
  }
}