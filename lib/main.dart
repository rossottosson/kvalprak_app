// lib/main.dart
// MODIFIED FILE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';
import 'package:kvalprak_app/models/saved_checklist_log.dart';

// --- Import the new AppInitializerScreen ---
import 'package:kvalprak_app/screens/app_initializer_screen.dart';
// LoginScreen and ClinicSelectionScreen are now launched by AppInitializerScreen
import 'package:kvalprak_app/providers/checklist_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Essential for SharedPreferences & Hive before runApp
  await Hive.initFlutter();

  Hive.registerAdapter(ChecklistAdapter());
  Hive.registerAdapter(ChecklistItemAdapter());
  Hive.registerAdapter(SavedChecklistLogAdapter());

  await Hive.openBox<Checklist>('checklistsBox');
  await Hive.openBox<SavedChecklistLog>('savedLogsBox');

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChecklistProvider()..loadData(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryViolet = Color(0xFF6A1B9A); // Deep Purple Accent
    const Color secondaryTurquoise = Color(0xFF00AFAB); // Tealish

    return MaterialApp(
      title: 'Kvalprak App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryViolet,
          primary: primaryViolet,
          secondary: secondaryTurquoise,
          brightness: Brightness.light,
          // Define other colors if needed, e.g., for containers, error
          // onPrimary: Colors.white, // Color for text/icons on primary color
          // onSecondary: Colors.white, // Color for text/icons on secondary color
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryViolet,
          foregroundColor: Colors.white, // For title and icons
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white, // Explicitly set for title
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: IconThemeData(color: Colors.white), // For icons like back button
        ),
         elevatedButtonTheme: ElevatedButtonThemeData(
           style: ElevatedButton.styleFrom(
              backgroundColor: primaryViolet, // Default for most elevated buttons
              foregroundColor: Colors.white, // Text color on elevated buttons
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
           )
        ),
         textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryViolet, // Text color for text buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          )
        ),
         inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: primaryViolet, width: 2.0),
          ),
          floatingLabelStyle: TextStyle(color: primaryViolet), // For label when focused
        ),
        // Add CardTheme if you want consistent card styling
        cardTheme: CardThemeData(
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        ),
        // Add ListTileTheme for consistency
        listTileTheme: const ListTileThemeData(
            // iconColor: primaryViolet, // Example
            // dense: true, // Example
        ),
      ),
      // --- Set AppInitializerScreen as the home ---
      home: const AppInitializerScreen(),
      // Define routes if you prefer named routes and are using Navigator.pushNamed
      // routes: {
      //   '/login': (context) => const LoginScreen(),
      //   '/clinic_selection': (context) => const ClinicSelectionScreen(),
      //   // ... other routes for your app if needed
      // },
      debugShowCheckedModeBanner: false,
    );
  }
}