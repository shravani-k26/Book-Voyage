import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
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
            title: const Text('Terms and Services',style:TextStyle(
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
              color: Colors.blue[50], // Light Blue Background for the introductory section
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "By using Book Voyage, you agree to the following terms and conditions. Please read carefully!",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            termsCard("1. Acceptance of Terms", [
              "By accessing and using Book Voyage, you accept and agree to be bound by these terms."
            ], Colors.lightBlue[100]!),
            termsCard("2. Account Responsibilities", [
              "You are responsible for maintaining your account and password.",
              "You agree to notify us immediately of any unauthorized use of your account."
            ], Colors.green[50]!),
            termsCard("3. Content", [
              "All eBooks and audiobooks are for personal use only.",
              "Do not copy, distribute, or modify content without permission."
            ], Colors.orange[50]!),
            termsCard("4. Privacy", [
              "We value your privacy. See our Privacy Policy for more details.",
              "Your personal information is never shared with third parties without consent."
            ], Colors.pink[50]!),
            termsCard("5. Book Clubs", [
              "You can create or join book clubs for discussions.",
              "Book Voyage is not responsible for club interactions."
            ], Colors.teal[50]!),
            termsCard("6. Payment and Refunds", [
              "Payment is required for premium content.",
              "Refunds are not typically provided, but support is available for issues."
            ], Colors.yellow[50]!),
            termsCard("7. Modifications to Service", [
              "We can change, suspend, or discontinue any part of the app.",
              "We will notify users of major changes to these Terms."
            ], Colors.purple[50]!),
            termsCard("8. Limitation of Liability", [
              "Book Voyage is not liable for any damages arising from your use of the app."
            ], Colors.grey[100]!),
            termsCard("9. Termination", [
              "Your access may be suspended or terminated for violating these terms."
            ], Colors.red[50]!),
            termsCard("10. Governing Law", [
              "These terms are governed by the laws of your country."
            ], Colors.blue[100]!),
            SizedBox(height: 12),
            Card(
              color: Colors.blue[50], // A consistent color for the contact section
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "For questions or concerns, reach us at support@bookvoyage.app",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget termsCard(String title, List<String> points, Color color) {
    return Card(
      color: color, // Use the color passed as an argument
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
