// lib/screens/menu_structure_screen.dart
// UPPDATERAD: Navigerar till DocumentDetailScreen när ett dokument väljs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/models/document_models.dart';
import 'package:kvalprak_app/providers/document_provider.dart';
import 'package:kvalprak_app/screens/document_detail_screen.dart'; // Ny import

class MenuStructureScreen extends StatelessWidget {
  final String parentId;
  final String parentName;

  const MenuStructureScreen({
    required this.parentId,
    required this.parentName,
    super.key,
  });

  IconData _getIconForItemType(String type) {
    switch (type) {
      case 'menu':
        return Icons.folder_special_outlined;
      case 'folder':
        return Icons.folder_outlined;
      case 'document':
        return Icons.article_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = context.watch<DocumentProvider>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(parentName),
      ),
      body: _buildBody(documentProvider, textTheme),
    );
  }

  Widget _buildBody(DocumentProvider provider, TextTheme textTheme) {
    if (provider.isLoading && provider.menuItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Kunde inte ladda innehåll:\n${provider.error}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    final itemsToShow = provider.menuItems.where((item) => item.parentId == parentId).toList();

    if (itemsToShow.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Denna mapp är tom.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        final item = itemsToShow[index];

        return Card(
          child: ListTile(
            leading: Icon(_getIconForItemType(item.type)),
            title: Text(
              item.name,
              style: textTheme.titleMedium,
            ),
            trailing: (item.type != 'document') ? const Icon(Icons.chevron_right) : null,
            onTap: () {
              if (item.type == 'menu' || item.type == 'folder') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuStructureScreen(
                      parentId: item.id,
                      parentName: item.name,
                    ),
                  ),
                );
              } else if (item.type == 'document') {
                // HÄR ÄR ÄNDRINGEN: Navigera till detaljvyn
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentDetailScreen(
                      documentId: item.id,
                      documentName: item.name,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}