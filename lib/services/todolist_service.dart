// lib/services/todolist_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kvalprak_app/models/todo_models.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/services/api_service.dart';

class TodolistService {
  final ApiService _apiService = ApiService();

  // ---------- LISTOR ----------

  Future<List<TodoList>> getLists() async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/lists');

    final response = await _apiService.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final listsJson = data['lists'] as List<dynamic>? ?? [];
      return listsJson.map((j) => TodoList.fromJson(j)).toList();
    } else {
      throw Exception('Kunde inte ladda listor (Status: ${response.statusCode})');
    }
  }

  Future<bool> createList({
    required String name,
    String description = '',
    String? finishDate,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/list');

    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'repeat_type': null,
      'repeat_value': null,
      'finish_date': finishDate,
    };

    final response = await _apiService.post(url, body: body);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte skapa lista. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }

  Future<bool> updateList({
    required String id,
    required String name,
    String description = '',
    String? finishDate,
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/list/$id');

    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'finish_date': finishDate,
    };

    final response = await _apiService.put(url, body: body);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte uppdatera lista. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }

  Future<bool> deleteList(String id) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/list/$id');

    final response = await _apiService.delete(url);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte radera lista. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }

  // ---------- ITEMS / UPPGIFTER ----------

  Future<List<TodoItem>> getItems(String listId) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/list/$listId/items');

    final response = await _apiService.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final itemsJson = data['items'] as List<dynamic>? ?? [];
      return itemsJson.map((j) => TodoItem.fromJson(j)).toList();
    } else {
      throw Exception('Kunde inte ladda uppgifter (Status: ${response.statusCode})');
    }
  }

  Future<bool> createItem({
    required String listId,
    required String name,
    String description = '',
    String? finishDate,
    String priority = 'medium',
    String status = 'not_started',
    String comments = '',
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/list/$listId/item');

    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'finish_date': finishDate,
      'priority': priority,
      'status': status,
      'comments': comments,
    };

    final response = await _apiService.post(url, body: body);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte skapa uppgift. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }

  Future<bool> updateItem({
    required String id,
    required String name,
    String description = '',
    String priority = 'medium',
    String status = 'not_started',
    String comments = '',
  }) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/item/$id');

    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'priority': priority,
      'status': status,
      'comments': comments,
    };

    final response = await _apiService.put(url, body: body);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte uppdatera uppgift. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/item/$id');

    final response = await _apiService.delete(url);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte radera uppgift. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }

  Future<bool> setItemChecked(String id, bool isChecked) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/item/$id/status');

    final response = await _apiService.put(url, body: {'is_checked': isChecked});

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte ändra status. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }

  Future<bool> archiveItem(String id) async {
    final apiHost = await UrlService.getApiHost();
    final url = Uri.parse('https://$apiHost/api/todolist/item/$id/archive');

    final response = await _apiService.put(url);

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    } else {
      debugPrint('Kunde inte arkivera uppgift. Status: ${response.statusCode}, Svar: ${response.body}');
      return false;
    }
  }
}
