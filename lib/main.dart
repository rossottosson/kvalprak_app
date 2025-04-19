// lib/main.dart
import 'package:flutter/material.dart';
import 'package:kvalprak_app/auth_check_screen.dart'; // <-- New entry point

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kvalprak App',
      theme: ThemeData( // Keep your theme
         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005A9C)),
         useMaterial3: true,
          appBarTheme: const AppBarTheme( /* ... */ ),
          elevatedButtonTheme: ElevatedButtonThemeData( /* ... */ ),
      ),
      // Start with the screen that checks auth status
      home: const AuthCheckScreen(),
    );
  }
}