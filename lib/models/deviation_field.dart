// lib/models/deviation_field.dart
// UPPDATERAD: Med den slutgiltiga, korrekta regeln för obligatoriska fält.

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
    // KORREKT LOGIK: Enligt specifikationen från teamet.
    final bool requiredValue = json['required'] == '2' || 
                               json['required_kvalprak'] == '1';

    if (requiredValue) {
      print("Fältet '${json['title']}' har markerats som obligatoriskt.");
    }

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