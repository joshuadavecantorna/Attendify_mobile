import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';

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
    _requestPermissions();
    _initializeWebView();
  }

  Future<void> _requestPermissions() async {
    // Request camera permission for QR scanning
    await Permission.camera.request();
  }

  void _initializeWebView() {
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
      ..loadRequest(
          Uri.parse('https://attendify20-production.up.railway.app/'));

    // Enable camera and media permissions for Android WebView
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);

      // Grant camera permission to WebView
      androidController.setOnShowFileChooser(
        (controller, params) async {
          return [];
        },
      );

      // Enable geolocation and other permissions
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return GeolocationPermissionsResponse(
            allow: true,
            retain: true,
          );
        },
      );

      // Enable camera permission requests from web pages
      androidController.setPermissionRequestCallback(
        (request) async {
          await request.grant();
        },
      );
    }
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
        // App bar removed per request; full-screen webview with SafeArea.
        body: SafeArea(
          child: Stack(
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
      ),
    );
  }
}
