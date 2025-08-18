// lib/services/url_service.dart
// UPPDATERAD: Tar bort den gamla kvalprak-domänen helt.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvalprak_app/models/clinic_model.dart';

class UrlService {
  static const String _clinicSubdomainKey = 'clinicSubdomain';
  static const String _clinicNameKey = 'clinicName';

  static const String _apiBaseDomain = "orna.vardna.se";
  // HÄR ÄR ÄNDRINGEN: Båda domänerna är nu samma.
  static const String _webBaseDomain = "orna.vardna.se"; 

  static Future<Clinic?> validateAndGetClinic(String subdomain) async {
    final cleanSubdomain = subdomain.trim().toLowerCase();
    if (cleanSubdomain.isEmpty) {
      return null;
    }

    final url = Uri.parse('https://$cleanSubdomain.$_apiBaseDomain/');
    debugPrint("Pinging clinic at root URL: $url");

    try {
      final response = await http.head(url);
      if (response.statusCode < 500) {
        debugPrint("Success! Server responded with status: ${response.statusCode}");
        return Clinic(name: cleanSubdomain, subdomain: cleanSubdomain);
      } else {
        debugPrint("Clinic server exists but has an error. Status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Failed to ping clinic. Error: $e");
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