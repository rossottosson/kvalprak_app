// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kvalprak_app/action_select_screen.dart';
import 'package:kvalprak_app/secure_storage_service.dart'; // Import secure storage
import 'package:local_auth/local_auth.dart'; // Needed for checking biometrics support in prompt

class LoginScreen extends StatefulWidget {
  final bool performAutoLogin; // Flag from AuthCheckScreen

  const LoginScreen({
    super.key,
    this.performAutoLogin = false, // Default to false
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  var loadingPercentage = 0;
  bool _navigationTriggered = false;
  bool _autoLoginAttempted = false; // Track if we tried auto-login

  // URLs and Host configuration
  // *** Using root URL based on user confirmation ***
  final String _initialUrl = 'https://playground.kiv.kvalprak.se/';
  final String _postLoginSuccessUrl = 'https://playground.kiv.kvalprak.se/'; // Keep as root
  final String _allowedHost = 'playground.kiv.kvalprak.se';

  // Services
  final SecureStorageService _storageService = SecureStorageService(); // Instance for storage
  final LocalAuthentication _localAuth = LocalAuthentication(); // For checking support

  @override
  void initState() {
    super.initState();
    debugPrint("LoginScreen initState: performAutoLogin = ${widget.performAutoLogin}");
    // Reset flags on initialization
    _navigationTriggered = false;
    _autoLoginAttempted = false;

    // Initialize WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('LoginScreen: Page started loading: $url');
            if (mounted) {
              setState(() {
                loadingPercentage = 0;
              });
            }
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                loadingPercentage = progress;
              });
            }
          },
          // --- onPageFinished with Immediate Navigation & Debugging ---
          onPageFinished: (String url) async { // Make async for storage checks
            // --- Detailed Debugging ---
            debugPrint('LoginScreen: ===== onPageFinished =====');
            debugPrint('LoginScreen: Received URL: "$url"');
            debugPrint('LoginScreen: Comparing with target URL: "$_postLoginSuccessUrl"');
            debugPrint('LoginScreen: _navigationTriggered state BEFORE check: $_navigationTriggered');
            debugPrint('LoginScreen: _autoLoginAttempted state BEFORE check: $_autoLoginAttempted');
            debugPrint('LoginScreen: Mounted state: $mounted');
            // --- End Detailed Debugging ---

            if (mounted) {
              setState(() { loadingPercentage = 100; });
            }

            // --- Auto-Login Logic ---
            // Attempt auto-login if flagged, on the initial page, and not yet attempted
            if (widget.performAutoLogin && url == _initialUrl && !_autoLoginAttempted) {
              debugPrint('LoginScreen: Condition met for attempting auto-login.');
              await _attemptAutoLogin();
            }
            // --- Post-Login / Already Logged In Logic ---
            // Check if the finished URL is the one indicating successful login/dashboard
            else if (url == _postLoginSuccessUrl) {
              debugPrint('LoginScreen: URL matches _postLoginSuccessUrl.');

              // --- Prompt to save credentials only on successful manual login ---
              bool hasCreds = await _storageService.hasCredentials();
              bool bioEnabled = await _storageService.areBiometricsEnabled();
              if ((!hasCreds || !bioEnabled) && !_autoLoginAttempted && mounted) {
                 debugPrint('LoginScreen: Manual login success detected, prompting to enable biometrics.');
                 await _promptToEnableBiometrics();
              }

              // --- Trigger Native Navigation Immediately ---
              if (!_navigationTriggered && mounted) {
                _navigationTriggered = true; // Set flag IMMEDIATELY
                debugPrint('>>> LoginScreen: Triggering native navigation IMMEDIATELY. Flag set to true.');

                // *** Direct navigation call (NO addPostFrameCallback) ***
                Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (context) => const ActionSelectScreen()),
                );
                // *******************************************************

                debugPrint('>>> LoginScreen: Navigator.pushReplacement called.');
              } else {
                  debugPrint('LoginScreen: Native navigation skipped. Triggered: $_navigationTriggered, Mounted: $mounted');
              }
            } else {
                debugPrint('LoginScreen: URL does NOT match target for navigation or auto-login trigger.');
                 if (widget.performAutoLogin && _autoLoginAttempted) {
                    debugPrint('LoginScreen: Auto-login attempted but finished on unexpected URL: "$url"');
                 }
            }
             debugPrint('LoginScreen: ===== /onPageFinished =====');
          }, // End of onPageFinished

          onWebResourceError: (WebResourceError error) {
            debugPrint('''LoginScreen: Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}''');
            if (mounted) {
              setState(() { loadingPercentage = 100; });
              if ((error.isForMainFrame ?? false) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load page: ${error.description}')),
                );
              }
            }
          }, // End of onWebResourceError

          // --- MODIFIED Navigation Request Logic ---
          onNavigationRequest: (NavigationRequest request) {
            // --- ADDED CHECK ---
            // If native navigation has already been triggered, block ALL further web navigation
            if (_navigationTriggered) {
              debugPrint('LoginScreen: Native navigation triggered, preventing further web request to: "${request.url}"');
              return NavigationDecision.prevent;
            }
            // --- END OF ADDED CHECK ---

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
              return NavigationDecision.prevent; // Block external
            }
          }, // End of onNavigationRequest
        ), // End of NavigationDelegate
      ) // End of setNavigationDelegate
      ..loadRequest(Uri.parse(_initialUrl)); // Load the initial URL
  } // End of initState method


  // --- Auto-Login Function ---
  Future<void> _attemptAutoLogin() async {
     setState(() { _autoLoginAttempted = true; });
     debugPrint("LoginScreen: Attempting auto-login via JavaScript injection.");

     final username = await _storageService.getUsername();
     final password = await _storageService.getPassword();

     if (username == null || password == null) {
       debugPrint("LoginScreen: Auto-login failed - Credentials not found.");
       await _storageService.setBiometricsEnabled(false);
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Inloggningsuppgifter saknas för auto-login.')),
         );
       }
       setState(() { _autoLoginAttempted = false; });
       return;
     }

     String js = """
       try {
         document.querySelector('input[name="login_email"]').value = '$username';
         document.querySelector('input[name="login_password"]').value = '$password';
         document.querySelector('button[type="submit"]').click();
         console.log('Auto-login JS executed successfully.');
       } catch (e) { console.error('Auto-login JS error:', e); }
     """;

     try {
        await _controller.runJavaScript(js);
        debugPrint("LoginScreen: Auto-login JavaScript injected.");
     } catch (e) {
         debugPrint("LoginScreen: Error running auto-login JavaScript: $e");
         setState(() { _autoLoginAttempted = false; });
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Automatiskt inloggningsfel. Försök manuellt.')),
           );
         }
     }
  } // End of _attemptAutoLogin


   // --- Prompt to Enable Biometrics ---
   Future<void> _promptToEnableBiometrics() async {
     bool canCheckBiometrics = false;
      try { canCheckBiometrics = await _localAuth.canCheckBiometrics; }
      on PlatformException catch (e) { debugPrint("Error checking biometrics support: $e"); }
      bool alreadyEnabled = await _storageService.areBiometricsEnabled();

      if (!canCheckBiometrics || alreadyEnabled || !mounted) {
        debugPrint("Skipping biometric prompt: canCheck=$canCheckBiometrics, alreadyEnabled=$alreadyEnabled, mounted=$mounted");
        return;
      }

     final bool? enable = await showDialog<bool>(
       context: context,
       barrierDismissible: false,
       builder: (BuildContext context) {
         return AlertDialog(
           title: const Text('Aktivera Snabb Inloggning?'),
           content: const Text('Vill du använda Face ID / Fingeravtryck för att logga in nästa gång? Du behöver ange ditt lösenord en gång till för att spara det säkert.'),
           actions: <Widget>[
             TextButton(
               child: const Text('Nej Tack'),
               onPressed: () => Navigator.of(context).pop(false), // Uses context correctly
             ),
             TextButton(
               child: const Text('Ja Tack'),
               onPressed: () => Navigator.of(context).pop(true), // Uses context correctly
             ),
           ],
         );
       },
     );

     if (enable == true && mounted) {
        final credentials = await _showCredentialEntryDialog();
        if (credentials != null && mounted) {
           try {
              await _storageService.saveCredentials(credentials['username']!, credentials['password']!);
              await _storageService.setBiometricsEnabled(true);
              debugPrint("Credentials saved and biometrics enabled.");
              ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Snabb inloggning aktiverad!')),);
           } catch (e) {
               debugPrint("Error saving credentials/enabling biometrics: $e");
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Kunde inte spara inställningar.')),
               );
           }
        } else { debugPrint("Credential entry cancelled or failed."); }
     } else { debugPrint("User declined biometric setup."); }
   } // End of _promptToEnableBiometrics


  // --- Dialog to re-enter credentials ---
  Future<Map<String, String>?> _showCredentialEntryDialog() async {
     final formKey = GlobalKey<FormState>();
     String? username; // Should be email based on field type
     String? password;
     // This return statement MUST end with a semicolon
     return await showDialog<Map<String, String>>(
        context: context, // Uses context correctly
        barrierDismissible: false,
        builder: (context) { // Uses context correctly
          return AlertDialog(
            title: const Text('Spara Inloggningsuppgifter'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextFormField(
                     decoration: const InputDecoration(labelText: 'E-post', hintText: 'Ange din e-postadress'),
                     keyboardType: TextInputType.emailAddress, autocorrect: false,
                     validator: (value) {
                        if (value == null || value.isEmpty) return 'Ange E-post';
                        bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
                        if (!emailValid) return 'Ange en giltig E-post';
                        return null;
                      },
                     onSaved: (value) => username = value,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                     decoration: const InputDecoration(labelText: 'Lösenord', hintText: 'Ange ditt lösenord'),
                     obscureText: true, autocorrect: false,
                     validator: (value) => value?.isEmpty ?? true ? 'Ange lösenord' : null,
                     onSaved: (value) => password = value,
                  ),
                ],
              ),
            ),
            actions: [
               TextButton(
                 child: const Text('Avbryt'),
                 onPressed: () => Navigator.of(context).pop(null), // Uses context correctly
               ),
               TextButton(
                 child: const Text('Spara'),
                 onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                       formKey.currentState!.save();
                       Navigator.of(context).pop({'username': username!, 'password': password!}); // Uses context correctly
                    }
                 }
               ),
            ],
          ); // End AlertDialog
        } // End builder
     ); // Semicolon is present
  } // End _showCredentialEntryDialog


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    debugPrint("LoginScreen build method running. AutoLogin: ${widget.performAutoLogin}, Attempted: $_autoLoginAttempted");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Kvalprak'),
         automaticallyImplyLeading: !widget.performAutoLogin,
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
  } // End build method

  // --- Dispose Method ---
  @override
  void dispose() {
    debugPrint("LoginScreen dispose method called.");
    super.dispose();
  }
} // End _LoginScreenState class