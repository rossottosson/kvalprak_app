// lib/providers/checklist_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart'; // Import Hive
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';
import 'package:kvalprak_app/models/saved_checklist_log.dart';

class ChecklistProvider with ChangeNotifier {

  // --- HIVE BOX NAMES (Match names used in main.dart) ---
  static const String _checklistsBoxName = 'checklistsBox';
  static const String _savedLogsBoxName = 'savedLogsBox';

  // --- Replace in-memory lists with references to Hive boxes ---
  // These will be initialized in loadData
  late Box<Checklist> _checklistsBox;
  late Box<SavedChecklistLog> _savedLogsBox;

  // --- Keep local lists for easy access, but they are derived from Hive ---
  List<Checklist> _checklists = [];
  List<SavedChecklistLog> _savedLogs = [];

  // Public getters now return the local lists
  List<Checklist> get checklists => List.unmodifiable(_checklists);
  List<SavedChecklistLog> get savedLogs => List.unmodifiable(_savedLogs);

  // --- ADDED: Method to load data from Hive ---
  Future<void> loadData() async {
    // Get references to the already opened boxes
    _checklistsBox = Hive.box<Checklist>(_checklistsBoxName);
    _savedLogsBox = Hive.box<SavedChecklistLog>(_savedLogsBoxName);

    // Load data into local lists
    _checklists = _checklistsBox.values.toList();
    // Sort logs by timestamp descending (newest first) after loading
    _savedLogs = _savedLogsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort newest first

    debugPrint("ChecklistProvider: Loaded ${_checklists.length} checklists and ${_savedLogs.length} logs from Hive.");

    // Important: Notify listeners after loading initial data
    notifyListeners();
  }

  // --- UPDATED: Methods to interact with Hive ---

  // Add a new checklist
  Future<void> addChecklist(Checklist checklist) async {
    // Add to Hive Box (use checklist.id as the key)
    await _checklistsBox.put(checklist.id, checklist);
    // Update local list
    _checklists = _checklistsBox.values.toList(); // Reload from box
    notifyListeners();
    debugPrint("Added checklist: ${checklist.title} to Hive.");
  }

  // Add a saved checklist log
  Future<void> addSavedLog(SavedChecklistLog log) async {
    // Add to Hive Box (use log.id as the key)
    await _savedLogsBox.put(log.id, log);
    // Update local list and re-sort
    _savedLogs = _savedLogsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
    debugPrint("Added saved log for checklist: ${log.checklistTitle} to Hive.");
  }

  // Find a checklist by its ID (can still use local list for reads)
  Checklist? findChecklistById(String id) {
    try {
      // Find in the local list (which is loaded from Hive)
      return _checklists.firstWhere((checklist) => checklist.id == id);
      // Alternatively, read directly from box: return _checklistsBox.get(id);
    } catch (e) {
      return null;
    }
  }

  // Update the status of an item within a specific checklist
  Future<void> updateItemStatus(String checklistId, String itemId, bool isChecked) async {
    final checklist = _checklistsBox.get(checklistId); // Get from Hive
    if (checklist != null) {
      final itemIndex = checklist.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        // Create a mutable copy of items
        final updatedItems = List<ChecklistItem>.from(checklist.items);
        // Update the specific item
        updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(isChecked: isChecked);
        // Create a new Checklist object with updated items
        final updatedChecklist = checklist.copyWith(items: updatedItems);

        // --- IMPORTANT: Save the updated checklist back to Hive ---
        await _checklistsBox.put(checklistId, updatedChecklist);

        // Update local list
        _checklists = _checklistsBox.values.toList();
        notifyListeners();
      }
    }
  }

  // Method to update comments
  Future<void> updateChecklistComments(String checklistId, String? newComments) async {
    final checklist = _checklistsBox.get(checklistId); // Get from Hive
    if (checklist != null) {
      final trimmedComment = newComments?.trim();
      final updatedChecklist = checklist.copyWith(
        comments: (trimmedComment == null || trimmedComment.isEmpty) ? null : trimmedComment,
        // Explicitly handle setting to null if needed, copyWith might need adjustment
        // setCommentsToNull: (trimmedComment == null || trimmedComment.isEmpty)
      );

      // --- IMPORTANT: Save the updated checklist back to Hive ---
      await _checklistsBox.put(checklistId, updatedChecklist);

      // Update local list
      _checklists = _checklistsBox.values.toList();
      notifyListeners();
      debugPrint("Updated comments for $checklistId in Hive.");
    }
  }

  // Method to clear/uncheck all items
  Future<void> clearChecklistItems(String checklistId) async {
    final checklist = _checklistsBox.get(checklistId); // Get from Hive
    if (checklist != null) {
      final clearedItems = checklist.items
          .map((item) => item.copyWith(isChecked: false))
          .toList();
      final updatedChecklist = checklist.copyWith(items: clearedItems);

      // --- IMPORTANT: Save the updated checklist back to Hive ---
      await _checklistsBox.put(checklistId, updatedChecklist);

      // Update local list
      _checklists = _checklistsBox.values.toList();
      notifyListeners();
      debugPrint("Cleared items for $checklistId in Hive.");
    }
  }

  // Delete a checklist
  Future<void> deleteChecklist(String id) async {
    // Delete from Hive
    await _checklistsBox.delete(id);

    // Optional: Delete associated logs if desired
    // final logsToDelete = _savedLogsBox.values.where((log) => log.originalChecklistId == id).toList();
    // for (var log in logsToDelete) {
    //   await _savedLogsBox.delete(log.id);
    // }

    // Update local lists
    _checklists = _checklistsBox.values.toList();
    // _savedLogs = _savedLogsBox.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Reload logs if they were deleted

    notifyListeners();
    debugPrint("Deleted checklist $id from Hive.");
  }

  // --- Optional: Close boxes when provider is disposed (if necessary) ---
  // @override
  // void dispose() {
  //   // Hive boxes usually stay open for the app's lifetime,
  //   // but you could close them here if needed.
  //   // Hive.close(); // Closes all boxes
  //   super.dispose();
  // }
}