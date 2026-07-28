// lib/providers/todo_provider.dart

import 'package:flutter/foundation.dart';
import 'package:kvalprak_app/models/todo_models.dart';
import 'package:kvalprak_app/services/todolist_service.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class TodoProvider with ChangeNotifier {
  final TodolistService _service = TodolistService();

  // ---------- Listor ----------
  List<TodoList> _lists = [];
  List<TodoList> get lists => List.unmodifiable(_lists);

  bool _isLoadingLists = false;
  bool get isLoadingLists => _isLoadingLists;

  String? _listsError;
  String? get listsError => _listsError;

  // ---------- Items för den lista som visas just nu ----------
  List<TodoItem> _items = [];
  List<TodoItem> get items => List.unmodifiable(_items);

  bool _isLoadingItems = false;
  bool get isLoadingItems => _isLoadingItems;

  String? _itemsError;
  String? get itemsError => _itemsError;

  String? _currentListId;

  // ================= LISTOR =================

  Future<void> fetchLists() async {
    _isLoadingLists = true;
    _listsError = null;
    notifyListeners();

    try {
      _lists = await _service.getLists();
    } catch (e) {
      _listsError = e.toString();
      if (e is SessionExpiredException) rethrow;
    } finally {
      _isLoadingLists = false;
      notifyListeners();
    }
  }

  Future<bool> createList({
    required String name,
    String description = '',
    String? finishDate,
  }) async {
    final success = await _service.createList(
      name: name,
      description: description,
      finishDate: finishDate,
    );
    if (success) await fetchLists();
    return success;
  }

  Future<bool> updateList({
    required String id,
    required String name,
    String description = '',
    String? finishDate,
  }) async {
    final success = await _service.updateList(
      id: id,
      name: name,
      description: description,
      finishDate: finishDate,
    );
    if (success) await fetchLists();
    return success;
  }

  Future<bool> deleteList(String id) async {
    final success = await _service.deleteList(id);
    if (success) {
      _lists.removeWhere((l) => l.id == id);
      notifyListeners();
    }
    return success;
  }

  // ================= ITEMS =================

  Future<void> fetchItems(String listId) async {
    _isLoadingItems = true;
    _itemsError = null;
    _currentListId = listId;
    _items = [];
    notifyListeners();

    try {
      _items = await _service.getItems(listId);
    } catch (e) {
      _itemsError = e.toString();
      if (e is SessionExpiredException) rethrow;
    } finally {
      _isLoadingItems = false;
      notifyListeners();
    }
  }

  Future<bool> createItem({
    required String name,
    String description = '',
    String? finishDate,
    String priority = 'medium',
    String status = 'not_started',
    String comments = '',
  }) async {
    if (_currentListId == null) return false;
    final success = await _service.createItem(
      listId: _currentListId!,
      name: name,
      description: description,
      finishDate: finishDate,
      priority: priority,
      status: status,
      comments: comments,
    );
    if (success) await fetchItems(_currentListId!);
    return success;
  }

  Future<bool> updateItem({
    required String id,
    required String name,
    String description = '',
    String priority = 'medium',
    String status = 'not_started',
    String comments = '',
  }) async {
    final success = await _service.updateItem(
      id: id,
      name: name,
      description: description,
      priority: priority,
      status: status,
      comments: comments,
    );
    if (success && _currentListId != null) await fetchItems(_currentListId!);
    return success;
  }

  Future<bool> deleteItem(String id) async {
    final success = await _service.deleteItem(id);
    if (success) {
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> archiveItem(String id) async {
    final success = await _service.archiveItem(id);
    if (success) {
      // Arkiverade items ska inte visas i listan.
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    }
    return success;
  }

  // Bockar i/ur en uppgift. Uppdaterar lokalt direkt för snabb respons och
  // återställer om anropet misslyckas.
  Future<bool> toggleChecked(String id, bool isChecked) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return false;

    final previous = _items[index];
    _items[index] = previous.copyWith(isChecked: isChecked);
    notifyListeners();

    try {
      final success = await _service.setItemChecked(id, isChecked);
      if (!success) {
        _items[index] = previous; // Återställ vid fel
        notifyListeners();
      }
      return success;
    } catch (e) {
      _items[index] = previous; // Återställ vid fel/exception
      notifyListeners();
      if (e is SessionExpiredException) rethrow;
      return false;
    }
  }

  void clearItems() {
    _items = [];
    _currentListId = null;
    _itemsError = null;
    notifyListeners();
  }
}
