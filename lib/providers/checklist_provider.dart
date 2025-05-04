// lib/providers/checklist_provider.dart
import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';

class ChecklistProvider with ChangeNotifier {
  // Private list to hold checklists (in-memory for now)
  final List<Checklist> _checklists = [
    // Sample Data (optional)
    Checklist(id: 'sample1', title: 'Morgonrutin', items: [
       ChecklistItem(id: 's1i1', text: 'Bädda sängen', isChecked: true),
       ChecklistItem(id: 's1i2', text: 'Borsta tänderna'),
       ChecklistItem(id: 's1i3', text: 'Ät frukost'),
    ], comments: 'Kom ihåg vitaminer!'), // Added sample comment
     Checklist(id: 'sample2', title: 'Packa Väskan', items: [
       ChecklistItem(id: 's2i1', text: 'Dator'),
       ChecklistItem(id: 's2i2', text: 'Laddare'),
       ChecklistItem(id: 's2i3', text: 'Mus'),
    ]),
  ];

  // Public getter for the list
  List<Checklist> get checklists => List.unmodifiable(_checklists); // Return unmodifiable copy

  // Add a new checklist
  void addChecklist(Checklist checklist) {
    _checklists.add(checklist);
    notifyListeners(); // Notify listeners about the change
  }

  // Find a checklist by its ID
  Checklist? findChecklistById(String id) {
     try {
       // Use firstWhereOrNull from collection package for cleaner null handling
       // Or stick with try-catch which is fine too.
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
        // Update specific item using copyWith
        updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(isChecked: isChecked);
        // Update the checklist in the list using copyWith
        _checklists[checklistIndex] = originalChecklist.copyWith(items: updatedItems);
        notifyListeners(); // Notify listeners
      }
    }
  }

  // Method to update comments
  void updateChecklistComments(String checklistId, String? newComments) {
     final checklistIndex = _checklists.indexWhere((cl) => cl.id == checklistId);
     if (checklistIndex != -1) {
        // Use copyWith to update comments (handles null correctly)
        final trimmedComment = newComments?.trim(); // Trim whitespace
        // Only update if changed? Optional optimization.
        _checklists[checklistIndex] = _checklists[checklistIndex].copyWith(
           // Store null if trimmed comment is empty, otherwise store trimmed comment
           comments: (trimmedComment == null || trimmedComment.isEmpty) ? null : trimmedComment,
           // Use setCommentsToNull flag if you need explicit null setting separate from empty string
           // setCommentsToNull: trimmedComment == null
        );
        notifyListeners();
        debugPrint("Updated comments for $checklistId");
     }
  }

  // *** THIS METHOD WAS LIKELY MISSING OR MISSPELLED ***
  // Method to clear/uncheck all items
  void clearChecklistItems(String checklistId) {
    final checklistIndex = _checklists.indexWhere((cl) => cl.id == checklistId);
    if (checklistIndex != -1) {
      final originalChecklist = _checklists[checklistIndex];
      // Create a new list with all items unchecked
      final clearedItems = originalChecklist.items
          .map((item) => item.copyWith(isChecked: false)) // Set isChecked to false
          .toList();

      // Update the checklist with the new items list using copyWith
      _checklists[checklistIndex] = originalChecklist.copyWith(items: clearedItems);
      notifyListeners(); // Notify listeners
      debugPrint("Cleared items for $checklistId");
    }
  }
  // ****************************************************

  // Delete a checklist
   void deleteChecklist(String id) {
    _checklists.removeWhere((checklist) => checklist.id == id);
    notifyListeners();
  }

} // End ChecklistProvider