import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BookPreviewWebView extends StatefulWidget {
  final String previewUrl;
  const BookPreviewWebView({super.key, required this.previewUrl});

  @override
  State<BookPreviewWebView> createState() => _BookPreviewWebViewState();
}

class _BookPreviewWebViewState extends State<BookPreviewWebView> {
  late final WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    // Initialize the WebViewController with the provided URL
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.previewUrl));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Book Preview"),
          backgroundColor: const Color(0xFFE07A5F),
        ),
        body: WebViewWidget(
          controller: webViewController, // Display WebView
        ),
      ),
    );
  }
}
