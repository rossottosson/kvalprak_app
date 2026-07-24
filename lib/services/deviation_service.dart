// lib/services/deviation_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kvalprak_app/models/deviation_field.dart';
import 'package:kvalprak_app/models/deviation_form_data.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kvalprak_app/services/api_service.dart'; 
import 'package:kvalprak_app/services/auth_service.dart';

void logLong(String text, {int chunkSize = 800}) {
  final pattern = RegExp('.{1,$chunkSize}', dotAll: true);
  for (final match in pattern.allMatches(text)) {
    debugPrint(match.group(0));
  }
}

class DeviationService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<DeviationFormData> getDeviationFields({int page = 1}) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/fields');
    
    final response = await _apiService.post(url, body: {'page': page});

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
    required String deviationId,
    required XFile file,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/upload');
    
    String? token = await _authService.getToken();
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['id'] = deviationId;
    request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: file.name));

    try {
      var response = await request.send();
      
      if (response.statusCode == 401) {
        debugPrint('Token gick ut vid filuppladdning. Försöker förnya osynligt...');
        
        // 1. Ta emot den nya nyckeln direkt
        String? newToken = await _authService.trySilentRefreshToken();
        
        // 2. Kolla om vi fick en nyckel (istället för att kolla efter 'true')
        if (newToken != null) {
          var newRequest = http.MultipartRequest('POST', url);
          
          // 3. Använd newToken direkt här!
          newRequest.headers['Authorization'] = 'Bearer $newToken';
          newRequest.fields['id'] = deviationId;
          newRequest.files.add(await http.MultipartFile.fromPath('file', file.path, filename: file.name));
          
          response = await newRequest.send();
        } else {
          // Om refresh misslyckas helt, kasta ett fel så appen kan logga ut
          throw Exception("Session expired during upload");
        }
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

  Future<bool> submitDeviation({required Map<String, dynamic> submissionData}) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/deviation/add');
    
    final response = await _apiService.post(url, body: submissionData);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte skicka in avvikelse. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }
}