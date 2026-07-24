// lib/services/document_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kvalprak_app/models/document_models.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/services/api_service.dart';

class DocumentService {
  final ApiService _apiService = ApiService();

  Future<List<MainMenu>> getMainMenus() async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/menu');
    
    final response = await _apiService.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final menusList = data['menus'] as List<dynamic>? ?? [];
      return menusList.map((menuJson) => MainMenu.fromJson(menuJson)).toList();
    } else {
      throw Exception('Kunde inte ladda huvudmenyer (Status: ${response.statusCode})');
    }
  }

  Future<List<MenuItem>> getMenuStructure(String menuId) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/menu/$menuId');
    
    final response = await _apiService.get(url);
    
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

  Future<DocumentDetail> getDocumentDetails(String documentId) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/document/$documentId');

    final response = await _apiService.get(url);

    if (response.statusCode == 200) {
      return DocumentDetail.fromJson(json.decode(response.body));
    } else {
      throw Exception('Kunde inte ladda dokumentdetaljer (Status: ${response.statusCode})');
    }
  }

  // NY METOD FÖR ATT SÖKA DOKUMENT
  Future<List<DocumentSearchResult>> searchDocuments(String query) async {
    final apiHost = await UrlService.getApiHost();
    // Vi kodar sökordet ifall användaren söker med mellanslag eller specialtecken
    final url = Uri.parse('https://$apiHost/api/documents/search?s=${Uri.encodeComponent(query)}');
    
    final response = await _apiService.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final docsList = data['documents'] as List<dynamic>? ?? [];
      return docsList.map((json) => DocumentSearchResult.fromJson(json)).toList();
    } else {
      throw Exception('Kunde inte söka (Status: ${response.statusCode})');
    }
  }
}