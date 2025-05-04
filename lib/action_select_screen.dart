import 'package:flutter/material.dart';
import 'package:kvalprak_app/deviation_report_screen.dart';
import 'package:kvalprak_app/screens/checklists_overview_screen.dart'; // Import overview screen

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vårdna'),
        automaticallyImplyLeading: false, // No back button here
      ),
      body: SafeArea( // Ensure content respects device notches/insets
        // CHANGE: Removed the Center widget to allow top alignment
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Keep padding around the column
          child: Column(
            // CHANGE: Align content to the start (top) instead of center
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch horizontally
            children: <Widget>[
              const SizedBox(height: 20), // Adjust this height (e.g., 20) to move the logo down

              // --- Logo Image ---
              Image.asset(
                'assets/images/Vårdna_symbol_gröngrå.png', // Path declared in pubspec.yaml
                // CHANGE: Increased height to make the logo bigger
                height: 200,
              ),
              // CHANGE: Slightly increased spacing below logo for balance
              const SizedBox(height: 250),

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
              // Optional: Add a Spacer() here if you want to push buttons further down
              // const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}