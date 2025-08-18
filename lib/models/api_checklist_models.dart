// lib/models/api_checklist_models.dart
// UPPDATERAD: Lade till 'validate' i ApiQuestion-modellen enligt ny dokumentation.

import 'dart:convert';

class ApiChecklist {
  final String formId;
  final String name;
  final ApiChecklistPage page;

  ApiChecklist({required this.formId, required this.name, required this.page});

  factory ApiChecklist.fromJson(Map<String, dynamic> json, ApiChecklistPage page) {
    return ApiChecklist(
      formId: json['form_id'] ?? '',
      name: json['name'] ?? 'Okänd Checklista',
      page: page,
    );
  }
}

class ApiChecklistPage {
  final String pageId;
  final String formId;
  final String name;

  ApiChecklistPage({required this.pageId, required this.formId, required this.name});

  factory ApiChecklistPage.fromJson(Map<String, dynamic> json) {
    return ApiChecklistPage(
      pageId: json['page_id'] ?? '',
      formId: json['form_id'] ?? '',
      name: json['name'] ?? 'Okänd Sida',
    );
  }
}

class ChecklistPageData {
  final ApiChecklistPage page;
  final List<ApiQuestion> questions;

  ChecklistPageData({required this.page, required this.questions});
}

class ApiQuestion {
  final String questionId;
  final String? parentId;
  final int sort;
  final String type;
  final String text;
  final String description;
  final List<ApiQuestionOption> options;
  final String validate; // <-- NYTT FÄLT
  final String settings; 

  ApiQuestion({
    required this.questionId,
    this.parentId,
    required this.sort,
    required this.type,
    required this.text,
    required this.description,
    required this.options,
    required this.validate, // <-- NYTT FÄLT
    required this.settings,
  });

  factory ApiQuestion.fromJson(Map<String, dynamic> json, Map<String, dynamic> allOptions) {
    final questionData = (json.values.first is Map<String, dynamic>)
        ? json.values.first as Map<String, dynamic>
        : json;

    final questionId = questionData['question_id'] ?? '';
    
    final questionOptionsMap = allOptions[questionId] as Map<String, dynamic>? ?? {};
    final parsedOptions = questionOptionsMap.entries.map((entry) {
      if (entry.value is Map<String, dynamic>) {
        return ApiQuestionOption.fromJson(entry.value);
      }
      return null;
    }).where((opt) => opt != null).cast<ApiQuestionOption>().toList();

    return ApiQuestion(
      questionId: questionId,
      parentId: questionData['parent_id'],
      sort: int.tryParse(questionData['sort']?.toString() ?? '0') ?? 0,
      type: questionData['field'] ?? 'text',
      text: questionData['name'] ?? 'Okänd fråga',
      description: questionData['description'] ?? '',
      options: parsedOptions,
      validate: questionData['validate'] ?? '', // <-- LÄS IN FÄLTET
      settings: questionData['settings'] ?? '',
    );
  }
}

class ApiQuestionOption {
  final String optionId;
  final String name;

  ApiQuestionOption({required this.optionId, required this.name});

  factory ApiQuestionOption.fromJson(Map<String, dynamic> json) {
    return ApiQuestionOption(
      optionId: json['option_id'] ?? '',
      name: json['name'] ?? 'Okänt alternativ',
    );
  }
}

class ApiSubmission {
  final String surveyId;
  final String pageId;
  final DateTime surveyDate;

  ApiSubmission({required this.surveyId, required this.pageId, required this.surveyDate});

  factory ApiSubmission.fromJson(Map<String, dynamic> json) {
    return ApiSubmission(
      surveyId: json['survey_id'] ?? '',
      pageId: json['page_id'] ?? '',
      surveyDate: DateTime.tryParse(json['survey_date'] ?? '') ?? DateTime.now(),
    );
  }
}