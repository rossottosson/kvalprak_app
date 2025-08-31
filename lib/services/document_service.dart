// lib/services/document_service.dart
// UPPDATERAD: Lade till en debugPrint för att logga det råa JSON-svaret från servern.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kvalprak_app/models/document_models.dart';
import 'package:kvalprak_app/services/checklist_service.dart'; // For SessionExpiredException
import 'package:kvalprak_app/services/url_service.dart';

class DocumentService {
  Future<List<MainMenu>> getMainMenus(String token) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/menu');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 401) {
      throw SessionExpiredException('Sessionen har gått ut.');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final menusList = data['menus'] as List<dynamic>? ?? [];
      return menusList.map((menuJson) => MainMenu.fromJson(menuJson)).toList();
    } else {
      throw Exception('Kunde inte ladda huvudmenyer (Status: ${response.statusCode})');
    }
  }

  Future<List<MenuItem>> getMenuStructure(String token, String menuId) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/menu/$menuId');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 401) {
      throw SessionExpiredException('Sessionen har gått ut.');
    }
    if (response.statusCode == 404) {
      debugPrint("Menu/folder with ID $menuId not found or is empty. Returning empty list.");
      return [];
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final itemsList = data['items'] as List<dynamic>? ?? [];
      return itemsList.map((itemJson) => MenuItem.fromJson(itemJson)).toList();
    } else {
      throw Exception('Kunde inte ladda menystruktur (Status: ${response.statusCode})');
    }
  }

  Future<DocumentDetail> getDocumentDetails(String token, String documentId) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/document/$documentId');

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    // ===================================
    // === HÄR ÄR ÄNDRINGEN ===
    // ===================================
    // Skriv ut hela svaret från servern till konsolen för felsökning.
    debugPrint("--- RAW JSON RESPONSE FROM GET DOCUMENT DETAILS ---");
    debugPrint(response.body);
    debugPrint("--- END RAW JSON RESPONSE ---");

    if (response.statusCode == 401) {
      throw SessionExpiredException('Sessionen har gått ut.');
    }

    if (response.statusCode == 200) {
      return DocumentDetail.fromJson(json.decode(response.body));
    } else {
      throw Exception('Kunde inte ladda dokumentdetaljer (Status: ${response.statusCode})');
    }
  }
}