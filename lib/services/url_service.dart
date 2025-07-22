// lib/services/url_service.dart
// UPPDATERAD: Tillåter nu sökning på 3 tecken.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvalprak_app/models/clinic_model.dart';

class UrlService {
  static const String _clinicSubdomainKey = 'clinicSubdomain';
  static const String _clinicNameKey = 'clinicName';

  static const String _webBaseDomain = "kiv.kvalprak.se";
  static const String _apiBaseDomain = "orna.vardna.se";

  static Future<String> getWebHost() async {
    String subdomain = await getSelectedClinicSubdomain();
    return "$subdomain.$_webBaseDomain";
  }

  static Future<String> getApiHost() async {
    String subdomain = await getSelectedClinicSubdomain();
    return "$subdomain.$_apiBaseDomain";
  }

  static Future<String> getSelectedClinicSubdomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clinicSubdomainKey) ?? "playground";
  }
  
  static List<Clinic> _masterClinicList = [];
  static bool _masterListLoaded = false;
  
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
        return clinic;
      }
    }

    for (var clinic in _masterClinicList) {
      if (clinic.name.toLowerCase() == query) {
        return clinic;
      }
    }

    // MODIFIERAD: Ändrat från 4 till 3
    if (query.length >= 3) {
      List<Clinic> containedInNameMatches = [];
      for (var clinic in _masterClinicList) {
        if (clinic.name.toLowerCase().contains(query)) {
          containedInNameMatches.add(clinic);
        }
      }
      if (containedInNameMatches.length == 1) {
        return containedInNameMatches.first;
      }
    }
    
    return null;
  }
  
  // ... resten av filen är oförändrad ...
  static Future<void> setSelectedClinic(Clinic clinic) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString(_clinicSubdomainKey, clinic.subdomain.toLowerCase().trim()); await prefs.setString(_clinicNameKey, clinic.name); }
  static Future<String?> getSelectedClinicName() async { final prefs = await SharedPreferences.getInstance(); return prefs.getString(_clinicNameKey); }
  static Future<bool> isClinicSelected() async { final prefs = await SharedPreferences.getInstance(); final subdomain = prefs.getString(_clinicSubdomainKey); return subdomain != null && subdomain.isNotEmpty; }
  static Future<void> clearSelectedClinic() async { final prefs = await SharedPreferences.getInstance(); await prefs.remove(_clinicSubdomainKey); await prefs.remove(_clinicNameKey); }
  static Future<String> getLoginInitialUrl() async { String host = await getWebHost(); return "https://$host/login?redirect="; }
  static Future<String> getLoginPostSuccessUrl() async { String host = await getWebHost(); return "https://$host/"; }
  static Future<String> getDeviationInitialUrl() async { String host = await getWebHost(); return "https://$host/deviation/add/1"; }
  static Future<String> getDeviationBasePath() async { String host = await getWebHost(); return "https://$host/deviation/"; }
  static Future<String> getDeviationSuccessPattern() async { String host = await getWebHost(); return "https://$host/deviation/add/2/"; }
  static Future<String> getGenericLoginPattern() async { String host = await getWebHost(); return "https://$host/login"; }
}