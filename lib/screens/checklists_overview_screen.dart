// lib/screens/checklists_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/screens/checklist_detail_screen.dart';
import 'package:kvalprak_app/screens/create_checklist_screen.dart';
import 'package:kvalprak_app/models/checklist.dart'; // Import model for type hinting

class ChecklistsOverviewScreen extends StatelessWidget {
  const ChecklistsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in ChecklistProvider
    return Consumer<ChecklistProvider>(
      builder: (context, checklistProvider, child) {
        final List<Checklist> checklists = checklistProvider.checklists;
        final TextTheme textTheme = Theme.of(context).textTheme;
        final ColorScheme colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mina Checklistor'),
            leading: BackButton( // Ensure back button is present
               onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: checklists.isEmpty
              ? Center( // Center the empty message
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Inga checklistor skapade ännu.\nTryck på "+" för att skapa din första!',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  )
                )
              // --- Start of ListView Builder ---
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), // Named param 'padding'
                  itemCount: checklists.length, // Named param 'itemCount', accessing getter '.length'
                  itemBuilder: (context, index) { // Named param 'itemBuilder', correct function signature
                    // --- Start of itemBuilder content ---
                    final checklist = checklists[index];
                    final progress = checklist.progress;
                    final progressText = '${(progress * 100).toStringAsFixed(0)}%'; // toStringAsFixed(0) is correct

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 16.0, right: 4.0, top: 10.0, bottom: 10.0),
                        title: Text(
                          checklist.title,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                             value: progress,
                             minHeight: 6,
                             backgroundColor: Colors.grey[300],
                             valueColor: AlwaysStoppedAnimation<Color>(
                               colorScheme.primary.withOpacity(0.8)
                             ),
                             borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        trailing: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                              Text(
                                 progressText,
                                 style: textTheme.bodyMedium?.copyWith(
                                   color: colorScheme.primary,
                                   fontWeight: FontWeight.bold,
                                 )
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                 icon: const Icon(Icons.clear_all_rounded),
                                 tooltip: 'Nollställ checklista',
                                 iconSize: 22,
                                 visualDensity: VisualDensity.compact,
                                 color: Colors.orange[800],
                                 onPressed: checklist.items.any((item) => item.isChecked)
                                     ? () => _showClearConfirmation(context, checklistProvider, checklist.id)
                                     : null,
                              ),
                           ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChecklistDetailScreen(checklistId: checklist.id),
                            ),
                          );
                        },
                        onLongPress: () {
                           _showDeleteConfirmation(context, checklistProvider, checklist.id);
                        },
                      ),
                    );
                    // --- End of itemBuilder content ---
                  },
                  // --- End of ListView Builder arguments ---
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateChecklistScreen()),
              );
            },
            tooltip: 'Skapa ny checklista',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  // Helper function to show delete confirmation dialog
  Future<void> _showDeleteConfirmation(BuildContext context, ChecklistProvider provider, String checklistId) async {
     final navigator = Navigator.of(context);
     final messenger = ScaffoldMessenger.of(context);
     final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
           return AlertDialog(
              title: const Text('Bekräfta Borttagning'),
              content: const Text('Är du säker på att du vill ta bort denna checklista?'),
              actions: <Widget>[
                 TextButton(
                    child: const Text('Avbryt'),
                    onPressed: () => navigator.pop(false),
                 ),
                 TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Ta bort'),
                    onPressed: () => navigator.pop(true),
                 ),
              ],
           );
        },
     );

     if (confirm == true) {
        provider.deleteChecklist(checklistId);
        if (context.mounted) {
           messenger.showSnackBar(
              const SnackBar(content: Text('Checklista borttagen.'), duration: Duration(seconds: 1)),
           );
        }
     }
  } // End _showDeleteConfirmation

  // Helper function to show clear confirmation dialog
  Future<void> _showClearConfirmation(BuildContext context, ChecklistProvider provider, String checklistId) async {
     final navigator = Navigator.of(context);
     final messenger = ScaffoldMessenger.of(context);
     final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
           return AlertDialog(
              title: const Text('Bekräfta Nollställning'),
              content: const Text('Är du säker på att du vill avmarkera alla objekt i denna checklista?'),
              actions: <Widget>[
                 TextButton(
                    child: const Text('Avbryt'),
                    onPressed: () => navigator.pop(false),
                 ),
                 TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.orange[800]),
                    child: const Text('Nollställ'),
                    onPressed: () => navigator.pop(true),
                 ),
              ],
           );
        },
     );

     if (confirm == true) {
        provider.clearChecklistItems(checklistId);
        if (context.mounted) {
           messenger.showSnackBar(
              const SnackBar(content: Text('Checklista nollställd.'), duration: Duration(seconds: 1)),
           );
        }
     }
  } // End _showClearConfirmation

} // End ChecklistsOverviewScreen