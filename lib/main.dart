// lib/main.dart
// UPPDATERAD: Lade till DocumentProvider med MultiProvider.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

// Hive-importer är borttagna

import 'package:kvalprak_app/screens/app_initializer_screen.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/providers/document_provider.dart'; // Ny import
import 'package:kvalprak_app/providers/todo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // I release-bygget tystar vi all felsökningsloggning (debugPrint) så att
  // ingen känslig data (t.ex. tokens, e-post) hamnar i enhetens systemlogg.
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // All kod relaterad till Hive.initFlutter(), registerAdapter() och openBox() är borttagen.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChecklistProvider()),
        ChangeNotifierProvider(create: (context) => DocumentProvider()),
        ChangeNotifierProvider(create: (context) => TodoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryViolet = Color(0xFF6A1B9A);
    const Color secondaryTurquoise = Color(0xFF00AFAB);

    return MaterialApp(
      title: 'Kvalprak App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryViolet,
          primary: primaryViolet,
          secondary: secondaryTurquoise,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryViolet,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
          foregroundColor: primaryViolet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        )),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: primaryViolet, width: 2.0),
          ),
          floatingLabelStyle: TextStyle(color: primaryViolet),
        ),
        cardTheme: CardThemeData(
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        ),
        listTileTheme: const ListTileThemeData(),
      ),
      home: const AppInitializerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}