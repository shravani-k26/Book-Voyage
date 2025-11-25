import 'package:book_voyage_demo/about_us.dart';
import 'package:book_voyage_demo/help.dart';
import 'package:book_voyage_demo/termsPage.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
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
            title: const Text('Settings',style:TextStyle(
                fontSize:25, color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),]))),
        body: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Terms and Conditions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TermsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
