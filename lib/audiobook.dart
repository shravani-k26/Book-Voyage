import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class AudiobookTTSPage extends StatefulWidget {
  final String bookId;
  final String userId;

  const AudiobookTTSPage({super.key, required this.bookId, required this.userId});

  @override
  State<AudiobookTTSPage> createState() => _AudiobookTTSPageState();
}

class _AudiobookTTSPageState extends State<AudiobookTTSPage> {
  FlutterTts flutterTts = FlutterTts();
  PDFViewController? pdfController;
  String localPdfPath = '';
  int startPage = 0;
  int endPage = 0;
  int currentPage = 0;
  bool isPlaying = false;
  List<int> bookmarks = [];

  @override
  void initState() {
    super.initState();
    fetchBookDetails();
    setupTTS();
    loadBookmarks();
  }

  void setupTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);
    flutterTts.setCompletionHandler(() async {
      if (currentPage < endPage) {
        setState(() => currentPage++);
        pdfController?.setPage(currentPage);
        await Future.delayed(Duration(milliseconds: 200));
        extractAndSpeakText(currentPage);
      } else {
        setState(() => isPlaying = false);
      }
    });
  }

  Future<void> fetchBookDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection("books").doc(widget.bookId).get();
      if (doc.exists) {
        if (doc["audiobook"] == true) {
          String pdfUrl = doc["pdf_url"];
          setState(() {
            startPage = doc["startPage"]-1 ?? 0;
            endPage = doc["endPage"]-1 ?? 0;
            currentPage = startPage; // Initialize currentPage with startPage
          });
          await loadBookmarks();
          downloadPDF(pdfUrl);
        } else {
          Fluttertoast.showToast(msg: "Audiobook not available for this book");
        }
      }
    } catch (e) {
      print("Error fetching book details: $e");
    }
  }

  Future<void> downloadPDF(String pdfUrl) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File pdfFile = File('${tempDir.path}/temp.pdf');
      final Reference storageRef = FirebaseStorage.instance.refFromURL(pdfUrl);
      await storageRef.writeToFile(pdfFile);
      setState(() => localPdfPath = pdfFile.path);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error downloading PDF: $e");
    }
  }

  Future<void> extractAndSpeakText(int page) async {
    if (localPdfPath.isNotEmpty) {
      final PdfDocument document = PdfDocument(inputBytes: File(localPdfPath).readAsBytesSync());
      PdfTextExtractor extractor = PdfTextExtractor(document);
      String pageText = extractor.extractText(startPageIndex: page).trim();
      document.dispose();

      if (pageText.isNotEmpty) {
        await flutterTts.speak(pageText);
      } else {
        if (currentPage < endPage) {
          setState(() => currentPage++);
          pdfController?.setPage(currentPage);
          extractAndSpeakText(currentPage);
        } else {
          setState(() => isPlaying = false);
          Fluttertoast.showToast(msg: "No more readable text.");
        }
      }
    }
  }

  Future<void> playTTS() async {
    if (localPdfPath.isNotEmpty) {
      setState(() {
        isPlaying = true;// Start TTS from the startPage
      });

      if (pdfController != null) {
        await pdfController!.setPage(currentPage);
      }
      extractAndSpeakText(currentPage);
    }
  }

  Future<void> pauseTTS() async {
    await flutterTts.stop();
    setState(() => isPlaying = false);
  }
  Future<void> loadBookmarks() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('audiobookBookmarks')
          .doc(widget.bookId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        bookmarks = List<int>.from(data?['pages'] ?? []);

        setState(() {
          currentPage = bookmarks.isNotEmpty ? bookmarks.last : startPage;
        });

        // Ensure PDF scrolls to the latest bookmark
        if (pdfController != null) {
          pdfController!.setPage(currentPage);
        }

        // Start TTS automatically after setting page
        if (localPdfPath.isNotEmpty) {
          extractAndSpeakText(currentPage);
          setState(() => isPlaying = true);
        }
      } else {
        setState(() {
          currentPage = startPage;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading bookmarks");
    }
  }

  void _toggleBookmark() async {
    if (bookmarks.contains(currentPage)) {
      bookmarks.remove(currentPage);
    } else {
      bookmarks.add(currentPage);
    }
    if (bookmarks.isEmpty) {
      // Remove the document if there are no bookmarks left
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('audiobookBookmarks')
          .doc(widget.bookId)
          .delete();
    } else {
      // Update the document with the new bookmarks
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('audiobookBookmarks')
          .doc(widget.bookId)
          .set({'pages': bookmarks}, SetOptions(merge: true));
    }
    setState(() {});
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
                      _toggleBookmark();
                      Navigator.pop(context);
                      _showBookmarksDialog();
                    },
                  ),
                  onTap: () {
                    setState(() {
                      currentPage = bookmarks[index];
                    });
                    pdfController?.setPage(currentPage);
                    extractAndSpeakText(currentPage);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Color(0xFF9B2226))),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop) return;
        await flutterTts.stop(); // Stop TTS when back button is pressed
      },
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
            backgroundColor:  const Color(0xFFE07A5F),
            title: const Text(
                "Audiobook Listener",
              style: TextStyle(
                  color: Color(0xFFF8F0E3),
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black45,
                      offset: Offset(2.0, 2.0),
                    ),]
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmarks_rounded),
                onPressed: _showBookmarksDialog,
              ),
            ],
        ),
        body: Column(
          children: [
            Expanded(
              child: localPdfPath.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : PDFView(
                filePath: localPdfPath,
                defaultPage: startPage, // Start PDF from startPage
                swipeHorizontal: false,
                onViewCreated: (controller) {
                  pdfController = controller;
                  controller.setPage(currentPage);
                },
                onPageChanged: (page, _) async {
                  if (page != null) {
                    await flutterTts.stop(); // Stop TTS when user scrolls
                    setState(() {
                      currentPage = page;  // Update to the new page
                    });

                    if (isPlaying) {
                      await Future.delayed(Duration(milliseconds: 500));
                      extractAndSpeakText(currentPage); // Restart TTS on the new page
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 40),
                    onPressed: () async {
                      if (currentPage > startPage) {
                        await flutterTts.stop();
                        setState(() => currentPage--);
                        pdfController?.setPage(currentPage);
                        extractAndSpeakText(currentPage);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 40),
                    onPressed: () async {
                      if (isPlaying) {
                        await pauseTTS();
                      } else {
                        await playTTS();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 40),
                    onPressed: () async {
                      if (currentPage < endPage) {
                        await flutterTts.stop();
                        setState(() => currentPage++);
                        pdfController?.setPage(currentPage);
                        extractAndSpeakText(currentPage);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70.0),
          child: FloatingActionButton(
            onPressed: _toggleBookmark,
            backgroundColor: bookmarks.contains(currentPage) ? const Color(0xFF9B2226): const Color(0xFFE07A5F),
            child: Icon(
                bookmarks.contains(currentPage) ? Icons.bookmark : Icons.bookmark_border,
                color: const Color(0xFFFEF7DC),
            ),
          ),
        ),
      ),
    );
  }
}
