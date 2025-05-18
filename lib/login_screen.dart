// lib/login_screen.dart
// UPDATED WITH "CHANGE CLINIC" BUTTON
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Needed for WebViewCookieManager
import 'package:kvalprak_app/action_select_screen.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/screens/clinic_selection_screen.dart'; // To navigate back

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late WebViewController _controller;
  int _pageLoadingPercentage = 0;
  bool _navigationTriggered = false;

  bool _isLoadingUrls = true;
  String _dynamicInitialUrl = '';
  String _dynamicPostLoginSuccessUrl = '';
  String _dynamicAllowedHost = '';

  @override
  void initState() {
    super.initState();
    debugPrint("LoginScreen initState: Loading dynamic URLs...");
    _navigationTriggered = false;
    _loadUrlsAndInitializeController();
  }

  Future<void> _loadUrlsAndInitializeController() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUrls = true;
    });

    _dynamicInitialUrl = await UrlService.getLoginInitialUrl();
    _dynamicPostLoginSuccessUrl = await UrlService.getLoginPostSuccessUrl();
    _dynamicAllowedHost = await UrlService.getHost();

    debugPrint("LoginScreen: Dynamic URLs loaded:");
    debugPrint("  _dynamicInitialUrl: $_dynamicInitialUrl");
    debugPrint("  _dynamicPostLoginSuccessUrl: $_dynamicPostLoginSuccessUrl");
    debugPrint("  _dynamicAllowedHost: $_dynamicAllowedHost");

    if (!mounted) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('LoginScreen WebView: Page started loading: $url');
            if (mounted && !_navigationTriggered) {
              setState(() { _pageLoadingPercentage = 0; });
            }
          },
          onProgress: (int progress) {
            if (mounted && !_navigationTriggered) {
              setState(() { _pageLoadingPercentage = progress; });
            }
          },
          onPageFinished: (String url) {
            debugPrint('LoginScreen WebView: ===== onPageFinished =====');
            debugPrint('LoginScreen WebView: Received URL: "$url"');
            debugPrint('LoginScreen WebView: Comparing with target success URL: "$_dynamicPostLoginSuccessUrl"');

            if (mounted && _pageLoadingPercentage != 100) {
              setState(() { _pageLoadingPercentage = 100; });
            }

            if (url == _dynamicPostLoginSuccessUrl) {
              debugPrint('LoginScreen WebView: URL matches _dynamicPostLoginSuccessUrl.');
              if (!_navigationTriggered && mounted) {
                  _navigationTriggered = true;
                  debugPrint('>>> LoginScreen WebView: Triggering native navigation IMMEDIATELY...');
                  Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => const ActionSelectScreen()),
                  );
                  debugPrint('>>> LoginScreen WebView: Navigator.pushReplacement called.');
              }
            } else {
                debugPrint('LoginScreen WebView: URL does NOT match target success URL.');
            }
             debugPrint('LoginScreen WebView: ===== /onPageFinished =====');
          },
          onWebResourceError: (WebResourceError error) {
             debugPrint('''LoginScreen WebView: Page resource error: ${error.description} (URL: ${error.url})''');
            if (mounted) {
              setState(() { _pageLoadingPercentage = 100; });
              if ((error.isForMainFrame ?? false) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load page: ${error.description}')),
                );
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
             if (_navigationTriggered) {
               debugPrint('LoginScreen WebView: Native navigation triggered, preventing further web request to: "${request.url}"');
               return NavigationDecision.prevent;
             }

            final requestedUri = Uri.parse(request.url);
            debugPrint('LoginScreen WebView: onNavigationRequest check for: "${request.url}" (Host: ${requestedUri.host})');
            debugPrint('LoginScreen WebView: Comparing with allowed host: "$_dynamicAllowedHost"');

            if (requestedUri.host == _dynamicAllowedHost) {
              debugPrint('LoginScreen WebView: Allowing navigation within domain: "${request.url}"');
              return NavigationDecision.navigate;
            } else {
              debugPrint('LoginScreen WebView: Preventing external or disallowed navigation to: "${request.url}"');
              // SnackBar borttagen härifrån enligt tidigare önskemål
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_dynamicInitialUrl));

    if (mounted) {
      setState(() {
        _isLoadingUrls = false;
      });
    }
  }

  // --- METOD FÖR ATT BYTA KLINIK / LOGGA UT ---
  Future<void> _confirmAndChangeClinic() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Byt klinik'),
          content: const Text(
              'Är du säker på att du vill byta klinik? Du kommer att loggas ut och tas tillbaka till klinikvalet.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Avbryt'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Byt klinik'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      // Rensa WebView cookies
      final WebViewCookieManager cookieManager = WebViewCookieManager();
      final bool hadCookies = await cookieManager.clearCookies();
      debugPrint("LoginScreen: WebView cookies cleared (had cookies: $hadCookies)");

      // Rensa vald klinik i SharedPreferences
      await UrlService.clearSelectedClinic();

      // Navigera tillbaka till klinikvalsskärmen och rensa historiken
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ClinicSelectionScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
  // --- SLUT PÅ METOD ---


  @override
  Widget build(BuildContext context) {
    if (_isLoadingUrls) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Login - Vårdna'),
          // Lägg till "Byt klinik"-knapp även här, om användaren vill byta innan URL:er laddats
          actions: [
            Tooltip(
              message: "Byt klinik",
              child: IconButton(
                icon: const Icon(Icons.home_work_outlined), // Eller Icons.logout_rounded
                onPressed: _confirmAndChangeClinic,
              ),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Laddar klinikinformation..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String?>(
           future: UrlService.getSelectedClinicName(),
           builder: (context, snapshot) {
             String titleText = "Login";
             if (snapshot.connectionState == ConnectionState.done) {
               if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                 titleText = "${snapshot.data} - Login";
               } else if (_dynamicAllowedHost.isNotEmpty) {
                  final hostParts = _dynamicAllowedHost.split('.');
                  if (hostParts.isNotEmpty && hostParts.first.toLowerCase() != "www") {
                    titleText = "${hostParts.first.capitalize()} - Login";
                  } else if (hostParts.length > 1 && hostParts[1].isNotEmpty) {
                    titleText = "${hostParts[1].capitalize()} - Login"; // Om det är t.ex. www.kliniknamn
                  }
               } else {
                 titleText = "Login - Vårdna";
               }
             } else if (snapshot.connectionState == ConnectionState.waiting) {
                titleText = "Laddar klinik...";
             }
             return Text(titleText);
           }
        ),
        // --- LÄGG TILL KNAPPEN HÄR ---
        actions: [
          Tooltip(
            message: "Byt klinik / Välj annan klinik",
            child: IconButton(
              icon: const Icon(Icons.home_work_outlined), // Tydligare ikon för "byt klinik"
                                                        // Alternativt Icons.logout om det känns mer rätt
              onPressed: _confirmAndChangeClinic,
            ),
          ),
        ],
        // --- SLUT PÅ TILLÄGG ---
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
          ),
          if (_pageLoadingPercentage < 100)
            LinearProgressIndicator(
              value: _pageLoadingPercentage / 100.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint("LoginScreen dispose method called.");
    super.dispose();
  }
}

extension StringExtension on String {
    String capitalize() {
      if (isEmpty) {
        return this;
      }
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}