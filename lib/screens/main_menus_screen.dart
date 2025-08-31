// lib/screens/main_menus_screen.dart
// UPPDATERAD: Anropar fetchMenuStructure och rensar gammal data vid behov.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/document_provider.dart';
import 'package:kvalprak_app/services/checklist_service.dart'; // For SessionExpiredException
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/screens/menu_structure_screen.dart';

class MainMenusScreen extends StatefulWidget {
  const MainMenusScreen({super.key});

  @override
  State<MainMenusScreen> createState() => _MainMenusScreenState();
}

class _MainMenusScreenState extends State<MainMenusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Rensa eventuell gammal data när vi kommer till denna skärm
      context.read<DocumentProvider>().clearMenuStructure();
      _fetchData();
    });
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  Future<void> _fetchData() async {
    try {
      await context.read<DocumentProvider>().fetchMainMenus();
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  // Anropas när användaren väljer en meny
  Future<void> _onMenuSelected(String menuId, String menuName) async {
    try {
      // Ladda hela strukturen för den valda menyn
      await context.read<DocumentProvider>().fetchMenuStructure(menuId);
      if (mounted) {
        // Navigera sedan till första nivån i strukturen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuStructureScreen(
              // Den första nivån har huvudmenyns ID som sin förälder
              parentId: menuId,
              parentName: menuName,
            ),
          ),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
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
      body: _buildBody(documentProvider, textTheme),
    );
  }

  Widget _buildBody(DocumentProvider provider, TextTheme textTheme) {
    if (provider.isLoading && provider.mainMenus.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Kunde inte ladda menyer:\n${provider.error}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

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
      padding: const EdgeInsets.all(8.0),
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