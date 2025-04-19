// lib/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kvalprak_app/login_screen.dart'; // Your WebView login screen
import 'package:kvalprak_app/secure_storage_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final SecureStorageService _storageService = SecureStorageService();
  _SupportState _supportState = _SupportState.unknown;
  bool _isLoading = true;
  bool _biometricsAvailable = false;
  bool _canUseBiometrics = false; // Stored credentials AND biometrics enabled

  @override
  void initState() {
    super.initState();
    _checkDeviceSupportAndCredentials();
  }

  Future<void> _checkDeviceSupportAndCredentials() async {
    bool isSupported = await _auth.isDeviceSupported();
    bool hasCreds = await _storageService.hasCredentials();
    bool bioEnabled = await _storageService.areBiometricsEnabled();
    List<BiometricType> availableBiometrics = [];
    if (isSupported) {
       try {
         availableBiometrics = await _auth.getAvailableBiometrics();
       } on PlatformException catch (e) {
          debugPrint("Error getting available biometrics: $e");
       }
    }


    setState(() {
      _supportState = isSupported ? _SupportState.supported : _SupportState.unsupported;
      _biometricsAvailable = availableBiometrics.isNotEmpty;
      _canUseBiometrics = hasCreds && bioEnabled && _biometricsAvailable;
      _isLoading = false;
    });

     // If biometrics aren't possible OR not enabled/setup, go straight to webview login
    if (!_canUseBiometrics && !hasCreds && mounted) {
        _navigateToWebViewLogin(autoLogin: false);
    }
  }

  Future<void> _authenticateAndLogin() async {
    bool authenticated = false;
    try {
      setState(() { _isLoading = true; }); // Show loading indicator
      authenticated = await _auth.authenticate(
          localizedReason: 'Logga in med Face ID / Fingeravtryck',
          options: const AuthenticationOptions(
            stickyAuth: true, // Keep prompt alive if app goes to background
            biometricOnly: false, // Allow device passcode as fallback
          ));
       setState(() { _isLoading = false; });
    } on PlatformException catch (e) {
      debugPrint('Error during authentication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentiseringsfel: ${e.message}')),
      );
       setState(() { _isLoading = false; });
      return;
    }

    if (authenticated && mounted) {
      debugPrint("Biometric authentication successful.");
       // Navigate to WebView login screen with flag/credentials to auto-login
      _navigateToWebViewLogin(autoLogin: true);
    } else {
       debugPrint("Biometric authentication failed or cancelled.");
    }
  }

 void _navigateToWebViewLogin({required bool autoLogin}) {
     // Use pushReplacement to prevent coming back here with the back button
     Navigator.of(context).pushReplacement(MaterialPageRoute(
       builder: (context) => LoginScreen(performAutoLogin: autoLogin),
     ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kvalprak Autentisering')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_supportState == _SupportState.unsupported)
                      const Text("Den här enheten stöder inte biometri."),
                    if (_canUseBiometrics) ...[
                       const Icon(Icons.fingerprint, size: 80),
                       const SizedBox(height: 30),
                       ElevatedButton.icon(
                         icon: const Icon(Icons.face), // Or Icons.fingerprint
                         label: const Text('Logga in med Biometri'),
                         onPressed: _authenticateAndLogin,
                         style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                       ),
                       const SizedBox(height: 20),
                       const Text("eller", textAlign: TextAlign.center),
                       const SizedBox(height: 20),
                    ],
                    // Always show password login as an option if biometrics fail or aren't setup
                    ElevatedButton(
                       child: const Text('Logga in med Lösenord (Web)'),
                       onPressed: () => _navigateToWebViewLogin(autoLogin: false),
                       style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}