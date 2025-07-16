// lib/models/deviation_field.dart
// UPPDATERAD FÖR ATT HANTERA 'isRequired' SOM EN STRÄNG

/// Representerar ett enskilt fält i avvikelseformuläret.
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

  /// Skapar ett DeviationField från en JSON-mapp från API:et.
  factory DeviationField.fromJson(String id, Map<String, dynamic> json) {
    // MODIFIERAD LOGIK:
    // Denna logik hanterar nu om 'required' är en äkta bool (true),
    // en sträng ("true"), eller en siffra som sträng ("1").
    final bool requiredValue = json['required'] == true || 
                               json['required'] == 'true' || 
                               json['required'] == '1';

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