// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- ADD IMPORTS FOR MODELS AND GENERATED ADAPTERS ---
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';
import 'package:kvalprak_app/models/saved_checklist_log.dart';

// --- END IMPORTS ---

import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // --- REGISTER ADAPTERS (Uncomment/Add these lines) ---
  // Ensure the typeIds match those defined in your models (0, 1, 2)
  Hive.registerAdapter(ChecklistAdapter());
  Hive.registerAdapter(ChecklistItemAdapter());
  Hive.registerAdapter(SavedChecklistLogAdapter());
  // --- END REGISTER ADAPTERS ---

  // --- OPEN HIVE BOXES (Uncomment/Add these lines) ---
  // Use unique names for your boxes
  await Hive.openBox<Checklist>('checklistsBox');
  await Hive.openBox<SavedChecklistLog>('savedLogsBox');
  // --- END OPEN BOXES ---


  runApp(
    ChangeNotifierProvider(
      // --- UPDATE PROVIDER CREATION ---
      // Create the provider and immediately call loadData
      create: (context) => ChecklistProvider()..loadData(),
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
         elevatedButtonTheme: ElevatedButtonThemeData( /* ... */ ),
         textButtonTheme: TextButtonThemeData( /* ... */ ),
         inputDecorationTheme: InputDecorationTheme( /* ... */ ),
      ),
      home: const LoginScreen(),
    );
  }
}