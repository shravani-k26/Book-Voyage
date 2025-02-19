import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfStoragePath; // gs://path/to/your/file.pdf
  final String bookId;


  const PdfViewerPage({super.key, required this.pdfStoragePath, required this.bookId});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int currentPageIndex = 0;
  bool isBookmarked = false;
  String? localPdfPath; // Local path for downloaded PDF

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked().then((_) => _downloadAndSavePdf());
  }

  // Download PDF from Firebase Storage and save locally
  Future<void> _downloadAndSavePdf() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.pdfStoragePath);
      final url = await ref.getDownloadURL();

      // Get the app's temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp.pdf');
      // Download the file
      await ref.writeToFile(tempFile);

      setState(() {
        localPdfPath = tempFile.path; // Store the local path
      });
    } catch (e) {
      print('Error downloading PDF: $e');
      Fluttertoast.showToast(msg: "Error loading PDF");
    }
  }
  Future<void>_addBookmark() async{
   try{
     String uid = _auth.currentUser?.uid ?? "";
     await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('bookmarks')
      .doc(widget.bookId)
      .set(
       {
         'pageIndex': currentPageIndex,
         'timestamp': FieldValue.serverTimestamp(),
       }
     );
     setState(() {
       isBookmarked = true;
     });
     Fluttertoast.showToast(msg: "Bookmark Added!");
   }
   catch(e){
     print('Error adding bookmark: $e');
     Fluttertoast.showToast(msg: "Error adding bookmark");
   }
  }
  Future<void>_removeBookmark() async{
    try{
      String uid = _auth.currentUser?.uid ?? "";
      await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(widget.bookId)
        .delete();
      setState(() {
        isBookmarked=false;
      });
      Fluttertoast.showToast(msg: "Book Removed!");
    }
    catch(e){
      print('Error removing bookmark: $e');
      Fluttertoast.showToast(msg: "Error removing bookmark");
    }
  }
  Future<void>_checkIfBookmarked() async{
    try{
      String uid = _auth.currentUser?.uid ?? "";
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(widget.bookId)
        .get();
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        int savedPageIndex = data?['pageIndex'] ?? 0;
        setState(() {
          currentPageIndex = savedPageIndex;
          isBookmarked = true;
        });
      }
    }
    catch(e){
      print('Error Checking Bookmarks: $e');
      Fluttertoast.showToast(msg: "Failed to check bookmark");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE07A5F),
        title: const Text('PDF Viewer'),
        actions: [
          IconButton(
            icon: Icon(
            isBookmarked ? Icons.bookmark:Icons.bookmark_border,
            color: isBookmarked ? Color(0xFF9B2226):Color(0xFFFEF7DC),
          ),
            onPressed: (){
                if(isBookmarked){
                  _removeBookmark();
                }
                else{
                  _addBookmark();
                }
              },
          )
        ],
      ),
      body: localPdfPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
        filePath: localPdfPath, // Use the local file path
        defaultPage: currentPageIndex,
        onPageChanged: (int? current, int? total) {
          setState(() {
            currentPageIndex = current ?? 0;
          });
        },
      ),
    );
  }
}
