// lib/models/saved_checklist_log.dart
import 'package:uuid/uuid.dart';

class SavedChecklistLog {
  final String id;
  final String originalChecklistId;
  final String checklistTitle;
  final DateTime timestamp;
  // Store a snapshot of items and their status at the time of saving
  final List<Map<String, dynamic>> itemsSnapshot; // e.g., {'text': String, 'isChecked': bool}
  final String? commentsSnapshot; // Store comments at the time of saving

  SavedChecklistLog({
    required this.id,
    required this.originalChecklistId,
    required this.checklistTitle,
    required this.timestamp,
    required this.itemsSnapshot,
    this.commentsSnapshot,
  });

  // Factory constructor to easily create a new log entry
  factory SavedChecklistLog.create({
    required String originalChecklistId,
    required String checklistTitle,
    required List<Map<String, dynamic>> itemsSnapshot,
    required String? commentsSnapshot,
  }) {
    return SavedChecklistLog(
      id: const Uuid().v4(), // Generate unique ID
      originalChecklistId: originalChecklistId,
      checklistTitle: checklistTitle,
      timestamp: DateTime.now(), // Record current time
      itemsSnapshot: itemsSnapshot,
      commentsSnapshot: commentsSnapshot,
    );
  }
}