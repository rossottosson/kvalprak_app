// lib/deviation_report_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kvalprak_app/login_screen.dart'; // Import LoginScreen

class DeviationReportScreen extends StatefulWidget {
  const DeviationReportScreen({super.key});

  @override
  State<DeviationReportScreen> createState() => _DeviationReportScreenState();
}

class _DeviationReportScreenState extends State<DeviationReportScreen> {
  late final WebViewController _controller;
  var loadingPercentage = 0;

  final String _initialDeviationUrl = 'https://playground.kiv.kvalprak.se/deviation/add/1';
  final String _allowedHost = 'playground.kiv.kvalprak.se';
  final String _deviationBasePath = 'https://playground.kiv.kvalprak.se/deviation/';
  final String _successUrlPattern = 'https://playground.kiv.kvalprak.se/deviation/add/2/';
  // --- ADDED: Define the login URL pattern ---
  // Adjust this if the actual login URL is different (e.g., includes query params consistently)
  final String _loginUrlPattern = 'https://playground.kiv.kvalprak.se/login';


  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Deviation Page started loading: $url');
            if(mounted) {
              setState(() {
                loadingPercentage = 0;
              });
            }
          },
          onProgress: (int progress) {
             if(mounted) {
               setState(() {
                 loadingPercentage = progress;
               });
             }
          },
          onPageFinished: (String url) {
            debugPrint('Deviation Page finished loading: $url');
            if(mounted) {
              setState(() {
                loadingPercentage = 100;
              });
              // Optional: Hide website header (replace selector)
              const String jsCodeToHideHeader = """
                var elementToHide = document.querySelector('.website-header-class-name'); // <-- REPLACE THIS SELECTOR
                if (elementToHide) { elementToHide.style.display = 'none'; }
              """;
               _controller.runJavaScript(jsCodeToHideHeader);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''Page resource error: ${error.description}''');
            if(mounted) {
               setState(() { loadingPercentage = 100; });
               if ((error.isForMainFrame ?? false) && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Failed to load page: ${error.description}')),
                 );
               }
            }
          },
          // --- UPDATED: onNavigationRequest Logic ---
          onNavigationRequest: (NavigationRequest request) {
            final requestedUrl = request.url;
            final requestedUri = Uri.parse(requestedUrl);
            debugPrint('Deviation Navigation request to: $requestedUrl');

            // --- Check 1: Is it the success URL pattern? ---
            if (requestedUrl.startsWith(_successUrlPattern)) {
              debugPrint('>>> Success URL detected: $requestedUrl');
              if (mounted) {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ditt ärende har skickats!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(); // Go back to ActionSelectScreen
                }
              }
              return NavigationDecision.prevent;
            }

            // --- Check 2: Is it the LOGIN URL pattern (session timeout)? ---
            if (requestedUrl.startsWith(_loginUrlPattern)) {
               debugPrint('>>> Login URL detected (session timeout?): $requestedUrl');
               if (mounted) {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sessionen har gått ut, logga in igen.'),
                      backgroundColor: Colors.orange, // Use a warning color
                      duration: Duration(seconds: 3),
                    ),
                  );
                  // Navigate back to the LoginScreen, clearing the stack above it
                  Navigator.of(context).pushAndRemoveUntil(
                     MaterialPageRoute(builder: (context) => const LoginScreen()),
                     (Route<dynamic> route) => false, // Remove all routes
                  );
               }
               return NavigationDecision.prevent; // Prevent webview from actually going to login
            }


            // --- Check 3: Is it within the allowed host AND deviation section? ---
            if (requestedUri.host == _allowedHost && requestedUrl.startsWith(_deviationBasePath)) {
              debugPrint('Allowing navigation within deviation section: $requestedUrl');
              return NavigationDecision.navigate;
            }

            // --- Check 4: Otherwise, prevent navigation ---
            // This handles clicks on other links within the deviation page (e.g., external links, root link)
            debugPrint('Preventing navigation away from deviation section: $requestedUrl');
            if (mounted) {
                 ScaffoldMessenger.of(context).removeCurrentSnackBar();
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('Navigering utanför aktuell sektion är begränsad.'),
                     duration: Duration(seconds: 2),
                    ),
                 );
            }
            return NavigationDecision.prevent; // Block
          }, // End of onNavigationRequest
        ), // End of NavigationDelegate
      ) // End of setNavigationDelegate
      ..loadRequest(Uri.parse(_initialDeviationUrl)); // Load the initial deviation URL
  } // End of initState method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapportera Avvikelse'),
        leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () {
             // Maybe add confirmation dialog if user might lose data?
             if (Navigator.canPop(context)) {
                Navigator.pop(context);
             }
           }
        ),
         actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Ladda om sidan',
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
          ),
          if (loadingPercentage < 100)
            LinearProgressIndicator(
              value: loadingPercentage / 100.0,
               backgroundColor: Colors.white.withOpacity(0.5),
               valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
    );
  }
}
