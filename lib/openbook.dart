import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfStoragePath;
  final String bookId;

  const PdfViewerPage({super.key, required this.pdfStoragePath, required this.bookId});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int currentPageIndex = 0;
  List<int> bookmarks = [];
  String? localPdfPath;
  PDFViewController? pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
    _loadBookmarks();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.pdfStoragePath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp.pdf');
      await ref.writeToFile(tempFile);
      setState(() {
        localPdfPath = tempFile.path;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading PDF");
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      if (bookmarks.contains(currentPageIndex)) {
        bookmarks.remove(currentPageIndex);
        Fluttertoast.showToast(msg: "Bookmark Removed!");
      } else {
        bookmarks.add(currentPageIndex);
        Fluttertoast.showToast(msg: "Bookmark Added!");
      }
      if (bookmarks.isEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bookmarks')
            .doc(widget.bookId)
            .delete();
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bookmarks')
            .doc(widget.bookId)
            .set({'bookmarks': bookmarks, 'timestamp': FieldValue.serverTimestamp()});
      }
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: "Error toggling bookmark");
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(widget.bookId)
          .get();
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        bookmarks = List<int>.from(data?['bookmarks'] ?? []);
        setState(() {
          currentPageIndex = bookmarks.isNotEmpty ? bookmarks.last : 0;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load bookmarks");
    }
  }

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
          backgroundColor: const Color(0xFFE07A5F),
          title: const Text('Book Viewer', style: TextStyle(
              color: Color(0xFFF8F0E3),
              shadows: [
                Shadow(
                  blurRadius: 8.0,
                  color: Colors.black45,
                  offset: Offset(2.0, 2.0),
                ),]
          ),),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmarks),
              onPressed: _showBookmarksDialog,
            ),
          ],
        ),
        body: localPdfPath == null
            ? const Center(child: CircularProgressIndicator())
            : PDFView(
          filePath: localPdfPath,
          defaultPage: currentPageIndex,
          onViewCreated: (controller) {
            pdfViewController = controller;
          },
          onPageChanged: (int? current, int? total) {
            setState(() {
              currentPageIndex = current ?? 0;
            });
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleBookmark,
          backgroundColor: bookmarks.contains(currentPageIndex) ? const Color(0xFF9B2226) : const Color(0xFFE07A5F),
          child: Icon(
            bookmarks.contains(currentPageIndex) ? Icons.bookmark : Icons.bookmark_border,
            color: const Color(0xFFFEF7DC),
          ),
        ),
      ),
    );
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF7DC),
          title: const Text("Bookmarks"),
          content: bookmarks.isEmpty
              ? const Text("No bookmarks available")
              : SizedBox(
            height: 200,
            width: 300,
            child: ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("Page ${bookmarks[index] + 1}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFF9B2226)),
                    onPressed: () {
                      _removeBookmark(bookmarks[index]);
                      Navigator.pop(context);
                      _showBookmarksDialog(); // Refresh dialog
                    },
                  ),
                  onTap: () {
                    _goToBookmark(bookmarks[index]); // Navigate to bookmarked page
                    Navigator.pop(context); // Close the dialog
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Color(0xFF9B2226)),),
            )
          ],
        );
      },
    );
  }

  Future<void> _removeBookmark(int pageIndex) async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      bookmarks.remove(pageIndex);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(widget.bookId)
          .delete();

      setState(() {});
      Fluttertoast.showToast(msg: "Bookmark Removed!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error removing bookmark");
    }
  }

  void _goToBookmark(int pageIndex) {
    if (pdfViewController != null) {
      pdfViewController!.setPage(pageIndex); // Navigate to the selected page
      setState(() {
        currentPageIndex = pageIndex; // Update current page index
      });
    }
  }
}
