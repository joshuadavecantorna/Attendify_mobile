import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const AttendifyApp());
}

class AttendifyApp extends StatelessWidget {
  const AttendifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AttendifyWebView(),
    );
  }
}

class AttendifyWebView extends StatefulWidget {
  const AttendifyWebView({super.key});

  @override
  State<AttendifyWebView> createState() => _AttendifyWebViewState();
}

class _AttendifyWebViewState extends State<AttendifyWebView> {
  late final WebViewController controller;
  bool isLoading = true;
  String currentUrl = '';

  @override
  void initState() {
    super.initState();

    // Initialize WebView Controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
            if (progress == 100) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
              currentUrl = url;
            });
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading page: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      // 👇 CHANGE THIS TO YOUR RAILWAY URL
      ..loadRequest(
          Uri.parse('https://attendify20-production.up.railway.app/'));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button - go back in web history
        if (await controller.canGoBack()) {
          controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        // App bar removed per request; full-screen webview.
        body: Stack(
          children: [
            // WebView
            WebViewWidget(controller: controller),

            // Loading indicator
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
