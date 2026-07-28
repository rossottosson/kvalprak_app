// lib/screens/todo_lists_screen.dart
// Översikt över alla att göra-listor.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/models/todo_models.dart';
import 'package:kvalprak_app/providers/todo_provider.dart';
import 'package:kvalprak_app/screens/todo_items_screen.dart';
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLists());
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

  Future<void> _fetchLists() async {
    try {
      await context.read<TodoProvider>().fetchLists();
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      debugPrint('Ett annat fel uppstod: $e');
    }
  }

  Future<void> _openList(TodoList list) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TodoItemsScreen(listId: list.id, listName: list.name),
      ),
    );
  }

  // Dialog för att skapa eller redigera en lista. list == null => skapa ny.
  Future<void> _showListDialog({TodoList? list}) async {
    final isEditing = list != null;
    final nameController = TextEditingController(text: list?.name ?? '');
    final descriptionController = TextEditingController(text: list?.description ?? '');
    final formKey = GlobalKey<FormState>();
    String? finishDate = list?.finishDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Redigera lista' : 'Ny lista'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Namn *'),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Namn är obligatoriskt.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Beskrivning'),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              finishDate == null || finishDate!.isEmpty
                                  ? 'Inget slutdatum'
                                  : 'Slutdatum: $finishDate',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.tryParse(finishDate ?? '') ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2101),
                              );
                              if (picked != null) {
                                setDialogState(() => finishDate = DateFormat('yyyy-MM-dd').format(picked));
                              }
                            },
                            child: const Text('Välj'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Avbryt')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                  child: Text(isEditing ? 'Spara' : 'Skapa'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    try {
      final provider = context.read<TodoProvider>();
      bool success;
      if (isEditing) {
        success = await provider.updateList(
          id: list.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          finishDate: finishDate,
        );
      } else {
        success = await provider.createList(
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          finishDate: finishDate,
        );
      }
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Kunde inte spara listan.' : 'Kunde inte skapa listan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  Future<void> _confirmDeleteList(TodoList list) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Radera lista'),
        content: Text('Vill du radera "${list.name}"? Alla uppgifter i listan raderas också. Detta går inte att ångra.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Avbryt')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Radera'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      final success = await context.read<TodoProvider>().deleteList(list.id);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte radera listan.'), backgroundColor: Colors.red),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Att göra')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showListDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ny lista'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLists,
        child: _buildBody(provider, textTheme),
      ),
    );
  }

  Widget _buildBody(TodoProvider provider, TextTheme textTheme) {
    if (provider.isLoadingLists && provider.lists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.listsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Kunde inte ladda listor:\n${provider.listsError}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    if (provider.lists.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.playlist_add_check, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Inga listor ännu.\nTryck på "Ny lista" för att komma igång.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    final lists = provider.lists;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.list_alt_rounded),
            title: Text(
              list.name,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: (list.description.isNotEmpty || (list.finishDate?.isNotEmpty ?? false))
                ? Text(
                    [
                      if (list.description.isNotEmpty) list.description,
                      if (list.finishDate?.isNotEmpty ?? false) 'Klart senast: ${list.finishDate}',
                    ].join('\n'),
                  )
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (choice) {
                if (choice == 'edit') _showListDialog(list: list);
                if (choice == 'delete') _confirmDeleteList(list);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Redigera'))),
                PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Radera'))),
              ],
            ),
            onTap: () => _openList(list),
          ),
        );
      },
    );
  }
}
