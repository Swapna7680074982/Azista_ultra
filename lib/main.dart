import 'package:azista_ultra/my_app.dart';
import 'package:azista_ultra/services/notification_service.dart';
import 'package:flutter/material.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   print("🚀 MAIN START"); // 👈 ADD THIS
//
//   await NotificationService.instance.init();
//
//   print("🚀 AFTER INIT"); // 👈 ADD THIS
//
//   runApp(const MyApp());
//
//   print("🚀 APP RUNNING"); // 👈 ADD THIS
// }

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  // Ensure Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drive Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// SCREEN 1: SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    // Wait for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));

    // Navigate to the Web View Screen and remove Splash from history
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GalleryWebViewScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_to_drive, size: 100, color: Colors.blueAccent),
            SizedBox(height: 24),
            Text(
              'My Drive Gallery',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 2: MAIN WEBVIEW SCREEN
// ==========================================
class GalleryWebViewScreen extends StatefulWidget {
  const GalleryWebViewScreen({super.key});

  @override
  State<GalleryWebViewScreen> createState() => _GalleryWebViewScreenState();
}

class _GalleryWebViewScreenState extends State<GalleryWebViewScreen> {

  // 1. The Default Static Link updated with your link!
  final String _staticLink = 'https://photos.app.goo.gl/rgBaiz5Hv2Qi3rvu8';

  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize the WebView Controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Hide the loading spinner when the webpage finishes loading
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
    // Automatically load the static link on startup
      ..loadRequest(Uri.parse(_staticLink));
  }

  // 2. Show the dialog to input a new link
  void _showUploadLinkDialog() {
    final TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload New Link'),
          content: TextField(
            controller: linkController,
            decoration: InputDecoration(
              hintText: 'Paste Google Drive/Photos link',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.link),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close popup without doing anything
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (linkController.text.isNotEmpty) {
                  Navigator.pop(context); // Close popup
                  _loadNewLink(linkController.text); // Trigger the new link load
                }
              },
              child: const Text('Load Photos'),
            ),
          ],
        );
      },
    );
  }

  // 3. Function to reload the WebView with the new URL
  void _loadNewLink(String newUrl) {
    // Show the loading spinner again
    setState(() {
      _isLoading = true;
    });

    // Ensure the string is a valid URL, then load it
    Uri? uri = Uri.tryParse(newUrl);
    if (uri != null) {
      _controller.loadRequest(uri);
    } else {
      // If the link is totally invalid, hide the spinner
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL format')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gallery'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // The Upload Button in the Top Bar
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Upload New Link',
            onPressed: _showUploadLinkDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // The actual Web Browser view
          WebViewWidget(controller: _controller),

          // The Loading Spinner overlay
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
