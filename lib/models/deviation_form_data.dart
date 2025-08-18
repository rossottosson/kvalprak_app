// lib/models/deviation_form_data.dart
import 'package:kvalprak_app/models/deviation_field.dart';

class DeviationFormData {
  final List<DeviationField> fields;
  final Map<String, dynamic> options;

  DeviationFormData({required this.fields, required this.options});
}