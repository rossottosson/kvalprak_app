// lib/models/deviation_field.dart
class DeviationField {
  final String id;
  final String title;
  final String description;
  final String inputType;
  final bool isRequired;
  final Map<String, dynamic> options;

  DeviationField({
    required this.id,
    required this.title,
    required this.description,
    required this.inputType,
    required this.isRequired,
    this.options = const {},
  });

  factory DeviationField.fromJson(String id, Map<String, dynamic> json) {
    final String req = json['required']?.toString().trim() ?? '0';
    final String reqKval = json['required_kvalprak']?.toString().trim() ?? '0';

    final bool requiredValue = req == '2' || reqKval == '1';

    return DeviationField(
      id: id,
      title: json['title'] ?? 'Okänd Titel',
      description: json['description'] ?? '',
      inputType: json['input'] ?? 'string',
      isRequired: requiredValue,
      options: json['options'] ?? {},
    );
  }
}