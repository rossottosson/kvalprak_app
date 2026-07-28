// lib/screens/todo_item_form_screen.dart
// Formulär för att skapa en ny uppgift eller redigera en befintlig.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/models/todo_models.dart';
import 'package:kvalprak_app/providers/todo_provider.dart';
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class TodoItemFormScreen extends StatefulWidget {
  // Om item != null redigerar vi, annars skapar vi en ny uppgift.
  final TodoItem? item;

  const TodoItemFormScreen({this.item, super.key});

  @override
  State<TodoItemFormScreen> createState() => _TodoItemFormScreenState();
}

class _TodoItemFormScreenState extends State<TodoItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _commentsController;
  late String _priority;
  late String _status;
  String? _finishDate;
  bool _isSaving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _commentsController = TextEditingController(text: item?.comments ?? '');
    _priority = item?.priority ?? 'medium';
    _status = item?.status ?? 'not_started';
    _finishDate = item?.finishDate;
    // Säkerställ att sparade värden finns bland alternativen (annars null).
    if (!TodoLabels.priorities.containsKey(_priority)) _priority = 'medium';
    if (!TodoLabels.statuses.containsKey(_status)) _status = 'not_started';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Din session har gått ut. Vänligen logga in igen.'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _selectFinishDate() async {
    DateTime initial = DateTime.now();
    if (_finishDate != null) {
      initial = DateTime.tryParse(_finishDate!) ?? DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _finishDate = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final provider = context.read<TodoProvider>();

    try {
      bool success;
      if (_isEditing) {
        success = await provider.updateItem(
          id: widget.item!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: _status,
          comments: _commentsController.text.trim(),
        );
      } else {
        success = await provider.createItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          finishDate: _finishDate,
          priority: _priority,
          status: _status,
          comments: _commentsController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Kunde inte spara ändringarna.' : 'Kunde inte skapa uppgiften.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ett fel uppstod: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Redigera uppgift' : 'Ny uppgift'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Namn *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Namn är obligatoriskt.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivning',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Prioritet',
                border: OutlineInputBorder(),
              ),
              items: TodoLabels.priorities.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _priority = value ?? 'medium'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: TodoLabels.statuses.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? 'not_started'),
            ),
            const SizedBox(height: 16),
            // Slutdatum kan bara sättas vid skapande (API:et tar inte emot det vid uppdatering).
            if (!_isEditing)
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _finishDate ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Slutdatum',
                  hintText: 'Valfritt',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectFinishDate,
              ),
            if (!_isEditing) const SizedBox(height: 16),
            TextFormField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Kommentarer',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Spara ändringar' : 'Skapa uppgift'),
            ),
          ],
        ),
      ),
    );
  }
}
