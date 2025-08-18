// lib/services/deviation_service.dart
// UPPDATERAD: Hanterar nu session timeouts (status 401) med ett eget undantag.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kvalprak_app/models/deviation_field.dart';
import 'package:kvalprak_app/models/deviation_form_data.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:image_picker/image_picker.dart';

// Eget undantag för att hantera session timeouts
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(this.message);
  @override
  String toString() => message;
}

void logLong(String text, {int chunkSize = 800}) {
  final pattern = RegExp('.{1,$chunkSize}', dotAll: true);
  for (final match in pattern.allMatches(text)) {
    debugPrint(match.group(0));
  }
}

class DeviationService {
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
    
    if (response.statusCode == 401) {
      throw SessionExpiredException('Sessionen har gått ut.');
    }

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
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['id'] = deviationId;
    request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: file.name));

    try {
      final response = await request.send();
      
      if (response.statusCode == 401) {
         throw SessionExpiredException('Sessionen har gått ut.');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseBody = await http.Response.fromStream(response);
        debugPrint('Filuppladdning misslyckades. Status: ${response.statusCode}, Svar: ${responseBody.body}');
        return false;
      }
    } catch (e) {
      debugPrint("Allvarligt fel vid filuppladdning: $e");
      rethrow;
    }
  }

  Future<bool> submitDeviation({
    required String token,
    required Map<String, dynamic> submissionData,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/add');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode(submissionData),
    );

    if (response.statusCode == 401) {
      throw SessionExpiredException('Sessionen har gått ut.');
    }

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      print('Kunde inte skicka in avvikelse. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }
}