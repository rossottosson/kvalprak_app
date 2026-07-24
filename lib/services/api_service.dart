// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Smart GET-metod
  Future<http.Response> get(Uri url) async {
    String? token = await _authService.getToken();
    
    // 1. Gör det första anropet (Tog bort Accept-headern för att matcha originalet)
    var response = await http.get(
      url, 
      headers: {
        'Authorization': 'Bearer $token', 
      }
    );

    // 2. Om token har gått ut, försök förnya osynligt
    if (response.statusCode == 401) {
      print('Token gick ut under användning! Försöker förnya osynligt i bakgrunden...');

      String? newToken = await _authService.trySilentRefreshToken();

      if (newToken != null) {
        print('Session förnyad i smyg! Gör om anropet direkt med ny nyckel...');
        
        // Uppdatera response med det nya anropet
        response = await http.get(
          url, 
          headers: {
            'Authorization': 'Bearer $newToken', 
          }
        );

        // HÄR ÄR FIXEN FÖR ZOMBIE-SESSIONEN:
        // Om servern FORTFARANDE säger 401 med den helt nya nyckeln,
        // då vägrar servern prata med oss. Kasta ut användaren till login!
        if (response.statusCode == 401) {
          print('Den nya nyckeln nekades också! Kasta ut till login.');
          throw SessionExpiredException();
        }
      } else {
        // Förnyelsen misslyckades helt - kasta ut användaren
        throw SessionExpiredException();
      }
    }

    // 3. Validera att vi faktiskt fick JSON om servern säger OK
    if (response.statusCode == 200) {
      try {
        json.decode(response.body);
      } catch (e) {
        throw Exception("Servern skickade ett ogiltigt svar (Inte JSON).");
      }
    }

    return response;
  }

  // Smart POST-metod (för när du ska skicka in formulär/data)
  Future<http.Response> post(Uri url, {Map<String, dynamic>? body}) async {
    String? token = await _authService.getToken();
    
    var response = await http.post(
      url, 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 401) {
      print('Token gick ut vid POST! Försöker förnya osynligt...');
      
      String? newToken = await _authService.trySilentRefreshToken();

      if (newToken != null) {
        response = await http.post(
          url, 
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: body != null ? json.encode(body) : null,
        );

        // HÄR ÄR SÄKERHETSSPÄRREN IGEN:
        if (response.statusCode == 401) {
          print('Den nya nyckeln nekades vid POST! Kasta ut till login.');
          throw SessionExpiredException();
        }
      } else {
        throw SessionExpiredException();    
      }
    }

    if (response.statusCode == 200) {
      try {
        json.decode(response.body);
      } catch (e) {
        throw Exception("Servern skickade ett ogiltigt svar (Inte JSON).");
      }
    }

    return response;
  }
}