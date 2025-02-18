import 'dart:io'; // For File operations
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart'; // For temporary directory

class PdfViewerPage extends StatefulWidget {
  final String pdfStoragePath; // gs://path/to/your/file.pdf
  final String bookId;

  const PdfViewerPage({super.key, required this.pdfStoragePath, required this.bookId});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int currentPageIndex = 0;
  bool isBookmarked = false;
  String? localPdfPath; // Local path for downloaded PDF

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: localPdfPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
        filePath: localPdfPath, // Use the local file path
        onPageChanged: (int? current, int? total) {
          setState(() {
            currentPageIndex = current ?? 0;
          });
        },
      ),
    );
  }
}
