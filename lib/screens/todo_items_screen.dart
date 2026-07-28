// lib/screens/todo_items_screen.dart
// Visar uppgifterna i en specifik lista.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/models/todo_models.dart';
import 'package:kvalprak_app/providers/todo_provider.dart';
import 'package:kvalprak_app/screens/todo_item_form_screen.dart';
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class TodoItemsScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const TodoItemsScreen({
    required this.listId,
    required this.listName,
    super.key,
  });

  @override
  State<TodoItemsScreen> createState() => _TodoItemsScreenState();
}

class _TodoItemsScreenState extends State<TodoItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchItems());
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

  Future<void> _fetchItems() async {
    try {
      await context.read<TodoProvider>().fetchItems(widget.listId);
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      debugPrint('Ett annat fel uppstod: $e');
    }
  }

  Future<void> _toggleChecked(TodoItem item, bool value) async {
    try {
      final success = await context.read<TodoProvider>().toggleChecked(item.id, value);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte ändra status.'), backgroundColor: Colors.red),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  Future<void> _openForm({TodoItem? item}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TodoItemFormScreen(item: item)),
    );
    // Providern hämtar om items automatiskt efter spara, inget mer behövs här.
  }

  Future<void> _confirmDelete(TodoItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Radera uppgift'),
        content: Text('Är du säker på att du vill radera "${item.name}"? Detta går inte att ångra.'),
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
      final success = await context.read<TodoProvider>().deleteItem(item.id);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte radera uppgiften.'), backgroundColor: Colors.red),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  Future<void> _archive(TodoItem item) async {
    try {
      final success = await context.read<TodoProvider>().archiveItem(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Uppgiften arkiverades.' : 'Kunde inte arkivera uppgiften.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFF8B0000);
      case 'medium':
        return Colors.orange.shade700;
      case 'low':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.listName, overflow: TextOverflow.ellipsis)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Ny uppgift'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchItems,
        child: _buildBody(provider, textTheme),
      ),
    );
  }

  Widget _buildBody(TodoProvider provider, TextTheme textTheme) {
    if (provider.isLoadingItems && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.itemsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Kunde inte ladda uppgifter:\n${provider.itemsError}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.checklist_rtl, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Inga uppgifter ännu.\nTryck på "Ny uppgift" för att lägga till.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    final items = provider.items;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: item.isChecked,
              onChanged: (value) => _toggleChecked(item, value ?? false),
            ),
            title: Text(
              item.name,
              style: textTheme.titleMedium?.copyWith(
                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                color: item.isChecked ? Colors.grey : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColor(item.priority).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        TodoLabels.priorityLabel(item.priority),
                        style: TextStyle(color: _priorityColor(item.priority), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('• ${TodoLabels.statusLabel(item.status)}', style: const TextStyle(fontSize: 12)),
                    if (item.finishDate != null && item.finishDate!.isNotEmpty)
                      Text('• ${item.finishDate}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (choice) {
                if (choice == 'edit') _openForm(item: item);
                if (choice == 'archive') _archive(item);
                if (choice == 'delete') _confirmDelete(item);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Redigera'))),
                PopupMenuItem(value: 'archive', child: ListTile(leading: Icon(Icons.archive_outlined), title: Text('Arkivera'))),
                PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Radera'))),
              ],
            ),
            onTap: () => _openForm(item: item),
            isThreeLine: item.description.isNotEmpty,
          ),
        );
      },
    );
  }
}
