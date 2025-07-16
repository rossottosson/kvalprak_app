// lib/services/deviation_service.dart
// UPPDATERAD FÖR ATT HANTERA 'order' SOM EN STRÄNG

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kvalprak_app/models/deviation_field.dart';
import 'package:kvalprak_app/services/url_service.dart';

class DeviationService {
  /// Hämtar formulärfälten för en specifik sida i avvikelseprocessen.
  Future<List<DeviationField>> getDeviationFields({
    required String token,
    int page = 1,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/fields');

    print('Hämtar avvikelsefält från: $url med POST');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'page': page}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final fieldsData = data['fields'] as Map<String, dynamic>;

      final List<DeviationField> fields = [];
      fieldsData.forEach((key, value) {
        fields.add(DeviationField.fromJson(key, value));
      });
      
      // MODIFIERAD LOGIK:
      // Använder int.tryParse för att säkert omvandla 'order' från en sträng till ett tal.
      // Om 'order' saknas eller inte kan tolkas, används 0 som standard.
      fields.sort((a, b) {
        final orderA = int.tryParse(fieldsData[a.id]['order'].toString()) ?? 0;
        final orderB = int.tryParse(fieldsData[b.id]['order'].toString()) ?? 0;
        return orderA.compareTo(orderB);
      });

      return fields;
    } else {
      throw Exception('Kunde inte ladda avvikelsefält. Status: ${response.statusCode}, Svar: ${response.body}');
    }
  }

  /// Skickar in en ny avvikelserapport.
  Future<bool> submitDeviation({
    required String token,
    required Map<String, String> formData,
    int page = 1,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/add');

    print('Skickar in avvikelse till: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'page': page,
        'form_data': formData,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } else {
      print('Kunde inte skicka in avvikelse. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }
}