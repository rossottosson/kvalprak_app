// lib/models/todo_models.dart
// Modeller för Todolist-API:et (listor och items/uppgifter).

// Hjälpfunktion: tolkar ett värde som kan vara bool, "1"/"0", "true"/"false".
bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}

class TodoList {
  final String id;
  final String name;
  final String description;
  final String? usId;
  final String? repeatType;
  final String? repeatValue;
  final String? finishDate;
  final String? createdDate;
  final String? updatedDate;

  TodoList({
    required this.id,
    required this.name,
    required this.description,
    this.usId,
    this.repeatType,
    this.repeatValue,
    this.finishDate,
    this.createdDate,
    this.updatedDate,
  });

  factory TodoList.fromJson(Map<String, dynamic> json) {
    return TodoList(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Namnlös lista',
      description: json['description']?.toString() ?? '',
      usId: json['us_id']?.toString(),
      repeatType: json['repeat_type']?.toString(),
      repeatValue: json['repeat_value']?.toString(),
      finishDate: json['finish_date']?.toString(),
      createdDate: json['created_date']?.toString(),
      updatedDate: json['updated_date']?.toString(),
    );
  }
}

class TodoItem {
  final String id;
  final String todoListId;
  final String name;
  final String description;
  final String? responsibleUserId;
  final String? finishDate;
  final String priority; // low | medium | high
  final String status; // not_started | in_progress | waiting | clear | approved
  final bool isChecked;
  final String? checkedDate;
  final String? checkedUserId;
  final String comments;
  final String? connectedPageId;
  final String? connectedType;
  final String? createdDate;
  final String? updatedDate;
  final bool isArchived;
  final String? archivedDate;

  TodoItem({
    required this.id,
    required this.todoListId,
    required this.name,
    required this.description,
    this.responsibleUserId,
    this.finishDate,
    required this.priority,
    required this.status,
    required this.isChecked,
    this.checkedDate,
    this.checkedUserId,
    required this.comments,
    this.connectedPageId,
    this.connectedType,
    this.createdDate,
    this.updatedDate,
    required this.isArchived,
    this.archivedDate,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id']?.toString() ?? '',
      todoListId: json['todo_list_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Namnlös uppgift',
      description: json['description']?.toString() ?? '',
      responsibleUserId: json['responsible_user_id']?.toString(),
      finishDate: json['finish_date']?.toString(),
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'not_started',
      isChecked: _parseBool(json['is_checked']),
      checkedDate: json['checked_date']?.toString(),
      checkedUserId: json['checked_user_id']?.toString(),
      comments: json['comments']?.toString() ?? '',
      connectedPageId: json['connected_page_id']?.toString(),
      connectedType: json['connected_type']?.toString(),
      createdDate: json['created_date']?.toString(),
      updatedDate: json['updated_date']?.toString(),
      isArchived: _parseBool(json['is_archived']),
      archivedDate: json['archived_date']?.toString(),
    );
  }

  // Används för att uppdatera state lokalt (t.ex. vid i-/urbockning) utan att
  // behöva hämta om hela listan från servern.
  TodoItem copyWith({
    bool? isChecked,
    String? status,
    String? priority,
  }) {
    return TodoItem(
      id: id,
      todoListId: todoListId,
      name: name,
      description: description,
      responsibleUserId: responsibleUserId,
      finishDate: finishDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isChecked: isChecked ?? this.isChecked,
      checkedDate: checkedDate,
      checkedUserId: checkedUserId,
      comments: comments,
      connectedPageId: connectedPageId,
      connectedType: connectedType,
      createdDate: createdDate,
      updatedDate: updatedDate,
      isArchived: isArchived,
      archivedDate: archivedDate,
    );
  }
}

// Svenska etiketter och möjliga värden för prioritet och status.
class TodoLabels {
  static const Map<String, String> priorities = {
    'low': 'Låg',
    'medium': 'Medel',
    'high': 'Hög',
  };

  static const Map<String, String> statuses = {
    'not_started': 'Ej påbörjad',
    'in_progress': 'Pågående',
    'waiting': 'Väntar',
    'clear': 'Klar',
    'approved': 'Godkänd',
  };

  static String priorityLabel(String key) => priorities[key] ?? key;
  static String statusLabel(String key) => statuses[key] ?? key;
}
