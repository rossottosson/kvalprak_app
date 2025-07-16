// lib/deviation_report_screen.dart
// UPDATED onWebResourceError
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kvalprak_app/login_screen.dart'; // For navigating back on session timeout
import 'package:kvalprak_app/services/url_service.dart'; // Import the UrlService

class DeviationReportScreen extends StatefulWidget {
  const DeviationReportScreen({super.key});

  @override
  State<DeviationReportScreen> createState() => _DeviationReportScreenState();
}

class _DeviationReportScreenState extends State<DeviationReportScreen> {
  late WebViewController _controller; // Initialize later
  int _pageLoadingPercentage = 0;

  bool _isLoadingUrls = true;
  String _dynamicInitialDeviationUrl = '';
  String _dynamicAllowedHost = '';
  String _dynamicDeviationBasePath = '';
  String _dynamicSuccessUrlPattern = '';
  String _dynamicLoginUrlPattern = '';

  @override
  void initState() {
    super.initState();
    debugPrint("DeviationReportScreen initState: Loading dynamic URLs...");
    _loadUrlsAndInitializeController();
  }

  Future<void> _loadUrlsAndInitializeController() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUrls = true;
    });

    _dynamicInitialDeviationUrl = await UrlService.getDeviationInitialUrl();
    _dynamicAllowedHost = await UrlService.getWebHost();
    _dynamicDeviationBasePath = await UrlService.getDeviationBasePath();
    _dynamicSuccessUrlPattern = await UrlService.getDeviationSuccessPattern();
    _dynamicLoginUrlPattern = await UrlService.getGenericLoginPattern();

    debugPrint("DeviationReportScreen: Dynamic URLs loaded (relevant for onWebResourceError):");
    debugPrint("  _dynamicSuccessUrlPattern: $_dynamicSuccessUrlPattern");


    if (!mounted) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Deviation WebView: Page started loading: $url');
            if (mounted) {
              setState(() { _pageLoadingPercentage = 0; });
            }
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() { _pageLoadingPercentage = progress; });
            }
          },
          onPageFinished: (String url) {
            debugPrint('Deviation WebView: Page finished loading: $url');
            if (mounted) {
              setState(() { _pageLoadingPercentage = 100; });
              _hideUnwantedWebElements();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''Deviation WebView: Page resource error: 
              Description: ${error.description}
              ErrorCode: ${error.errorCode}
              ErrorType: ${error.errorType?.toString()}
              Failing URL: ${error.url}
              IsForMainFrame: ${error.isForMainFrame}
            ''');

            if (mounted) {
              if (_pageLoadingPercentage != 100) {
                setState(() { _pageLoadingPercentage = 100; });
              }

              bool showErrorSnackBar = true;

              if (error.url != null && _dynamicSuccessUrlPattern.isNotEmpty && error.url!.startsWith(_dynamicSuccessUrlPattern)) {
                String descriptionLower = error.description.toLowerCase();
                if (descriptionLower.contains("interrupted") ||
                    descriptionLower.contains("cancelled") ||
                    error.errorCode == -999 || // NSURLErrorCancelled on iOS
                    error.errorCode == -10 ||   // ERROR_UNKNOWN_URL_SCHEME on Android
                    (error.errorType?.toString().toLowerCase().contains("cancel") ?? false) ) { 
                  debugPrint("Deviation WebView: Suppressing SnackBar for expected error on prevented success URL: ${error.url}");
                  showErrorSnackBar = false;
                }
              }

              if (showErrorSnackBar && (error.isForMainFrame ?? false) && context.mounted) {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sidladdningsfel: ${error.description}')),
                );
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final requestedUrl = request.url;
            final requestedUri = Uri.parse(requestedUrl);
            debugPrint('Deviation WebView: Navigation request to: $requestedUrl (Host: ${requestedUri.host})');

            if (requestedUrl.startsWith(_dynamicSuccessUrlPattern)) {
              debugPrint('>>> Deviation WebView: Success URL detected: $requestedUrl');
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
                  Navigator.of(context).pop();
                }
              }
              return NavigationDecision.prevent;
            }

            if (requestedUrl.startsWith(_dynamicLoginUrlPattern) && requestedUri.host == _dynamicAllowedHost) {
               debugPrint('>>> Deviation WebView: Login URL on allowed host detected (session timeout?): $requestedUrl');
               if (mounted) {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sessionen har gått ut. Logga in igen för att fortsätta.'),
                      backgroundColor: Colors.orangeAccent,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                     MaterialPageRoute(builder: (context) => const LoginScreen()),
                     (Route<dynamic> route) => route.isFirst,
                  );
               }
               return NavigationDecision.prevent;
            }

            if (requestedUri.host == _dynamicAllowedHost && requestedUrl.startsWith(_dynamicDeviationBasePath)) {
              debugPrint('Deviation WebView: Allowing navigation within deviation section: $requestedUrl');
              return NavigationDecision.navigate;
            }
            
            if (requestedUri.host == _dynamicAllowedHost) {
                debugPrint('Deviation WebView: Preventing navigation to other sections on the same host: $requestedUrl');
                return NavigationDecision.prevent;
            }

            debugPrint('Deviation WebView: Preventing external or disallowed navigation: $requestedUrl');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_dynamicInitialDeviationUrl));

    if (mounted) {
      setState(() {
        _isLoadingUrls = false;
      });
    }
  }

  void _hideUnwantedWebElements() {
    if (_isLoadingUrls || !mounted) {
      debugPrint("DeviationReportScreen: JS not run, controller not ready or URLs still loading or widget unmounted.");
      return;
    }
    String jsCode = """
      try {
        var mainNavBar = document.querySelector('nav.navbar.navbar-static-top.navbar-expand-md'); 
        if (mainNavBar) {
          mainNavBar.style.display = 'none';
          console.log('Kvalprak App: Main navigation bar hidden.');
        } else {
          console.log('Kvalprak App: Main navigation bar (nav.navbar.navbar-static-top.navbar-expand-md) not found.');
        }
        var leftAppsMenu = document.querySelector('.navbar-custom-menu-left');
        if (leftAppsMenu) {
          leftAppsMenu.style.display = 'none';
          console.log('Kvalprak App: Left apps menu (.navbar-custom-menu-left) hidden.');
        } else {
          console.log('Kvalprak App: Left apps menu (.navbar-custom-menu-left) not found.');
        }
      } catch (e) {
        console.error('Kvalprak App: JavaScript error while trying to hide elements: ' + e.toString());
      }
    """;
    _controller.runJavaScript(jsCode);
    debugPrint("DeviationReportScreen: Executed JavaScript to hide elements.");
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUrls) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rapportera Avvikelse')),
        body: const Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Laddar klinikinformation..."),
          ],
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapportera Avvikelse'),
        leading: IconButton(
           icon: const Icon(Icons.arrow_back_ios_new_rounded),
           tooltip: "Stäng",
           onPressed: () {
             _askToPop();
           }
        ),
         actions: [
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            tooltip: 'Ladda om sidan',
            onPressed: () {
              if (!_isLoadingUrls) {
                 _controller.reload();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
          ),
          if (_pageLoadingPercentage < 100)
            LinearProgressIndicator(
              value: _pageLoadingPercentage / 100.0,
               backgroundColor: Colors.white.withOpacity(0.5),
               valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
    );
  }

  Future<void> _askToPop() async {
    if (_isLoadingUrls || !mounted) { 
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        return;
    }
    String? currentUrl;
    try {
      currentUrl = await _controller.currentUrl();
    } catch (e) {
      debugPrint("Error getting current URL in _askToPop: $e");
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      return;
    }
    final bool hasNavigatedFromInitial = currentUrl != _dynamicInitialDeviationUrl;

    if (hasNavigatedFromInitial && mounted) {
      final bool? shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lämna sidan?'),
          content: const Text('Eventuellt ifylld information kommer inte att sparas. Är du säker på att du vill lämna?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Avbryt'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Lämna'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (shouldPop ?? false) {
         if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      }
    } else {
      if (mounted && Navigator.canPop(context)) {
         Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    debugPrint("DeviationReportScreen dispose method called.");
    super.dispose();
  }
}