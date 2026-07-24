// lib/services/checklist_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kvalprak_app/models/api_checklist_models.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/services/api_service.dart';

void logLong(String text, {int chunkSize = 800}) {
  final pattern = RegExp('.{1,$chunkSize}', dotAll: true);
  for (final match in pattern.allMatches(text)) {
    debugPrint(match.group(0));
  }
}

class ChecklistService {
  final ApiService _apiService = ApiService();

  Future<List<ApiChecklist>> getChecklists() async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/checklist');

    final response = await _apiService.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final checklistsMap = data['checklists'] as Map<String, dynamic>? ?? {};
      final pagesMap = data['pages'] as Map<String, dynamic>? ?? {};

      final Map<String, ApiChecklistPage> pagesByFormId = {};
      pagesMap.forEach((pageKey, pageValue) {
        if (pageValue is Map<String, dynamic>) {
          final page = ApiChecklistPage.fromJson(pageValue);
          pagesByFormId[page.formId] = page;
        }
      });

      final List<ApiChecklist> checklists = [];
      checklistsMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final checklistJson = value;
          final formId = key;
          checklistJson['form_id'] = formId;

          final matchingPage = pagesByFormId[formId];
          if (matchingPage != null) {
            checklists.add(ApiChecklist.fromJson(checklistJson, matchingPage));
          }
        }
      });

      return checklists;
    } else {
      throw Exception('Kunde inte ladda checklistor (Status: ${response.statusCode})');
    }
  }

  Future<ChecklistPageData> getQuestionsForPage(String pageId) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/checklist/$pageId/questions');

    final response = await _apiService.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      logLong('--- RAW DECODED QUESTIONS RESPONSE ---');
      logLong(const JsonEncoder.withIndent('  ').convert(data));
      logLong('--- END RAW DECODED QUESTIONS RESPONSE ---');

      final pageInfo = ApiChecklistPage.fromJson(data['page']);
      final questionsData = data['questions'];
      final optionsData = data['options'];
      final optionsMap = (optionsData is Map<String, dynamic>) ? optionsData : <String, dynamic>{};

      List<ApiQuestion> questions = [];

      void parseQuestionGroup(Map<String, dynamic> questionGroup) {
        questionGroup.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            questions.add(ApiQuestion.fromJson(value, optionsMap));
          }
        });
      }

      if (questionsData is Map<String, dynamic>) {
        questionsData.forEach((groupKey, groupValue) {
          if (groupValue is Map<String, dynamic>) {
            parseQuestionGroup(groupValue);
          }
        });
      } else if (questionsData is List<dynamic>) {
        for (var item in questionsData) {
          if (item is Map<String, dynamic>) {
            parseQuestionGroup(item);
          }
        }
      }

      questions.sort((a, b) => a.sort.compareTo(b.sort));

      return ChecklistPageData(page: pageInfo, questions: questions);
    } else {
      throw Exception('Kunde inte ladda frågor (Status: ${response.statusCode})');
    }
  }

  Future<String?> submitChecklist(String pageId, Map<String, dynamic> answers) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/checklist/$pageId/submit');

    final response = await _apiService.post(url, body: answers);

    debugPrint('Inskickning till servern gav status: ${response.statusCode}');
    logLong('--- RAW SUBMIT RESPONSE ---');
    logLong(response.body);
    logLong('--- END RAW SUBMIT RESPONSE ---');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true || data.isEmpty) {
        return data['survey_id'] as String? ?? 'success';
      }
      return null;
    } else {
      debugPrint('Inskickning misslyckades med felkod: ${response.statusCode}');
      return null;
    }
  }

  Future<List<ApiSubmission>> getSubmissionsForPage(String pageId) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/checklist/$pageId/submissions');

    final response = await _apiService.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final submissionsList = data['submissions'] as List<dynamic>;

      final submissions = submissionsList.map((subJson) {
        return ApiSubmission.fromJson(subJson);
      }).toList();

      return submissions;
    } else {
      throw Exception('Kunde inte ladda historik (Status: ${response.statusCode})');
    }
  }
}