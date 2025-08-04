// lib/screens/checklists_overview_screen.dart
// HELT OMbygd FÖR ATT ANVÄNDA DEN NYA API-DRIVNA ChecklistProvider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/screens/checklist_detail_screen.dart';
import 'package:kvalprak_app/models/api_checklist_models.dart'; // Importera de nya modellerna

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
    // Anropa providern för att hämta checklistorna från API:et när skärmen byggs.
    // Vi använder addPostFrameCallback för att säkerställa att Provider är tillgänglig.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Använd 'read' i initState och andra engångs-anrop.
      context.read<ChecklistProvider>().fetchChecklists();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Använd 'watch' i build-metoden för att lyssna på ändringar
    final checklistProvider = context.watch<ChecklistProvider>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklistor'),
      ),
      // Body bygger nu sitt utseende baserat på state från providern
      body: _buildBody(checklistProvider, textTheme),
    );
  }

  // Hjälpmetod för att hålla build-metoden ren
  Widget _buildBody(ChecklistProvider provider, TextTheme textTheme) {
    // 1. Om vi laddar, visa en progress indicator
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Om ett fel har inträffat, visa ett felmeddelande
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

    // 3. Om listan är tom (och vi inte laddar), visa ett meddelande om det
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

    // 4. Om allt är bra och vi har data, bygg listan
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
              // Navigera till detaljvyn och skicka med den unika pageId
              // som behövs för att hämta frågorna.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChecklistDetailScreen(
                    // Notera: Vi skickar nu pageId, inte checklistId/formId
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