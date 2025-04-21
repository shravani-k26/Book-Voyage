import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(iconTheme: const IconThemeData(
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
            title: const Text('Help',style:TextStyle(
                fontSize:25, color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),]))),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Need a hand? We’ve got you. Here’s a quick guide to help you get the most out of Book Voyage.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            helpCard("📖 Reading eBooks", [
              "Tap on any book to open it.",
              "Scroll up-down to turn pages.",
              "Your progress is saved automatically.",
            ], Colors.orange[50]!),
      
            helpCard("🎧 Listening to Audiobooks", [
              "Tap the play icon to start listening.",
              "Use skip to move pages.",
              "Adjust speed and pause as needed.",
            ], Colors.lightBlue[50]!),
      
            helpCard("📚 Joining Book Clubs", [
              "Browse clubs in the Book Club section.",
              "Tap 'Join' or create your own club.",
              "Club creators can manage members and discussions.",
            ], Colors.green[50]!),
      
            helpCard("💬 Chat & Discussion", [
              "Use the chat tab in any club to talk.",
              "Discuss books, share recommendations, and connect.",
            ], Colors.purple[50]!),
      
            helpCard("⚙️ Settings", [
              "Update profile, change password, and view policies.",
              "Find everything under the drawer menu.",
            ], Colors.grey[200]!),
            SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blue[50],
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Still stuck?\nNo worries. Reach out to us and we’ll help you out ASAP\n📩 Email: support@bookvoyage.app",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget helpCard(String title, List<String> points, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...points.map((p) => Text("• $p")).toList(),
          ],
        ),
      ),
    );
  }
}
