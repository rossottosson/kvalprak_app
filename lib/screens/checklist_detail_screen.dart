// lib/screens/checklist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';
import 'package:kvalprak_app/models/saved_checklist_log.dart'; // Import the log model

class ChecklistDetailScreen extends StatefulWidget {
  final String checklistId;

  const ChecklistDetailScreen({required this.checklistId, super.key});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  late final TextEditingController _commentsController;
  final FocusNode _commentsFocusNode = FocusNode();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();
    // Don't add listener immediately, wait for checklist load
    debugPrint("ChecklistDetailScreen initState for ID: ${widget.checklistId}");
  }

  // Separate method to add listener once checklist is loaded
  void _initializeCommentsListener() {
    if (!_commentsFocusNode.hasListeners) {
       _commentsFocusNode.addListener(_saveCommentsOnUnfocus);
    }
  }

  void _saveCommentsOnUnfocus() {
    if (!_commentsFocusNode.hasFocus && mounted && _isInitialized) {
      debugPrint("Comments field unfocused, saving comments...");
      // Use context.read inside listener callbacks
      final checklistProvider = context.read<ChecklistProvider>();
      final newComment = _commentsController.text.trim();
      checklistProvider.updateChecklistComments(widget.checklistId, newComment);
    }
  }

  // --- ADDED: Method to handle saving the checklist state ---
  void _saveChecklistLog(Checklist checklist) {
    // Ensure comments are up-to-date before saving snapshot
    final currentComment = _commentsController.text.trim();
    // Update provider immediately if focused (or just use controller text directly)
    if (_commentsFocusNode.hasFocus) {
       context.read<ChecklistProvider>().updateChecklistComments(widget.checklistId, currentComment);
    }


    // Create snapshot of items
    final itemsSnapshot = checklist.items.map((item) => {
      'text': item.text,
      'isChecked': item.isChecked,
    }).toList();

    // Create the log entry
    final newLog = SavedChecklistLog.create(
      originalChecklistId: checklist.id,
      checklistTitle: checklist.title,
      itemsSnapshot: itemsSnapshot,
      commentsSnapshot: currentComment.isEmpty ? null : currentComment,
    );

    // Add log using provider
    context.read<ChecklistProvider>().addSavedLog(newLog);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text('"${checklist.title}" sparad i historik.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
       ),
    );
  }


  @override
  void dispose() {
    debugPrint("ChecklistDetailScreen dispose for ID: ${widget.checklistId}");
    // Save comments one last time ONLY if initialized and mounted
    if (_isInitialized && mounted && _commentsFocusNode.hasFocus) {
       debugPrint("Saving comments final time on dispose...");
       final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
       checklistProvider.updateChecklistComments(widget.checklistId, _commentsController.text.trim());
    }
     _commentsFocusNode.removeListener(_saveCommentsOnUnfocus);
    _commentsController.dispose();
    _commentsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use watch only when needed for rebuilds, otherwise use read/select
    final checklist = context.select<ChecklistProvider, Checklist?>(
      (provider) => provider.findChecklistById(widget.checklistId)
    );
    // Use a flag to prevent initializing multiple times if build runs again
    bool needsInitialization = checklist != null && !_isInitialized;


    // Post-frame callback for initialization/navigation if checklist is gone
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!mounted) return; // Check if widget is still mounted

       if (checklist == null && _isInitialized) { // Check if it disappeared AFTER initializing
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Checklistan kunde inte hittas (kanske borttagen).'), duration: Duration(seconds: 2)),
         );
         Navigator.of(context).pop();
       } else if (needsInitialization) {
          // Initialize controller and listener here, AFTER the first build
          _commentsController.text = checklist!.comments ?? '';
          _initializeCommentsListener(); // Add listener here
           // Set flag after successful initialization
          setState(() { _isInitialized = true; });
          debugPrint("Comments controller initialized with: '${checklist.comments ?? ''}'");
       }
    });

     if (checklist == null) {
      // Show loading indicator or handle differently if needed immediately
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
     }


    // Use a Consumer or context.watch where UI must react to checklist changes
    return Scaffold(
      appBar: AppBar(
        title: Text(checklist.title),
      ),
      // Use Listener to unfocus when tapping outside text fields
      body: Listener( // Changed from GestureDetector for potentially better focus handling
        onPointerDown: (_) { // unfocus when tapping down anywhere else
           FocusScopeNode currentFocus = FocusScope.of(context);
           if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
             FocusManager.instance.primaryFocus?.unfocus();
           }
        },
        child: Column(
          children: [
            // Progress Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    // Use Consumer only around the ProgressIndicator if needed
                    child: Consumer<ChecklistProvider>(
                        builder: (context, provider, child) {
                           // Find checklist again (or rely on outer 'checklist' variable if safe)
                           final currentChecklist = provider.findChecklistById(widget.checklistId);
                           final progress = currentChecklist?.progress ?? 0.0;
                            return LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                              borderRadius: BorderRadius.circular(4),
                            );
                        }
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Use Consumer only around the Text if needed
                   Consumer<ChecklistProvider>(
                      builder: (context, provider, child) {
                          final currentChecklist = provider.findChecklistById(widget.checklistId);
                           final progress = currentChecklist?.progress ?? 0.0;
                           return Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          );
                      }
                   ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Checklist Items List Section
            Expanded(
              // Use Consumer here as item status changes need rebuild
              child: Consumer<ChecklistProvider>(
                 builder: (context, provider, child) {
                   // Re-find checklist inside consumer to get latest state
                   final currentChecklist = provider.findChecklistById(widget.checklistId);
                   // Handle if checklist disappears mid-build (less likely now with outer checks)
                   if (currentChecklist == null) return const Center(child: Text("Checklist not found"));

                   return ListView.builder(
                      itemCount: currentChecklist.items.length,
                      itemBuilder: (context, index) {
                        final ChecklistItem item = currentChecklist.items[index];
                        return CheckboxListTile(
                          title: Text(
                            item.text,
                            style: TextStyle(
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: item.isChecked ? Colors.grey[600] : null,
                            ),
                          ),
                          value: item.isChecked,
                          onChanged: (bool? newValue) {
                            if (newValue != null) {
                              // Use context.read for actions within callbacks
                              context.read<ChecklistProvider>().updateItemStatus(
                                    widget.checklistId,
                                    item.id,
                                    newValue);
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    );
                  }
               )
            ),
            const Divider(height: 1),

            // Comments Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _commentsController,
                focusNode: _commentsFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Kommentarer',
                  hintText: 'Lägg till eventuella kommentarer här...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // --- ADDED: Save Button Section ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0), // Add padding
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_rounded), // Or Icons.check_circle_outline
                label: const Text('Spara Som Genomförd'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Make button wide
                  // Use primary color (Violet) or green for positive action? Let's use theme primary.
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                ),
                onPressed: () {
                  // Pass the currently built checklist state to the save function
                  _saveChecklistLog(checklist);
                },
              ),
            ),
            // --- END ADDED ---

            // Removed the extra SizedBox here, padding on button handles bottom space
          ],
        ),
      ),
    );
  }
}