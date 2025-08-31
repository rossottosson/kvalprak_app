// lib/providers/document_provider.dart
// UPPDATERAD: Lade till state och metod för att hantera dokumentdetaljer.

import 'package:flutter/foundation.dart';
import 'package:kvalprak_app/models/document_models.dart';
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/services/checklist_service.dart'; // For SessionExpiredException
import 'package:kvalprak_app/services/document_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();
  final AuthService _authService = AuthService();

  List<MainMenu> _mainMenus = [];
  List<MainMenu> get mainMenus => List.unmodifiable(_mainMenus);

  List<MenuItem> _menuItems = [];
  List<MenuItem> get menuItems => List.unmodifiable(_menuItems);

  String? _currentMainMenuId;

  DocumentDetail? _documentDetail;
  DocumentDetail? get documentDetail => _documentDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchMainMenus() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw SessionExpiredException("Autentisering saknas.");
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mainMenus = await _documentService.getMainMenus(token);
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMenuStructure(String menuId) async {
    if (_currentMainMenuId == menuId && _menuItems.isNotEmpty) {
      return;
    }

    final token = await _authService.getToken();
    if (token == null) {
      throw SessionExpiredException("Autentisering saknas.");
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _menuItems = await _documentService.getMenuStructure(token, menuId);
      _currentMainMenuId = menuId;
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDocumentDetails(String documentId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw SessionExpiredException("Autentisering saknas.");
    }

    _isLoading = true;
    _error = null;
    _documentDetail = null;
    notifyListeners();

    try {
      _documentDetail = await _documentService.getDocumentDetails(token, documentId);
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMenuStructure() {
    _menuItems = [];
    _currentMainMenuId = null;
    _error = null;
    notifyListeners();
  }
}