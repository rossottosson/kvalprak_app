// lib/models/checklist.dart
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart'; // Import Hive
import 'checklist_item.dart'; // Keep this import

// Add this line for the generated file
part 'checklist.g.dart';

// Add HiveType annotation with a unique typeId (e.g., 0 - must be different from ChecklistItem's typeId)
@HiveType(typeId: 0)
class Checklist extends HiveObject { // Extend HiveObject

  // Add HiveField annotations with unique indices (0, 1, 2, 3)
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  // Ensure the type is explicitly List<ChecklistItem> for Hive
  @HiveField(2)
  List<ChecklistItem> items;

  @HiveField(3)
  String? comments;

  Checklist({
    required this.id,
    required this.title,
    required this.items,
    this.comments,
  });

  // Factory constructor remains the same
  factory Checklist.newChecklist({required String title, required List<ChecklistItem> items}) {
     return Checklist(id: const Uuid().v4(), title: title, items: items, comments: null);
  }

  // Calculate completion progress (remains the same)
  double get progress {
    if (items.isEmpty) {
      return 0.0;
    }
    final checkedCount = items.where((item) => item.isChecked).length;
    return checkedCount / items.length;
  }

  // copyWith remains the same
  Checklist copyWith({
    String? id,
    String? title,
    List<ChecklistItem>? items,
    String? comments,
    bool setCommentsToNull = false,
  }) {
    return Checklist(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? List.from(this.items),
      comments: setCommentsToNull ? null : (comments ?? this.comments),
    );
  }
}