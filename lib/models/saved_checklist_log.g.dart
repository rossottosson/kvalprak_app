// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_checklist_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedChecklistLogAdapter extends TypeAdapter<SavedChecklistLog> {
  @override
  final int typeId = 2;

  @override
  SavedChecklistLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedChecklistLog(
      id: fields[0] as String,
      originalChecklistId: fields[1] as String,
      checklistTitle: fields[2] as String,
      timestamp: fields[3] as DateTime,
      itemsSnapshot: (fields[4] as List)
          .map((dynamic e) => (e as Map).cast<dynamic, dynamic>())
          .toList(),
      commentsSnapshot: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedChecklistLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalChecklistId)
      ..writeByte(2)
      ..write(obj.checklistTitle)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.itemsSnapshot)
      ..writeByte(5)
      ..write(obj.commentsSnapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedChecklistLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
