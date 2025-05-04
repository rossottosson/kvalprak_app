import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Keep provider import
// Removed the incorrect import for auth_check_screen.dart
// Import LoginScreen if it's not implicitly found (usually not needed if in same project)
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart'; // Keep your provider import

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Wrap the app with the Provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChecklistProvider(), // Create instance of your provider
      child: const MyApp(), // Your original root widget
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define new colors
    const Color primaryViolet = Color(0xFF6A1B9A); // CHANGE: New primary violet color
    const Color secondaryTurquoise = Color(0xFF00AFAB); // CHANGE: New secondary turquoise color

    return MaterialApp(
      title: 'Kvalprak App',
      theme: ThemeData(
        // CHANGE: Updated color scheme using new seed/primary/secondary colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryViolet,      // Use violet as seed
          primary: primaryViolet,         // Explicitly set primary to violet
          secondary: secondaryTurquoise, // Explicitly set secondary to turquoise
          // You might need to adjust onPrimary, onSecondary etc. if contrast is poor,
          // but fromSeed usually handles this well. Let's assume default is okay for now.
          brightness: Brightness.light, // Or Brightness.dark based on your preference
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          // CHANGE: Updated AppBar background color
          backgroundColor: primaryViolet,
          // Keep foreground white, usually good contrast with violet
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
         // Ensure other theme components adapt or override if needed
         elevatedButtonTheme: ElevatedButtonThemeData( /* ... potentially adjust styles if needed ... */ ),
         textButtonTheme: TextButtonThemeData( /* ... potentially adjust styles if needed ... */ ),
         inputDecorationTheme: InputDecorationTheme( /* ... potentially adjust styles if needed ... */ ),
      ),
      // Ensure 'home' points directly to LoginScreen
      home: const LoginScreen(),
    );
  }
}