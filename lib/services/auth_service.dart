// lib/services/auth_service.dart
// UPPDATERAD: Logout-metoden raderar nu endast sessionen, inte sparade credentials.

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

  // ===================================
  // === HÄR ÄR ÄNDRINGEN ===
  // ===================================
  Future<void> logout() async {
    // Raderar endast sessions-specifik data. Sparat lösenord och e-post lämnas kvar.
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);

    // Raderar den valda kliniken för en total återställning av sessionen.
    await UrlService.clearSelectedClinic();
    print('Användare utloggad. Session raderad, men sparade credentials bevarade.');
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
}