// lib/screens/checklists_overview_screen.dart
// UPPDATERAD: Fångar nu SessionExpiredException och navigerar till login.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/screens/checklist_detail_screen.dart';
import 'package:kvalprak_app/models/api_checklist_models.dart';
import 'package:kvalprak_app/services/checklist_service.dart'; // Importera för exception
import 'package:kvalprak_app/login_screen.dart'; // Importera för navigation

// Vi gör om skärmen till en StatefulWidget för att kunna hämta data i initState
class ChecklistsOverviewScreen extends StatefulWidget {
  const ChecklistsOverviewScreen({super.key});

  @override
  State<ChecklistsOverviewScreen> createState() => _ChecklistsOverviewScreenState();
}

class _ChecklistsOverviewScreenState extends State<ChecklistsOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
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
      await context.read<ChecklistProvider>().fetchChecklists();
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklistProvider = context.watch<ChecklistProvider>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklistor'),
      ),
      body: _buildBody(checklistProvider, textTheme),
    );
  }

  Widget _buildBody(ChecklistProvider provider, TextTheme textTheme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Kunde inte ladda checklistor:\n${provider.error}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    if (provider.checklists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Inga checklistor hittades.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final List<ApiChecklist> checklists = provider.checklists;
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: checklists.length,
      itemBuilder: (context, index) {
        final checklist = checklists[index];

        return Card(
          child: ListTile(
            title: Text(
              checklist.name,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChecklistDetailScreen(
                    pageId: checklist.page.pageId,
                    checklistTitle: checklist.name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}