// lib/action_select_screen.dart
import 'package:flutter/material.dart';
import 'package:kvalprak_app/deviation_report_screen.dart';
import 'package:kvalprak_app/screens/checklists_overview_screen.dart';
import 'package:kvalprak_app/screens/saved_checklists_screen.dart'; // Import the new screen

class ActionSelectScreen extends StatelessWidget {
  const ActionSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme data for styling
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Define specific button colors
    const Color oxbloodRed = Color(0xFF8B0000);   // Oxblood Red
    const Color turquoise = Color(0xFF00AFAB);   // Turquoise
    final Color primaryColor = colorScheme.primary; // Use theme's primary (Violet)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kvalprak appen'),
        automaticallyImplyLeading: false, // No back button here
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/Vårdna_symbol_gröngrå.png',
                height: 180,
              ),
              const SizedBox(height: 200),

              // --- Deviation Report Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.warning_amber_rounded, size: 28),
                label: const Text('Rapportera avvikelse'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: textTheme.titleLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: oxbloodRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  debugPrint('Navigating to Deviation Report Screen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeviationReportScreen()),
                  );
                },
              ),

              const SizedBox(height: 30), // Spacing between buttons

              // --- Checklists Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.checklist_rtl_rounded, size: 28),
                label: const Text('Checklistor'),
                  style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: textTheme.titleLarge,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: turquoise,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                    debugPrint('Navigating to Checklists Overview Screen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChecklistsOverviewScreen()),
                    );
                },
              ),

              // --- ADDED: Saved History Button ---
              const SizedBox(height: 30), // Spacing between buttons

              ElevatedButton.icon(
                icon: const Icon(Icons.history_rounded, size: 28), // History icon
                label: const Text('Sparad Historik'),
                  style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: textTheme.titleLarge,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Use primary color for this button
                  backgroundColor: primaryColor,
                  foregroundColor: colorScheme.onPrimary, // Text color on primary
                ),
                onPressed: () {
                    debugPrint('Navigating to Saved Checklists Screen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedChecklistsScreen()),
                    );
                },
              ),
              // --- END ADDED ---

            ],
          ),
        ),
      ),
    );
  }
}