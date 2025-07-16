// lib/screens/app_initializer_screen.dart
// NEW FILE

import 'package:flutter/material.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/screens/clinic_selection_screen.dart';

class AppInitializerScreen extends StatefulWidget {
  const AppInitializerScreen({super.key});

  @override
  State<AppInitializerScreen> createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends State<AppInitializerScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // A small delay can be nice for the splash screen, but not strictly necessary.
    // await Future.delayed(const Duration(milliseconds: 300));

    bool isClinicAlreadySelected = await UrlService.isClinicSelected();

    if (mounted) { // Check if the widget is still in the tree
      if (isClinicAlreadySelected) {
        String? clinicName = await UrlService.getSelectedClinicName();
        debugPrint("AppInitializer: Clinic '${clinicName ?? 'N/A'}' already selected. Navigating to LoginScreen.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        debugPrint("AppInitializer: No clinic selected. Navigating to ClinicSelectionScreen.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ClinicSelectionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple splash screen UI
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
            const Text('Konfigurerar appen...'),
          ],
        ),
      ),
    );
  }
}