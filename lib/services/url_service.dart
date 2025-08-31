// lib/services/url_service.dart
// UPPDATERAD: Använder nya /api/status för att validera klinik och hämta dess riktiga namn.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvalprak_app/models/clinic_model.dart';

class UrlService {
  static const String _clinicSubdomainKey = 'clinicSubdomain';
  static const String _clinicNameKey = 'clinicName';

  static const String _apiBaseDomain = "orna.vardna.se";
  static const String _webBaseDomain = "orna.vardna.se";

  static Future<Clinic?> validateAndGetClinic(String subdomain) async {
    final cleanSubdomain = subdomain.trim().toLowerCase();
    if (cleanSubdomain.isEmpty) {
      return null;
    }

    // ÄNDRING: Använd den nya /api/status-endpointen.
    final url = Uri.parse('https://$cleanSubdomain.$_apiBaseDomain/api/status');
    debugPrint("Checking clinic status at: $url");

    try {
      // ÄNDRING: Använd http.get för att få ett svar med innehåll.
      final response = await http.get(url);

      // ÄNDRING: En lyckad validering är nu enbart status 200.
      if (response.statusCode == 200) {
        // Tolka JSON-svaret och hämta namnet.
        final data = json.decode(response.body);
        final clinicName = data['name'] as String?;

        if (clinicName != null && clinicName.isNotEmpty) {
          debugPrint("Success! Clinic found: '$clinicName'");
          // Returnera ett Clinic-objekt med det riktiga namnet.
          return Clinic(name: clinicName, subdomain: cleanSubdomain);
        } else {
          debugPrint("Status OK, but clinic name was not found in response.");
          return null;
        }
      } else {
        debugPrint("Failed to validate clinic. Status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error checking clinic status: $e");
      return null;
    }
  }

  static Future<void> setSelectedClinic(Clinic clinic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clinicSubdomainKey, clinic.subdomain);
    await prefs.setString(_clinicNameKey, clinic.name);
  }

  static Future<String?> getSelectedClinicName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clinicNameKey);
  }

  static Future<String> getSelectedClinicSubdomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clinicSubdomainKey) ?? "";
  }

  static Future<bool> isClinicSelected() async {
    final prefs = await SharedPreferences.getInstance();
    final subdomain = prefs.getString(_clinicSubdomainKey);
    return subdomain != null && subdomain.isNotEmpty;
  }

  static Future<void> clearSelectedClinic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clinicSubdomainKey);
    await prefs.remove(_clinicNameKey);
  }

  static Future<String> getApiHost() async {
    String subdomain = await getSelectedClinicSubdomain();
    return "$subdomain.$_apiBaseDomain";
  }

  static Future<String> getWebHost() async {
    String subdomain = await getSelectedClinicSubdomain();
    return "$subdomain.$_webBaseDomain";
  }
}