// lib/action_select_screen.dart
import 'package:flutter/material.dart';
// Import the next screen
import 'deviation_report_screen.dart';

class ActionSelectScreen extends StatelessWidget {
  const ActionSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme colors for styling
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Välj Åtgärd'),
        automaticallyImplyLeading: false, // Remove back button on this screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center( // Center the column content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch horizontally
            children: <Widget>[
              // --- Deviation Report Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.warning_amber_rounded), // Example icon
                label: const Text('Rapportera avvikelse'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder( // Softer corners
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  debugPrint('Navigating to Deviation Report Screen');
                  // Navigate to the Deviation Report WebView Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeviationReportScreen()),
                  );
                },
              ),

              const SizedBox(height: 25), // Spacing between buttons

              // --- Checklists Button (Placeholder) ---
              ElevatedButton.icon(
                icon: const Icon(Icons.checklist_rtl_rounded), // Example icon
                label: const Text('Checklistor'),
                 style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Optional: Style differently if disabled or placeholder
                  backgroundColor: colorScheme.secondary, // Use accent color maybe
                  foregroundColor: colorScheme.onSecondary,
                ),
                onPressed: () {
                   debugPrint('Checklistor action tapped (Not Implemented)');
                   // Show a temporary message
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('Checklistor är inte implementerade än.'),
                       duration: Duration(seconds: 2),
                     ),
                   );
                   // TODO: Implement navigation or action for Checklistor
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}