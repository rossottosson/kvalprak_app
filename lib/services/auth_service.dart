// lib/services/auth_service.dart
// FINAL VERSION: Korrekt hantering av 2FA-svaret från servern.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kvalprak_app/models/login_result.dart';
import 'package:kvalprak_app/services/url_service.dart';

// Funktion för att logga långa strängar
void logLong(String text, {int chunkSize = 800}) {
  final pattern = RegExp('.{1,$chunkSize}', dotAll: true);
  for (final match in pattern.allMatches(text)) {
    debugPrint(match.group(0));
  }
}

class AuthService {
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  Future<LoginResult> login(String email, String password, {String? otp, bool rememberMe = false}) async {
    try {
      final apiHost = await UrlService.getApiHost();
      final url = Uri.parse('https://$apiHost/api/auth/login');

      final Map<String, String> body = {
        'login_email': email,
        'login_password': password,
      };
      if (otp != null && otp.isNotEmpty) {
        body['otp'] = otp;
      }

      print('Försöker logga in mot: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      
      print('Svar från servern - Statuskod: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
        await _storage.write(key: _userNameKey, value: data['name']);
        await _storage.write(key: _userEmailKey, value: data['email']);

        if (rememberMe) {
          await _storage.write(key: _emailKey, value: email);
          await _storage.write(key: _passwordKey, value: password);
        } else {
          await _clearSavedCredentials();
        }
        return LoginResult(status: LoginResultStatus.success);
      } 
      else if (response.statusCode == 401) {
        final data = json.decode(response.body);
        
        // =================================================================
        // === ÄNDRING: Vi letar nu bara efter "2FA" för att vara mer flexibla. ===
        // =================================================================
        if (data['message']?.toString().contains('2FA') ?? false) {
          return LoginResult(status: LoginResultStatus.twoFactorRequired);
        } else {
          // Vi kan nu ta bort loggningen eftersom vi vet vad problemet var.
          return LoginResult(status: LoginResultStatus.failure, errorMessage: "Felaktiga inloggningsuppgifter.");
        }
      }
      else {
        return LoginResult(status: LoginResultStatus.failure, errorMessage: "Ett okänt fel uppstod (Status ${response.statusCode}).");
      }

    } catch (e) {
      print('Allvarligt fel vid inloggningsförsök: $e');
      return LoginResult(status: LoginResultStatus.failure, errorMessage: "Kunde inte ansluta till servern.");
    }
  }
  
  Future<String?> getCurrentUserName() async { return await _storage.read(key: _userNameKey); }
  Future<String?> getCurrentUserEmail() async { return await _storage.read(key: _userEmailKey); }
  Future<void> logout() async { await _storage.deleteAll(); print('Användare utloggad. All sparad data borttagen.'); }
  Future<String?> getSavedEmail() async { return await _storage.read(key: _emailKey); }
  Future<String?> getSavedPassword() async { return await _storage.read(key: _passwordKey); }
  Future<void> _clearSavedCredentials() async { await _storage.delete(key: _emailKey); await _storage.delete(key: _passwordKey); }
  Future<void> clearSelectedClinic() async { await UrlService.clearSelectedClinic(); }
  Future<String?> getToken() async { return await _storage.read(key: _tokenKey); }
}