// lib/screens/checklist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';

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
    _commentsFocusNode.addListener(_saveCommentsOnUnfocus);
    debugPrint("ChecklistDetailScreen initState for ID: ${widget.checklistId}");
  }

  void _saveCommentsOnUnfocus() {
    if (!_commentsFocusNode.hasFocus && mounted && _isInitialized) {
      debugPrint("Comments field unfocused, saving comments...");
      final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
      final newComment = _commentsController.text.trim();
      checklistProvider.updateChecklistComments(widget.checklistId, newComment);
    }
  }

  @override
  void dispose() {
    debugPrint("ChecklistDetailScreen dispose for ID: ${widget.checklistId}");
    _commentsFocusNode.removeListener(_saveCommentsOnUnfocus);
    // Save one last time only if initialized and mounted
    if (_isInitialized && mounted) {
       debugPrint("Saving comments final time on dispose...");
       final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
       checklistProvider.updateChecklistComments(widget.checklistId, _commentsController.text.trim());
    }
    _commentsController.dispose();
    _commentsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklistProvider = context.watch<ChecklistProvider>();
    final Checklist? checklist = checklistProvider.findChecklistById(widget.checklistId);

    if (checklist != null && !_isInitialized) {
      _commentsController.text = checklist.comments ?? '';
      _isInitialized = true;
      debugPrint("Comments controller initialized with: '${checklist.comments ?? ''}'");
    }

    if (checklist == null) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Checklistan kunde inte hittas (kanske borttagen).'), duration: Duration(seconds: 2)),
            );
            Navigator.of(context).pop();
          }
       });
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(checklist.title),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Progress Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: checklist.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(checklist.progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Checklist Items List Section
            Expanded(
              child: ListView.builder(
                itemCount: checklist.items.length,
                itemBuilder: (context, index) {
                  final ChecklistItem item = checklist.items[index];
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
              ),
            ),
            const Divider(height: 1),

            // Comments Section
            Padding(
              padding: const EdgeInsets.all(16.0), // Padding around text field
              child: TextField(
                controller: _commentsController,
                focusNode: _commentsFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Kommentarer',
                  hintText: 'Lägg till eventuella kommentarer här...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4, // Allow more lines
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // *** ADDED: SizedBox for bottom spacing ***
            const SizedBox(height: 20.0), // Adjust height as needed
            // *** END ADDED ***

          ], // End Column children
        ),
      ),
    );
  }
}