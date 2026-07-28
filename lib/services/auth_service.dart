// lib/services/auth_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kvalprak_app/models/login_result.dart';
import 'package:kvalprak_app/services/url_service.dart';

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

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _debugLogJwtPayload(data['token'], 'VANLIG LOGIN');
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
      } else if (response.statusCode == 401) {
        final data = json.decode(response.body);
        if (data['message']?.toString().contains('2FA') ?? false) {
          return LoginResult(status: LoginResultStatus.twoFactorRequired);
        } else {
          return LoginResult(status: LoginResultStatus.failure, errorMessage: "Felaktiga inloggningsuppgifter.");
        }
      } else {
        return LoginResult(status: LoginResultStatus.failure, errorMessage: "Ett okänt fel uppstod (Status ${response.statusCode}).");
      }
    } catch (e) {
      return LoginResult(status: LoginResultStatus.failure, errorMessage: "Kunde inte ansluta till servern.");
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);

    await UrlService.clearSelectedClinic();
    debugPrint('Användare utloggad. Session raderad, men sparade credentials bevarade.');
  }

  Future<String?> getCurrentUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  Future<String?> getCurrentUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<String?> getSavedPassword() async {
    return await _storage.read(key: _passwordKey);
  }

  Future<void> _clearSavedCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<bool> hasSavedRefreshToken() async {
    final token = await _storage.read(key: _refreshTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> trySilentRefreshToken() async {
    final email = await getSavedEmail();
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final currentToken = await _storage.read(key: _tokenKey); 
    
    if (email == null || refreshToken == null) return null; // Ändrat till null

    try {
      final apiHost = await UrlService.getApiHost();
      final url = Uri.parse('https://$apiHost/api/auth/refresh'); 

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (currentToken != null) 'Authorization': 'Bearer $currentToken',
        },
        body: json.encode({
          'refresh_token': refreshToken, 
          'login_email': email,           
        }),
      );

      debugPrint('--- RAW REFRESH RESPONSE ---');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('-----------------------------');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Fånga den nya nyckeln i en variabel först!
        String? newToken = data['token'] ?? data['access_token'];
        _debugLogJwtPayload(newToken, 'SILENT REFRESH (Face ID)');
        
        if (newToken != null) {
          await _storage.write(key: _tokenKey, value: newToken);
        }
        
        if (data['refresh_token'] != null) {
          await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        
        if (data['name'] != null) {
          await _storage.write(key: _userNameKey, value: data['name']);
        }
        if (data['email'] != null) {
          await _storage.write(key: _userEmailKey, value: data['email']);
        }
        
        // ÄNDRING: Returnera den nya nyckeln direkt till ApiService!
        return newToken; 
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Kunde inte ansluta till refresh: $e');
      return null;
    }
  }
  void _debugLogJwtPayload(String? token, String source) {
  if (token == null || token.isEmpty) {
    debugPrint('--- JWT [$source]: Ingen token hittades ---');
    return;
  }

  try {
    // En JWT består av tre delar separerade med punkt. Vi vill ha del 2 (index 1).
    final parts = token.split('.');
    if (parts.length < 2) {
      debugPrint('--- JWT [$source]: Ogiltigt token-format ---');
      return;
    }

    String payload = parts[1];
    
    // Base64-strängar i JWT saknar ibland "padding" (=), vi lägger till det om det behövs
    switch (payload.length % 4) {
      case 2: payload += '=='; break;
      case 3: payload += '='; break;
    }

    // Koda av strängen till ren text (JSON)
    final String decodedText = utf8.decode(base64Url.decode(payload));
    
    // Snygga till JSON-strukturen så den blir lättläst i terminalen
    final dynamic jsonObject = json.decode(decodedText);
    final String prettyJson = const JsonEncoder.withIndent('  ').convert(jsonObject);

    debugPrint('\n=============================================');
    debugPrint('     🚨 JWT PAYLOAD FRÅN: $source 🚨');
    debugPrint('=============================================');
    debugPrint(prettyJson);
    debugPrint('=============================================\n');
  } catch (e) {
    debugPrint('Kunde inte avkoda JWT från $source: $e');
  }
}
}