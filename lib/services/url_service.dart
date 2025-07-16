// lib/services/url_service.dart
// UPPDATERAD FÖR ATT HANTERA BÅDE WEBB- OCH API-DOMÄNER

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvalprak_app/models/clinic_model.dart';

class UrlService {
  static const String _clinicSubdomainKey = 'clinicSubdomain';
  static const String _clinicNameKey = 'clinicName';

  // Definiera båda basdomänerna
  static const String _webBaseDomain = "kiv.kvalprak.se";
  static const String _apiBaseDomain = "orna.vardna.se"; // NYTT: API-domän

  static List<Clinic> _masterClinicList = [];
  static bool _masterListLoaded = false;

  // --- Nya metoder för att hämta specifik host ---

  /// Returnerar host för WebView, t.ex. "ornaegen.kiv.kvalprak.se"
  static Future<String> getWebHost() async {
    String subdomain = await getSelectedClinicSubdomain();
    return "$subdomain.$_webBaseDomain";
  }

  /// Returnerar host för det nativa API:et, t.ex. "ornaegen.orna.vardna.se"
  static Future<String> getApiHost() async {
    String subdomain = await getSelectedClinicSubdomain();
    return "$subdomain.$_apiBaseDomain";
  }

  // --- Slut på nya metoder ---


  static Future<String> getSelectedClinicSubdomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clinicSubdomainKey) ?? "playground"; // Fallback
  }

  // Ingen ändring i resten av filen nedanför...

  static Future<void> _loadMasterClinicListIfNeeded() async {
    if (_masterListLoaded) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/clinics.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List;
      _masterClinicList = jsonList
          .map((jsonItem) => Clinic(
                name: jsonItem['name'] as String,
                subdomain: jsonItem['subdomain'] as String,
              ))
          .toList();
      _masterListLoaded = true;
      debugPrint("UrlService: Successfully loaded ${_masterClinicList.length} clinics from JSON asset.");
    } catch (e) {
      debugPrint("UrlService: Error loading or parsing clinics.json: $e");
      _masterClinicList = [Clinic(name: "Playground (Fallback)", subdomain: "playground")];
      _masterListLoaded = true;
    }
  }

  static Future<Clinic?> findClinicByUserInput(String userInput) async {
    await _loadMasterClinicListIfNeeded();
    if (userInput.trim().isEmpty) return null;

    final String query = userInput.trim().toLowerCase();

    for (var clinic in _masterClinicList) {
      if (clinic.subdomain.toLowerCase() == query) {
        debugPrint("Found clinic by exact subdomain match: ${clinic.name}");
        return clinic;
      }
    }

    for (var clinic in _masterClinicList) {
      if (clinic.name.toLowerCase() == query) {
        debugPrint("Found clinic by exact name match: ${clinic.name}");
        return clinic;
      }
    }

    if (query.length >= 4) {
      List<Clinic> containedInNameMatches = [];
      for (var clinic in _masterClinicList) {
        if (clinic.name.toLowerCase().contains(query)) {
          containedInNameMatches.add(clinic);
        }
      }
      if (containedInNameMatches.length == 1) {
        debugPrint("Found unique clinic by name contains query: ${containedInNameMatches.first.name}");
        return containedInNameMatches.first;
      } else if (containedInNameMatches.length > 1) {
        debugPrint("Query '$query' matched multiple clinics by name contains, too ambiguous.");
      }
    }
    
    debugPrint("No unique, confident match found for query: '$query'");
    return null;
  }

  static Future<void> setSelectedClinic(Clinic clinic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clinicSubdomainKey, clinic.subdomain.toLowerCase().trim());
    await prefs.setString(_clinicNameKey, clinic.name);
    debugPrint("UrlService: Selected clinic saved - Name: ${clinic.name}, Subdomain: ${clinic.subdomain}");
  }

  static Future<String?> getSelectedClinicName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clinicNameKey);
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
    debugPrint("UrlService: Selected clinic cleared.");
  }

  // UPPDATERADE URL GETTERS ANVÄNDER NU getWebHost()
  static Future<String> getLoginInitialUrl() async {
    String host = await getWebHost();
    return "https://$host/login?redirect=";
  }

  static Future<String> getLoginPostSuccessUrl() async {
    String host = await getWebHost();
    return "https://$host/";
  }

  static Future<String> getDeviationInitialUrl() async {
    String host = await getWebHost();
    return "https://$host/deviation/add/1";
  }

  static Future<String> getDeviationBasePath() async {
    String host = await getWebHost();
    return "https://$host/deviation/";
  }

  static Future<String> getDeviationSuccessPattern() async {
    String host = await getWebHost();
    return "https://$host/deviation/add/2/";
  }

  static Future<String> getGenericLoginPattern() async {
    String host = await getWebHost();
    return "https://$host/login";
  }
}