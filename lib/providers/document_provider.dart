// lib/providers/document_provider.dart

import 'package:flutter/foundation.dart';
import 'package:kvalprak_app/models/document_models.dart';
import 'package:kvalprak_app/services/document_service.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();

  List<MainMenu> _mainMenus = [];
  List<MainMenu> get mainMenus => List.unmodifiable(_mainMenus);

  List<MenuItem> _menuItems = [];
  List<MenuItem> get menuItems => List.unmodifiable(_menuItems);

  // Tillstånd för sökning
  List<DocumentSearchResult> _searchResults = [];
  List<DocumentSearchResult> get searchResults => List.unmodifiable(_searchResults);
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _currentMainMenuId;
  DocumentDetail? _documentDetail;
  DocumentDetail? get documentDetail => _documentDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchMainMenus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mainMenus = await _documentService.getMainMenus();
    } catch (e) {
      _error = e.toString();
      if (e is SessionExpiredException) rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMenuStructure(String menuId) async {
    if (_currentMainMenuId == menuId && _menuItems.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _menuItems = await _documentService.getMenuStructure(menuId);
      _currentMainMenuId = menuId;
    } catch (e) {
      _error = e.toString();
      if (e is SessionExpiredException) rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDocumentDetails(String documentId) async {
    _isLoading = true;
    _error = null;
    _documentDetail = null;
    notifyListeners();

    try {
      _documentDetail = await _documentService.getDocumentDetails(documentId);
    } catch (e) {
      _error = e.toString();
      if (e is SessionExpiredException) rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchDocuments(String query) async {
    if (query.trim().length < 3) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _documentService.searchDocuments(query.trim());
    } catch (e) {
      _error = e.toString();
      if (e is SessionExpiredException) rethrow;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  void clearMenuStructure() {
    _menuItems = [];
    _currentMainMenuId = null;
    _error = null;
    notifyListeners();
  }
}