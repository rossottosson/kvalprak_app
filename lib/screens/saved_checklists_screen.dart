// lib/screens/saved_checklists_screen.dart
// KORRIGERAD VERSION MED RÄTT IMPORT

import 'package:flutter/material.dart'; // Rättad från 'package_flutter/material.dart'
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/models/api_checklist_models.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';

class SavedChecklistsScreen extends StatefulWidget {
  const SavedChecklistsScreen({super.key});

  @override
  State<SavedChecklistsScreen> createState() => _SavedChecklistsScreenState();
}

class _SavedChecklistsScreenState extends State<SavedChecklistsScreen> {
  ApiChecklist? _selectedChecklist;

  @override
  void initState() {
    super.initState();
    // Se till att listan med checklistor är laddad.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChecklistProvider>();
      // Hämta bara om listan är tom OCH vi inte redan laddar den.
      if (provider.checklists.isEmpty && !provider.isLoading) {
        provider.fetchChecklists();
      }
    });
  }

  void _selectChecklist(ApiChecklist checklist) {
    setState(() {
      _selectedChecklist = checklist;
    });
    // Hämta historiken för den valda checklistan
    context.read<ChecklistProvider>().fetchSubmissions(checklist.page.pageId);
  }

  void _goBackToChecklistSelection() {
    setState(() {
      _selectedChecklist = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedChecklist == null ? 'Välj Checklista' : 'Historik för "${_selectedChecklist!.name}"'),
        leading: _selectedChecklist != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Välj en annan checklista',
                onPressed: _goBackToChecklistSelection,
              )
            : null,
      ),
      body: _selectedChecklist == null
          ? _buildChecklistSelection()
          : _buildSubmissionsList(),
    );
  }

  Widget _buildChecklistSelection() {
    final provider = context.watch<ChecklistProvider>();
    if (provider.isLoading && provider.checklists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.checklists.isEmpty) {
        return Center(child: Text('Fel: ${provider.error}'));
    }
    if (provider.checklists.isEmpty) {
      return const Center(child: Text('Inga checklistor att visa.'));
    }

    return ListView.builder(
      itemCount: provider.checklists.length,
      itemBuilder: (context, index) {
        final checklist = provider.checklists[index];
        return ListTile(
          title: Text(checklist.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectChecklist(checklist),
        );
      },
    );
  }

  Widget _buildSubmissionsList() {
    final provider = context.watch<ChecklistProvider>();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
    final textTheme = Theme.of(context).textTheme;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Fel: ${provider.error}'));
    }
    if (provider.submissions.isEmpty) {
      return const Center(child: Text('Ingen historik hittades för denna checklista.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: provider.submissions.length,
      itemBuilder: (context, index) {
        final submission = provider.submissions[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.history_toggle_off_rounded, color: Colors.grey),
            title: Text(
              'Inskickad: ${formatter.format(submission.surveyDate)}',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('ID: ${submission.surveyId}'),
          ),
        );
      },
    );
  }
}