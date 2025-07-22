// lib/services/auth_service.dart
// UPPDATERAD: Hanterar nu 2FA (OTP) vid inloggning.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kvalprak_app/models/login_result.dart'; // Importera vår nya modell
import 'package:kvalprak_app/services/url_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Nycklar för säker lagring
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  /// Försöker logga in användaren. Kan nu hantera OTP.
  Future<LoginResult> login(String email, String password, {String? otp, bool rememberMe = false}) async {
    try {
      final apiHost = await UrlService.getApiHost();
      final url = Uri.parse('https://$apiHost/api/auth/login');

      // Bygg upp JSON-kroppen för anropet
      final Map<String, String> body = {
        'login_email': email,
        'login_password': password,
      };
      // Lägg bara till OTP-fältet om ett värde har angetts
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
      // Hantera 401-fel specifikt
      else if (response.statusCode == 401) {
        final data = json.decode(response.body);
        // Kontrollera om servern säger att 2FA krävs
        if (data['message']?.toString().contains('2FA required') ?? false) {
          return LoginResult(status: LoginResultStatus.twoFactorRequired);
        } else {
          // Annars är det felaktiga inloggningsuppgifter
          return LoginResult(status: LoginResultStatus.failure, errorMessage: "Felaktiga inloggningsuppgifter.");
        }
      }
      // Hantera alla andra fel
      else {
        return LoginResult(status: LoginResultStatus.failure, errorMessage: "Ett okänt fel uppstod (Status ${response.statusCode}).");
      }

    } catch (e) {
      print('Allvarligt fel vid inloggningsförsök: $e');
      return LoginResult(status: LoginResultStatus.failure, errorMessage: "Kunde inte ansluta till servern.");
    }
  }
  
  // ... resten av filen är oförändrad ...
  Future<String?> getCurrentUserName() async { return await _storage.read(key: _userNameKey); }
  Future<String?> getCurrentUserEmail() async { return await _storage.read(key: _userEmailKey); }
  Future<void> logout() async { await _storage.deleteAll(); print('Användare utloggad. All sparad data borttagen.'); }
  Future<String?> getSavedEmail() async { return await _storage.read(key: _emailKey); }
  Future<String?> getSavedPassword() async { return await _storage.read(key: _passwordKey); }
  Future<void> _clearSavedCredentials() async { await _storage.delete(key: _emailKey); await _storage.delete(key: _passwordKey); }
  Future<void> clearSelectedClinic() async { await UrlService.clearSelectedClinic(); }
  Future<String?> getToken() async { return await _storage.read(key: _tokenKey); }
}