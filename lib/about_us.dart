import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
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
          backgroundColor: Color(0xFFE07A5F),
            title: const Text('About Us',style:TextStyle(
                fontSize:25, color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),]))
        ),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome to Book Voyage 👋',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      "We're here to make reading fun, easy, and social. Whether you're into flipping through eBooks or listening on the go, we’ve got you covered.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blue[50],
              elevation: 4,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What You Can Do 🚀',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 10),
                    Text("• Read and listen to a variety of books\n"
                        "• Use Text-to-Speech for hands-free enjoyment\n"
                        "• Join or create book clubs\n"
                        "• Chat with fellow readers"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Thanks for being part of our journey. Let’s keep reading and sharing stories together. ❤️\n\n– The Book Voyage Team",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
