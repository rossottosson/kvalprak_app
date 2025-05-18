// lib/login_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Can likely remove
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kvalprak_app/action_select_screen.dart';
// No transition screen import needed

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  var loadingPercentage = 0;
  bool _navigationTriggered = false;
  // Removed _isTransitioning and _isInitialLoad state variables

  // URLs and Host configuration
  final String _initialUrl = 'https://playground.kiv.kvalprak.se/login?redirect=';
  final String _postLoginSuccessUrl = 'https://playground.kiv.kvalprak.se/';
  final String _allowedHost = 'playground.kiv.kvalprak.se';

  @override
  void initState() {
    super.initState();
    debugPrint("LoginScreen initState (Reverted to Immediate Navigation)");
    _navigationTriggered = false;

    // Initialize WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('LoginScreen: Page started loading: $url');
            if (mounted) {
              // Reset navigation trigger if a new page starts BEFORE success was reached
              // (e.g., user navigates back/forth on login pages)
              if (!_navigationTriggered) {
                 // Reset linear progress only
                 setState(() { loadingPercentage = 0; });
              }
            }
          },
          onProgress: (int progress) {
            if (mounted && !_navigationTriggered) { // Stop updating progress after navigating
              setState(() { loadingPercentage = progress; });
            }
          },
          // --- onPageFinished with IMMEDIATE Navigation ---
          onPageFinished: (String url) {
            debugPrint('LoginScreen: ===== onPageFinished =====');
            debugPrint('LoginScreen: Received URL: "$url"');
            debugPrint('LoginScreen: Comparing with target success URL: "$_postLoginSuccessUrl"');
            debugPrint('LoginScreen: _navigationTriggered state: $_navigationTriggered');
            debugPrint('LoginScreen: Mounted state: $mounted');

            // Stop showing linear progress once any page finishes
            if (mounted && loadingPercentage != 100) {
              setState(() { loadingPercentage = 100; });
            }

            // --- Navigate if on Success URL ---
            if (url == _postLoginSuccessUrl) {
              debugPrint('LoginScreen: URL matches _postLoginSuccessUrl.');
              if (!_navigationTriggered && mounted) {
                  _navigationTriggered = true; // Prevent duplicate triggers
                  debugPrint('>>> LoginScreen: Triggering native navigation IMMEDIATELY...');

                  // *** Direct navigation call ***
                  Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => const ActionSelectScreen()),
                  );
                  // ****************************

                  debugPrint('>>> LoginScreen: Navigator.pushReplacement called.');
              } else {
                  debugPrint('LoginScreen: Native navigation skipped (already triggered or unmounted)...');
              }
            } else {
                debugPrint('LoginScreen: URL does NOT match target success URL.');
            }
             debugPrint('LoginScreen: ===== /onPageFinished =====');
          }, // End of onPageFinished

          onWebResourceError: (WebResourceError error) {
             debugPrint('''LoginScreen: Page resource error: ${error.description}''');
            if (mounted) {
              setState(() { loadingPercentage = 100; });
              if ((error.isForMainFrame ?? false) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load page: ${error.description}')),
                );
              }
            }
             // Reset navigation trigger on error? Maybe not needed if staying on LoginScreen
             // _navigationTriggered = false;
          }, // End of onWebResourceError

          // --- Navigation Request Logic (Simplified back) ---
          onNavigationRequest: (NavigationRequest request) {
            // Block navigation if native transition has theoretically started
            // Might help slightly but likely won't prevent initial flash
             if (_navigationTriggered) {
               debugPrint('LoginScreen: Native navigation triggered, preventing further web request to: "${request.url}"');
               return NavigationDecision.prevent;
             }

            final requestedUri = Uri.parse(request.url);
            debugPrint('LoginScreen: onNavigationRequest check for: "${request.url}"');

            if (requestedUri.host == _allowedHost) {
              debugPrint('LoginScreen: Allowing navigation within domain: "${request.url}"');
              return NavigationDecision.navigate;
            } else {
              debugPrint('LoginScreen: Preventing external navigation to: "${request.url}"');
              if (context.mounted) {
                 ScaffoldMessenger.of(context).removeCurrentSnackBar();
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('Navigation to external sites is blocked.'),
                     duration: Duration(seconds: 2),
                    ),
                 );
              }
              return NavigationDecision.prevent; // Block
            }
          }, // End of onNavigationRequest
        ), // End of NavigationDelegate
      ) // End of setNavigationDelegate
      ..loadRequest(Uri.parse(_initialUrl)); // Load the initial URL
  } // End of initState method

  // --- Build Method (Simplified - No overlay logic) ---
  @override
  Widget build(BuildContext context) {
    debugPrint("LoginScreen build method running (Immediate Navigation Approach)");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Vårdna'),
      ),
      body: Stack(
        children: [
          // Just the WebView
          WebViewWidget(
            controller: _controller,
          ),
          // And the linear progress indicator (show until page finishes)
          if (loadingPercentage < 100)
            LinearProgressIndicator(
              value: loadingPercentage / 100.0,
              backgroundColor: Colors.white.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
    );
  } // End build method

  // --- Dispose Method ---
  @override
  void dispose() {
    debugPrint("LoginScreen dispose method called.");
    super.dispose();
  }
} // End _LoginScreenState class