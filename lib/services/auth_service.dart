// lib/services/auth_service.dart
// UPPDATERAD FÖR ATT SPARA OCH HANTERA INLOGGNINGSUPPGIFTER

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kvalprak_app/services/url_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Nycklar för säker lagring
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'saved_email'; // NYTT
  static const String _passwordKey = 'saved_password'; // NYTT

  /// Försöker logga in användaren.
  /// Om rememberMe är true, sparas uppgifterna säkert.
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final apiHost = await UrlService.getApiHost();
      final url = Uri.parse('https://$apiHost/api/auth/login');

      print('Försöker logga in mot: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'login_email': email,
          'login_password': password,
        }),
      );
      
      print('Svar från servern - Statuskod: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final refreshToken = data['refresh_token'];

        if (token != null && refreshToken != null) {
          await _storage.write(key: _tokenKey, value: token);
          await _storage.write(key: _refreshTokenKey, value: refreshToken);

          // NYTT: Hantera "Kom ihåg mig"-logik
          if (rememberMe) {
            await _storage.write(key: _emailKey, value: email);
            await _storage.write(key: _passwordKey, value: password);
            print('Inloggningsuppgifter sparade.');
          } else {
            // Om "Kom ihåg mig" inte är ikryssat, ta bort eventuella gamla uppgifter
            await _clearSavedCredentials();
          }

          print('Inloggning lyckades. Tokens sparade.');
          return true;
        }
      }
      print('Inloggning misslyckades.');
      return false;

    } catch (e) {
      print('Allvarligt fel vid inloggningsförsök: $e');
      return false;
    }
  }

  /// NYTT: Hämtar sparad e-post
  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _emailKey);
  }

  /// NYTT: Hämtar sparat lösenord
  Future<String?> getSavedPassword() async {
    return await _storage.read(key: _passwordKey);
  }

  /// NYTT: Tar bort sparade inloggningsuppgifter
  Future<void> _clearSavedCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
    print('Sparade inloggningsuppgifter borttagna.');
  }

  /// Loggar ut användaren genom att ta bort allt sparat
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _clearSavedCredentials(); // Se till att även sparade uppgifter tas bort vid utloggning
    print('Användare utloggad. All sparad data borttagen.');
  }

  /// Hämtar den sparade JWT-token.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearSelectedClinic() async {
    await UrlService.clearSelectedClinic();
  }
}