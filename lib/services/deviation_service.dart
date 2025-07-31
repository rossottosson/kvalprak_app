// lib/services/deviation_service.dart
// UPPDATERAD: Skickar med filens originalnamn vid uppladdning.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kvalprak_app/models/deviation_field.dart';
import 'package:kvalprak_app/models/deviation_form_data.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:image_picker/image_picker.dart';

// ... (logLong-funktionen är oförändrad) ...
void logLong(String text, {int chunkSize = 800}) {
  final pattern = RegExp('.{1,$chunkSize}', dotAll: true);
  for (final match in pattern.allMatches(text)) {
    debugPrint(match.group(0));
  }
}

class DeviationService {
  // ... (getDeviationFields-metoden är oförändrad) ...
  Future<DeviationFormData> getDeviationFields({
    required String token,
    int page = 1,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/fields');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode({'page': page}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final fieldsData = data['fields'] as Map<String, dynamic>;
      final optionsData = data['options'] as Map<String, dynamic>? ?? {};
      final List<DeviationField> fields = [];
      fieldsData.forEach((key, value) {
        fields.add(DeviationField.fromJson(key, value));
      });
      fields.sort((a, b) {
        final orderA = int.tryParse(fieldsData[a.id]['order'].toString()) ?? 0;
        final orderB = int.tryParse(fieldsData[b.id]['order'].toString()) ?? 0;
        return orderA.compareTo(orderB);
      });
      return DeviationFormData(fields: fields, options: optionsData);
    } else {
      throw Exception('Kunde inte ladda avvikelsefält. Status: ${response.statusCode}, Svar: ${response.body}');
    }
  }


  Future<bool> uploadAttachment({
    required String token,
    required String deviationId,
    required XFile file,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/upload');
    
    logLong('Laddar upp fil till: $url för deviationId: $deviationId');

    var request = http.MultipartRequest('POST', url);
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['id'] = deviationId;

    // === HÄR ÄR ÄNDRINGEN ===
    // Vi lägger till parametern "filename" och skickar med originalnamnet (file.name)
    request.files.add(await http.MultipartFile.fromPath(
      'file', 
      file.path, 
      filename: file.name
    ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        debugPrint("Filuppladdning lyckades.");
        return true;
      } else {
        debugPrint('Filuppladdning misslyckades. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint("Allvarligt fel vid filuppladdning: $e");
      return false;
    }
  }

  // ... (submitDeviation-metoden är oförändrad) ...
  Future<bool> submitDeviation({
    required String token,
    required Map<String, dynamic> submissionData,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/add');
    logLong('Skickar in avvikelse till: $url');
    logLong('Skickar följande data: ${json.encode(submissionData)}');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(submissionData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      print('Kunde inte skicka in avvikelse. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }
}