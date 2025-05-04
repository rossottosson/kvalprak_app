// lib/providers/checklist_provider.dart
import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';
import 'package:kvalprak_app/models/saved_checklist_log.dart'; // Import the new model

class ChecklistProvider with ChangeNotifier {
  // Private list to hold checklists (in-memory for now)
  final List<Checklist> _checklists = [
    // Sample Data (optional)
    Checklist(id: 'sample1', title: 'Morgonrutin', items: [
       ChecklistItem(id: 's1i1', text: 'Bädda sängen', isChecked: true),
       ChecklistItem(id: 's1i2', text: 'Borsta tänderna'),
       ChecklistItem(id: 's1i3', text: 'Ät frukost'),
    ], comments: 'Kom ihåg vitaminer!'),
     Checklist(id: 'sample2', title: 'Packa Väskan', items: [
       ChecklistItem(id: 's2i1', text: 'Dator'),
       ChecklistItem(id: 's2i2', text: 'Laddare'),
       ChecklistItem(id: 's2i3', text: 'Mus'),
    ]),
  ];

  // Private list for saved logs
  final List<SavedChecklistLog> _savedLogs = [];

  // Public getter for the checklist list
  List<Checklist> get checklists => List.unmodifiable(_checklists);

  // Public getter for the saved logs list
  List<SavedChecklistLog> get savedLogs => List.unmodifiable(_savedLogs);

  // --- METHOD RESTORED: Add a new checklist ---
  void addChecklist(Checklist checklist) {
    _checklists.add(checklist);
    notifyListeners(); // Notify listeners about the change
    debugPrint("Added checklist: ${checklist.title}");
  }
  // --- END RESTORED METHOD ---

  // Method to add a saved checklist log
  void addSavedLog(SavedChecklistLog log) {
    _savedLogs.insert(0, log);
    notifyListeners();
    debugPrint("Added saved log for checklist: ${log.checklistTitle}");
     // !! IMPORTANT: In a real app, you would save _savedLogs to persistent storage here !!
  }

  // Find a checklist by its ID
  Checklist? findChecklistById(String id) {
     try {
       return _checklists.firstWhere((checklist) => checklist.id == id);
     } catch (e) {
       return null; // Return null if not found
     }
  }

  // Update the status of an item within a specific checklist
  void updateItemStatus(String checklistId, String itemId, bool isChecked) {
    final checklistIndex = _checklists.indexWhere((cl) => cl.id == checklistId);
    if (checklistIndex != -1) {
      final itemIndex = _checklists[checklistIndex].items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final originalChecklist = _checklists[checklistIndex];
        final updatedItems = List<ChecklistItem>.from(originalChecklist.items);
        updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(isChecked: isChecked);
        _checklists[checklistIndex] = originalChecklist.copyWith(items: updatedItems);
        notifyListeners();
      }
    }
  }

  // Method to update comments
  void updateChecklistComments(String checklistId, String? newComments) {
     final checklistIndex = _checklists.indexWhere((cl) => cl.id == checklistId);
     if (checklistIndex != -1) {
        final trimmedComment = newComments?.trim();
        _checklists[checklistIndex] = _checklists[checklistIndex].copyWith(
           comments: (trimmedComment == null || trimmedComment.isEmpty) ? null : trimmedComment,
        );
        notifyListeners();
        debugPrint("Updated comments for $checklistId");
     }
  }

  // Method to clear/uncheck all items
  void clearChecklistItems(String checklistId) {
    final checklistIndex = _checklists.indexWhere((cl) => cl.id == checklistId);
    if (checklistIndex != -1) {
      final originalChecklist = _checklists[checklistIndex];
      final clearedItems = originalChecklist.items
          .map((item) => item.copyWith(isChecked: false))
          .toList();
      _checklists[checklistIndex] = originalChecklist.copyWith(items: clearedItems);
      notifyListeners();
      debugPrint("Cleared items for $checklistId");
    }
  }

  // Delete a checklist
   void deleteChecklist(String id) {
    _checklists.removeWhere((checklist) => checklist.id == id);
    // Optional: Handle associated saved logs if needed
    // _savedLogs.removeWhere((log) => log.originalChecklistId == id);
    notifyListeners();
  }

}