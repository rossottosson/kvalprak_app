// lib/models/checklist.dart
import 'package:uuid/uuid.dart';
import 'checklist_item.dart';

class Checklist {
  final String id;
  String title;
  List<ChecklistItem> items;
  // --- ADDED COMMENTS FIELD ---
  String? comments; // Nullable string for comments

  Checklist({
    required this.id,
    required this.title,
    required this.items,
    this.comments, // Add to constructor
  });

  // Factory constructor for creating new checklists with unique IDs
  factory Checklist.newChecklist({required String title, required List<ChecklistItem> items}) {
     // Initialize comments as null or empty string if preferred
     return Checklist(id: const Uuid().v4(), title: title, items: items, comments: null);
  }

  // Calculate completion progress
  double get progress {
    if (items.isEmpty) {
      return 0.0;
    }
    final checkedCount = items.where((item) => item.isChecked).length;
    return checkedCount / items.length;
  }

  // Method to easily create a copy with updated values
  Checklist copyWith({
    String? id,
    String? title,
    List<ChecklistItem>? items,
    String? comments, // Add comments here
    bool setCommentsToNull = false, // Flag to explicitly set comments to null if needed
  }) {
    return Checklist(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? List.from(this.items), // Create a new list copy
      // Handle comments update carefully respecting nullability
      comments: setCommentsToNull ? null : (comments ?? this.comments),
    );
  }
}