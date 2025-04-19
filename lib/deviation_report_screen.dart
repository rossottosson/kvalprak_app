// lib/deviation_report_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Optional: Import services for PlatformException if needed later
// import 'package:flutter/services.dart';

class DeviationReportScreen extends StatefulWidget {
  const DeviationReportScreen({super.key});

  @override
  State<DeviationReportScreen> createState() => _DeviationReportScreenState();
}

class _DeviationReportScreenState extends State<DeviationReportScreen> {
  late final WebViewController _controller;
  var loadingPercentage = 0;

  // --- Define the specific URL for deviation reporting ---
  final String _deviationUrl = 'https://playground.kiv.kvalprak.se/deviation/';
  // Define the base host for comparison
  final String _allowedHost = 'playground.kiv.kvalprak.se';


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
             // debugPrint('WebView is loading (progress : $progress%)');
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
            }
            // Optional: Could inject javascript here if needed to modify the page
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
            ''');
            if(mounted) {
               setState(() {
                loadingPercentage = 100; // Hide progress bar on error
              });
               if ((error.isForMainFrame ?? false) && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Failed to load page: ${error.description}')),
                 );
               }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final requestedUri = Uri.parse(request.url);
            debugPrint('Deviation Navigation request to: ${request.url}');

            // *** Navigation Locking Logic for Deviation Section ***
            // Allow navigation ONLY if it's within the allowed host AND
            // starts with the base deviation path OR is the root path (might be needed for logout links etc.)
            if (requestedUri.host == _allowedHost &&
                (request.url.startsWith(_deviationUrl) || request.url == 'https://$_allowedHost/')) { // Allow going back to root potentially
              debugPrint('Allowing navigation within deviation section or to root: ${request.url}');
              return NavigationDecision.navigate;
            } else {
              // Prevent navigation outside the allowed deviation paths
              debugPrint('Preventing navigation away from deviation section: ${request.url}');
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Navigering utanför avvikelsesektionen är begränsad.')),
                 );
              }
              return NavigationDecision.prevent; // Block
            }
          }, // End of onNavigationRequest
        ), // End of NavigationDelegate
      ) // End of setNavigationDelegate
      ..loadRequest(Uri.parse(_deviationUrl)); // Load the deviation URL directly
  } // End of initState method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapportera Avvikelse'),
        // The default back button in AppBar will call Navigator.pop(context)
        // which takes the user back to ActionSelectScreen.
        leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () {
             // Maybe add a confirmation dialog here if needed?
             if (Navigator.canPop(context)) {
                Navigator.pop(context);
             }
           }
        ),
         actions: [ // Add reload for convenience
          IconButton(
            icon: const Icon(Icons.replay),
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