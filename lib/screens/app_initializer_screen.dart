// lib/screens/app_initializer_screen.dart

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/screens/clinic_selection_screen.dart';
import 'package:kvalprak_app/action_select_screen.dart'; // Ändra sökväg om den ligger någon annanstans

class AppInitializerScreen extends StatefulWidget {
  const AppInitializerScreen({super.key});

  @override
  State<AppInitializerScreen> createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends State<AppInitializerScreen> {
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    bool isClinicAlreadySelected = await UrlService.isClinicSelected();

    // 1. Har användaren ens valt en klinik ännu?
    if (!isClinicAlreadySelected) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ClinicSelectionScreen()),
        );
      }
      return;
    }

    bool hasToken = await _authService.hasSavedRefreshToken();

    // 2. Finns det en sparad session att försöka återuppliva?
    if (hasToken) {
      bool didAuthenticate = false;
      try {
        didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Lås upp Vårdna',
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        );
      } catch (e) {
        debugPrint('Face ID avbröts eller misslyckades: $e');
      }

      if (didAuthenticate) {
        // HÄR ÄR FIXEN: Vi gör en silent refresh precis som på inloggningsskärmen
        final String? newToken = await _authService.trySilentRefreshToken();

        if (mounted) {
          if (newToken != null) {
            // Token förnyades framgångsrikt (eller var redan giltig) - in i appen!
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ActionSelectScreen()),
            );
          } else {
            // Sessionen var helt död (t.ex. inaktiv för länge). Tvinga login.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
        return; 
      }
    }

    // 3. Om ingen token fanns, eller om Face ID avbröts, gå till vanliga inloggningen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/Vårdna_symbol_gröngrå.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => const SizedBox(height: 120, child: Icon(Icons.local_hospital, size: 80)),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Autentiserar...'),
          ],
        ),
      ),
    );
  }
}