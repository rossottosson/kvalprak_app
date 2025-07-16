// lib/screens/saved_checklists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/models/saved_checklist_log.dart';

class SavedChecklistsScreen extends StatelessWidget {
  const SavedChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the logs from the provider
    final savedLogs = context.watch<ChecklistProvider>().savedLogs;
    final textTheme = Theme.of(context).textTheme;

    // Date and Time formatter (customize as needed)
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sparad Historik'),
         leading: BackButton( // Ensure back button is present
           onPressed: () => Navigator.of(context).pop(),
         ),
      ),
      body: savedLogs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Inga checklistor har sparats ännu.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: savedLogs.length,
              itemBuilder: (context, index) {
                final log = savedLogs[index];
                // Optional: Calculate completion percentage from snapshot if needed
                // final totalItems = log.itemsSnapshot.length;
                // final checkedItems = log.itemsSnapshot.where((item) => item['isChecked'] == true).length;
                // final progress = totalItems > 0 ? checkedItems / totalItems : 0.0;

                return Card(
                   margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                   elevation: 1.5,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                   child: ListTile(
                     leading: const Icon(Icons.history_toggle_off_rounded, color: Colors.grey), // Or Icons.task_alt
                     title: Text(
                        log.checklistTitle,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                     subtitle: Text(
                       'Sparad: ${formatter.format(log.timestamp)}', // Format timestamp
                       style: textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
                      ),
                     // Optional: Add trailing info or tap action
                     trailing: const Icon(Icons.chevron_right),
                     onTap: () {
                       // Optional: Navigate to a detail view showing the snapshot
                       _showLogDetails(context, log);
                       debugPrint('Tapped log: ${log.checklistTitle} @ ${log.timestamp}');
                     },
                   ),
                );
              },
            ),
    );
  }

  // --- Optional: Helper function to show log details ---
  Future<void> _showLogDetails(BuildContext context, SavedChecklistLog log) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(log.checklistTitle),
          content: SingleChildScrollView( // Ensure content is scrollable
            child: ListBody(
              children: <Widget>[
                Text('Sparad: ${formatter.format(log.timestamp)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Status vid sparning:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                // Display items snapshot
                ...log.itemsSnapshot.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Icon(
                          item['isChecked'] == true ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: item['isChecked'] == true ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item['text'] ?? 'N/A')),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 10),
                 const Text('Kommentarer vid sparning:', style: TextStyle(fontWeight: FontWeight.bold)),
                 const Divider(),
                Text(log.commentsSnapshot?.isNotEmpty ?? false ? log.commentsSnapshot! : 'Inga kommentarer'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Stäng'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

}