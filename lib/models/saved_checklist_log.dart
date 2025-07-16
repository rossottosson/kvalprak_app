// lib/models/saved_checklist_log.dart
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart'; // Import Hive

// Add this line for the generated file
part 'saved_checklist_log.g.dart';

// Add HiveType annotation with a unique typeId (e.g., 2 - must be different from others)
@HiveType(typeId: 2)
class SavedChecklistLog extends HiveObject { // Extend HiveObject

  // Add HiveField annotations with unique indices (0 to 5)
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalChecklistId;

  @HiveField(2)
  final String checklistTitle;

  @HiveField(3)
  final DateTime timestamp;

  // Hive needs to know the type of the Map values.
  // If they are mixed (String, bool), dynamic is okay, but be explicit.
  @HiveField(4)
  final List<Map<dynamic, dynamic>> itemsSnapshot; // Use Map<dynamic, dynamic>

  @HiveField(5)
  final String? commentsSnapshot;

  SavedChecklistLog({
    required this.id,
    required this.originalChecklistId,
    required this.checklistTitle,
    required this.timestamp,
    required this.itemsSnapshot,
    this.commentsSnapshot,
  });

  // Factory constructor remains the same
  factory SavedChecklistLog.create({
    required String originalChecklistId,
    required String checklistTitle,
    required List<Map<String, dynamic>> itemsSnapshot, // Keep dynamic here for input flexibility
    required String? commentsSnapshot,
  }) {
    return SavedChecklistLog(
      id: const Uuid().v4(),
      originalChecklistId: originalChecklistId,
      checklistTitle: checklistTitle,
      timestamp: DateTime.now(),
      // Ensure the map being stored matches the HiveField type Map<dynamic, dynamic>
      itemsSnapshot: List<Map<dynamic, dynamic>>.from(itemsSnapshot),
      commentsSnapshot: commentsSnapshot,
    );
  }
}