// lib/models/checklist_item.dart
import 'package:uuid/uuid.dart';

class ChecklistItem {
  final String id;
  String text;
  bool isChecked;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
  });

  // Factory constructor for creating new items with unique IDs
  factory ChecklistItem.newItem({required String text}) {
    return ChecklistItem(id: const Uuid().v4(), text: text);
  }

  // Method to easily create a copy with updated values (useful for state management)
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