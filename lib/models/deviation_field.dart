// lib/models/deviation_field.dart
// UPPDATERAD: Ny teori att "2" är obligatorisk + felsökningsutskrift.

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
    // NY TEORI: Ett fält är obligatoriskt om 'required' har värdet "2".
    final bool requiredValue = json['required'] == '2';

    // NY FELSÖKNING: Skriv ut vilka fält som tolkas som obligatoriska.
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