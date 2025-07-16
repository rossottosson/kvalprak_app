// lib/providers/checklist_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';
import 'package:kvalprak_app/models/saved_checklist_log.dart';

class ChecklistProvider with ChangeNotifier {
  static const String _checklistsBoxName = 'checklistsBox';
  static const String _savedLogsBoxName = 'savedLogsBox';

  late Box<Checklist> _checklistsBox;
  late Box<SavedChecklistLog> _savedLogsBox;

  List<Checklist> _checklists = [];
  List<SavedChecklistLog> _savedLogs = [];

  List<Checklist> get checklists => List.unmodifiable(_checklists);
  List<SavedChecklistLog> get savedLogs => List.unmodifiable(_savedLogs);

  // --- Define unique IDs for each default checklist section ---
  static const String _sIDLokaler = 'skyddsrond-lokaler-v1';
  static const String _sIDBrandskydd = 'skyddsrond-brandskydd-v1';
  static const String _sIDUtrustning = 'skyddsrond-utrustning-v1';
  static const String _sIDErgonomi = 'skyddsrond-ergonomi-v1';
  static const String _sIDKemikalier = 'skyddsrond-kemikalier-v1';
  static const String _sIDPsykosocial = 'skyddsrond-psykosocial-v1';
  static const String _sIDOvrigt = 'skyddsrond-ovrigt-v1';

  Future<void> loadData() async {
    _checklistsBox = Hive.box<Checklist>(_checklistsBoxName);
    _savedLogsBox = Hive.box<SavedChecklistLog>(_savedLogsBoxName);

    _checklists = _checklistsBox.values.toList();
    _savedLogs = _savedLogsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    debugPrint("ChecklistProvider: Loaded ${_checklists.length} checklists and ${_savedLogs.length} logs from Hive during initial load.");

    await _addDefaultChecklistsIfNecessary();

    // The addChecklist method (called by _addDefaultChecklistsIfNecessary) already updates _checklists
    // and calls notifyListeners. So, the _checklists list here will be up-to-date if defaults were added.
    // A final notifyListeners() from loadData ensures UI updates even if no defaults were added
    // but other initial loading aspects might warrant it.
    debugPrint("ChecklistProvider: Final count after checking defaults - Checklists: ${_checklists.length}, Logs: ${_savedLogs.length}");
    notifyListeners();
  }

  Future<void> _createAndAddChecklistIfNotExists({
    required String id,
    required String title,
    required List<ChecklistItem> items,
    String? comments,
  }) async {
    if (!_checklistsBox.containsKey(id)) {
      debugPrint("ChecklistProvider: Default checklist '$title' (ID: $id) not found. Adding it now...");
      final newChecklist = Checklist(
        id: id,
        title: title,
        items: items,
        comments: comments,
      );
      await addChecklist(newChecklist); // This method handles Hive and notifies listeners
    } else {
      debugPrint("ChecklistProvider: Default checklist '$title' (ID: $id) already exists.");
    }
  }

  Future<void> _addDefaultChecklistsIfNecessary() async {
    // Section 1: Lokaler och inomhusmiljö
    await _createAndAddChecklistIfNotExists(
      id: _sIDLokaler,
      title: "Lokaler & Inomhusmiljö",
      items: [
        ChecklistItem.newItem(text: "God belysning i alla arbetsutrymmen"),
        ChecklistItem.newItem(text: "Tillräcklig ventilation och temperatur"),
        ChecklistItem.newItem(text: "Golv och trappor är hela och halksäkra"),
        ChecklistItem.newItem(text: "Utrymningsvägar är tydliga och fria"),
      ],
    );

    // Section 2: Brandskydd och nödlägen
    await _createAndAddChecklistIfNotExists(
      id: _sIDBrandskydd,
      title: "Brandskydd & Nödlägen",
      items: [
        ChecklistItem.newItem(text: "Utrymningsplan är uppsatt och aktuell"),
        ChecklistItem.newItem(text: "Brandsläckare finns och är kontrollerade"),
        ChecklistItem.newItem(text: "Personal känner till samlingsplats"),
        ChecklistItem.newItem(text: "Nödutgångar är väl markerade"),
      ],
    );

    // Section 3: Arbetsutrustning och hjälpmedel
    await _createAndAddChecklistIfNotExists(
      id: _sIDUtrustning,
      title: "Arbetsutrustning & Hjälpmedel",
      items: [
        ChecklistItem.newItem(text: "Hjälpmedel är kontrollerade och fungerar"),
        ChecklistItem.newItem(text: "Elutrustning är hel och säkert installerad"),
        ChecklistItem.newItem(text: "Förflyttningshjälpmedel används korrekt"),
      ],
    );

    // Section 4: Ergonomi och belastning
    await _createAndAddChecklistIfNotExists(
      id: _sIDErgonomi,
      title: "Ergonomi & Belastning",
      items: [
        ChecklistItem.newItem(text: "Anpassade arbetsställningar är möjliga"),
        ChecklistItem.newItem(text: "Tunga lyft undviks eller görs med hjälp"),
        ChecklistItem.newItem(text: "Sitt- och ståarbetsplatser är ergonomiska"),
      ],
    );

    // Section 5: Kemikalier och hygien
    await _createAndAddChecklistIfNotExists(
      id: _sIDKemikalier,
      title: "Kemikalier & Hygien",
      items: [
        ChecklistItem.newItem(text: "Kemikalier är märkta och förvaras säkert"),
        ChecklistItem.newItem(text: "Säkerhetsdatablad finns tillgängliga"),
        ChecklistItem.newItem(text: "Rutiner för städning och hygien följs"),
        ChecklistItem.newItem(text: "Skyddsutrustning finns och används rätt"),
      ],
    );

    // Section 6: Psykosocial arbetsmiljö
    await _createAndAddChecklistIfNotExists(
      id: _sIDPsykosocial,
      title: "Psykosocial Arbetsmiljö",
      items: [
        ChecklistItem.newItem(text: "Det råder god stämning i arbetsgruppen"),
        ChecklistItem.newItem(text: "Arbetstakten är rimlig och hållbar"),
        ChecklistItem.newItem(text: "Tydlig ansvarsfördelning i arbetslaget"),
        ChecklistItem.newItem(text: "Rutiner mot kränkningar finns och följs"),
      ],
    );

    // Section 7: Övrigt / Önskemål från personal
    await _createAndAddChecklistIfNotExists(
      id: _sIDOvrigt,
      title: "Övrigt & Personalönskemål",
      items: [
        ChecklistItem.newItem(text: "Personalen upplever sig lyssnad på"),
        ChecklistItem.newItem(text: "Finns det behov av nya rutiner eller stöd?"),
      ],
      comments: "Här kan övriga punkter och önskemål från personalen tas upp."
    );
  }

  Future<void> addChecklist(Checklist checklist) async {
    await _checklistsBox.put(checklist.id, checklist);
    _checklists = _checklistsBox.values.toList();
    notifyListeners();
    debugPrint("Added/Updated checklist: ${checklist.title} (ID: ${checklist.id}) to Hive.");
  }

  Future<void> addSavedLog(SavedChecklistLog log) async {
    await _savedLogsBox.put(log.id, log);
    _savedLogs = _savedLogsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
    debugPrint("Added saved log for checklist: ${log.checklistTitle} to Hive.");
  }

  Checklist? findChecklistById(String id) {
    try {
      return _checklists.firstWhere((checklist) => checklist.id == id);
    } catch (e) {
      return _checklistsBox.get(id);
    }
  }

  Future<void> updateItemStatus(String checklistId, String itemId, bool isChecked) async {
    final checklist = _checklistsBox.get(checklistId);
    if (checklist != null) {
      final itemIndex = checklist.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final updatedItems = List<ChecklistItem>.from(checklist.items);
        updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(isChecked: isChecked);
        final updatedChecklist = checklist.copyWith(items: updatedItems);
        await _checklistsBox.put(checklistId, updatedChecklist);
        _checklists = _checklistsBox.values.toList();
        notifyListeners();
      }
    }
  }

  Future<void> updateChecklistComments(String checklistId, String? newComments) async {
    final checklist = _checklistsBox.get(checklistId);
    if (checklist != null) {
      final trimmedComment = newComments?.trim();
      final commentsToSave = (trimmedComment == null || trimmedComment.isEmpty) ? null : trimmedComment;
      final updatedChecklist = checklist.copyWith(
        comments: commentsToSave,
        setCommentsToNull: commentsToSave == null,
      );
      await _checklistsBox.put(checklistId, updatedChecklist);
      _checklists = _checklistsBox.values.toList();
      notifyListeners();
      debugPrint("Updated comments for $checklistId in Hive.");
    }
  }

  Future<void> clearChecklistItems(String checklistId) async {
    final checklist = _checklistsBox.get(checklistId);
    if (checklist != null) {
      final clearedItems = checklist.items
          .map((item) => item.copyWith(isChecked: false))
          .toList();
      final updatedChecklist = checklist.copyWith(items: clearedItems);
      await _checklistsBox.put(checklistId, updatedChecklist);
      _checklists = _checklistsBox.values.toList();
      notifyListeners();
      debugPrint("Cleared items for $checklistId in Hive.");
    }
  }

  Future<void> deleteChecklist(String id) async {
    await _checklistsBox.delete(id);
    _checklists = _checklistsBox.values.toList();
    notifyListeners();
    debugPrint("Deleted checklist $id from Hive.");
  }
}