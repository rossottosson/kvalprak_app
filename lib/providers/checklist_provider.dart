// lib/providers/checklist_provider.dart
// OMbyggd FÖR ATT ANVÄNDA ChecklistService OCH API-ANROP ISTÄLLET FÖR HIVE

import 'package:flutter/foundation.dart';
import 'package:kvalprak_app/models/api_checklist_models.dart';
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/services/checklist_service.dart';

class ChecklistProvider with ChangeNotifier {
  final ChecklistService _checklistService = ChecklistService();
  final AuthService _authService = AuthService();

  // State för listan med checklistor
  List<ApiChecklist> _checklists = [];
  List<ApiChecklist> get checklists => List.unmodifiable(_checklists);
  
  // State för den checklista som användaren just nu tittar på
  ChecklistPageData? _currentPageData;
  ChecklistPageData? get currentPageData => _currentPageData;

  // State för historik
  List<ApiSubmission> _submissions = [];
  List<ApiSubmission> get submissions => List.unmodifiable(_submissions);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Hämtar listan med alla tillgängliga checklistor
  Future<void> fetchChecklists() async {
    final token = await _authService.getToken();
    if (token == null) {
      _error = "Autentisering saknas.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _checklists = await _checklistService.getChecklists(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hämtar frågorna för en specifik checklista
  Future<void> fetchQuestions(String pageId) async {
    final token = await _authService.getToken();
    if (token == null) {
      _error = "Autentisering saknas.";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    _currentPageData = null; // Rensa gammal data
    notifyListeners();

    try {
      _currentPageData = await _checklistService.getQuestionsForPage(token, pageId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Skickar in svaren för en checklista
  Future<bool> submitAnswers(String pageId, Map<String, dynamic> answers) async {
     final token = await _authService.getToken();
    if (token == null) {
      _error = "Autentisering saknas.";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final surveyId = await _checklistService.submitChecklist(token, pageId, answers);
      return surveyId != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hämtar historik för en specifik checklista
  Future<void> fetchSubmissions(String pageId) async {
     final token = await _authService.getToken();
    if (token == null) {
      _error = "Autentisering saknas.";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    _submissions = []; // Rensa gammal data
    notifyListeners();

    try {
      _submissions = await _checklistService.getSubmissionsForPage(token, pageId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metod för att rensa state när användaren lämnar en detaljvy
  void clearCurrentPage() {
    _currentPageData = null;
    _error = null;
    notifyListeners();
  }
}