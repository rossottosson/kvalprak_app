// lib/action_select_screen.dart
// UPPDATERAD: Anropar nu AuthService.logout() för en konsekvent utloggning.

import 'package:flutter/material.dart';
import 'package:kvalprak_app/screens/deviation_form_screen.dart';
import 'package:kvalprak_app/screens/checklists_overview_screen.dart';
import 'package:kvalprak_app/screens/main_menus_screen.dart';
import 'package:kvalprak_app/screens/todo_lists_screen.dart';
import 'package:kvalprak_app/services/auth_service.dart'; // Ny import
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/screens/clinic_selection_screen.dart';

class ActionSelectScreen extends StatelessWidget {
  const ActionSelectScreen({super.key});

  Future<void> _confirmChangeClinic(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Byt klinik'),
          content: const Text('Är du säker på att du vill byta klinik? Detta kommer att logga ut dig och du måste välja en ny klinik för att fortsätta.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Avbryt'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Byt klinik'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      // ANVÄND DEN KONSEKVENTA LOGOUT-METODEN
      await AuthService().logout();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ClinicSelectionScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const Color oxbloodRed = Color(0xFF8B0000);
    const Color turquoise = Color(0xFF00AFAB);
    const Color todoGreen = Color(0xFF2E7D32);
    final Color primaryColor = colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String?>(
          future: UrlService.getSelectedClinicName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0));
            } else if (snapshot.hasData && snapshot.data != null) {
              return Text(snapshot.data!, overflow: TextOverflow.ellipsis);
            }
            return const Text('Vårdna');
          },
        ),
        automaticallyImplyLeading: false,
        leading: Tooltip(
          message: "Byt klinik / Logga ut",
          child: IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              _confirmChangeClinic(context);
            },
          ),
        ),
        actions: const [],
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
                'assets/images/logo.png',
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("Error loading logo in ActionSelectScreen: $error");
                  return const SizedBox(
                      height: 150,
                      child: Center(child: Icon(Icons.broken_image_rounded, size: 60, color: Colors.grey)));
                },
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                icon: const Icon(Icons.warning_amber_rounded, size: 28),
                label: const Text('Rapportera avvikelse'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
                  backgroundColor: oxbloodRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  debugPrint('Navigating to NATIVE Deviation Form Screen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeviationFormScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.checklist_rtl_rounded, size: 28),
                label: const Text('Checklistor'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
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
              const SizedBox(height: 20),
              // NY KNAPP FÖR DOKUMENT
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_copy_outlined, size: 28),
                label: const Text('Dokument'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
                  backgroundColor: primaryColor, // Använder appens primära lila färg
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  debugPrint('Navigating to Main Menus Screen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MainMenusScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.task_alt_rounded, size: 28),
                label: const Text('Att göra'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
                  backgroundColor: todoGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  debugPrint('Navigating to Todo Lists Screen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TodoListsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}