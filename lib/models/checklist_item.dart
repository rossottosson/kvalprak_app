// lib/models/checklist_item.dart
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart'; // Import Hive

// Add this line for the generated file
part 'checklist_item.g.dart';

// Add HiveType annotation with a unique typeId (e.g., 1)
@HiveType(typeId: 1)
class ChecklistItem extends HiveObject { // Extend HiveObject for easier updates later (optional but recommended)

  // Add HiveField annotations with unique indices (0, 1, 2)
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text; // Can be final if you only update via copyWith

  @HiveField(2)
  bool isChecked; // Can be final if you only update via copyWith

  ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
  });

  // Factory constructor remains the same
  factory ChecklistItem.newItem({required String text}) {
    return ChecklistItem(id: const Uuid().v4(), text: text);
  }

  // copyWith remains the same
   ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isChecked,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}