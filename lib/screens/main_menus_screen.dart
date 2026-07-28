// lib/screens/main_menus_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/document_provider.dart';
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/screens/menu_structure_screen.dart';
import 'package:kvalprak_app/screens/document_detail_screen.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class MainMenusScreen extends StatefulWidget {
  const MainMenusScreen({super.key});

  @override
  State<MainMenusScreen> createState() => _MainMenusScreenState();
}

class _MainMenusScreenState extends State<MainMenusScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().clearMenuStructure();
      context.read<DocumentProvider>().clearSearch();
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _fetchData() async {
    try {
      await context.read<DocumentProvider>().fetchMainMenus();
    } catch (e) {
      if (e is SessionExpiredException) {
        _handleSessionExpired();
      } else {
        debugPrint("Ett annat fel uppstod: $e");
      }
    }
  }

  Future<void> _onMenuSelected(String menuId, String menuName) async {
    // Rensa sökningen när man klickar in i en mapp så den är ren när man backar
    _searchController.clear();
    context.read<DocumentProvider>().clearSearch();
    
    try {
      await context.read<DocumentProvider>().fetchMenuStructure(menuId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuStructureScreen(
              parentId: menuId,
              parentName: menuName,
            ),
          ),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      debugPrint('Kunde inte ladda menystruktur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = context.watch<DocumentProvider>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokument'),
      ),
      body: Column(
        children: [
          // SÖKFÄLTET
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Sök dokument...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<DocumentProvider>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                if (value.length >= 3) {
                  context.read<DocumentProvider>().searchDocuments(value);
                } else if (value.isEmpty) {
                  context.read<DocumentProvider>().clearSearch();
                }
              },
            ),
          ),
          
          // LISTAN (Mappar eller sökresultat)
          Expanded(
            child: _buildBody(documentProvider, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DocumentProvider provider, TextTheme textTheme) {
    if (provider.isLoading || provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Ett fel uppstod:\n${provider.error}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    // SCENARIO 1: Användaren har sökt och fått träffar
    if (_searchController.text.length >= 3) {
      if (provider.searchResults.isEmpty) {
        return Center(
          child: Text(
            'Inga dokument matchade "${_searchController.text}"',
            style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: provider.searchResults.length,
        itemBuilder: (context, index) {
          final doc = provider.searchResults[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(doc.name, style: textTheme.titleMedium),
              subtitle: Text('${doc.menuName} > ${doc.folderName}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentDetailScreen(
                      documentId: doc.id,
                      documentName: doc.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    // SCENARIO 2: Visar vanliga mappar när man inte söker
    if (provider.mainMenus.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Inga dokumentmenyer hittades.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final menus = provider.mainMenus;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: Text(
              menu.name,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _onMenuSelected(menu.id, menu.name),
          ),
        );
      },
    );
  }
}