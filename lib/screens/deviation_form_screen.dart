// lib/screens/deviation_form_screen.dart
// UPPDATERAD MED BILDHANTERING (KAMERA & GALLERI)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Importera nya paketet
import 'package:intl/intl.dart';
import 'package:kvalprak_app/models/deviation_field.dart';
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/services/deviation_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

class DeviationFormScreen extends StatefulWidget {
  const DeviationFormScreen({super.key});

  @override
  State<DeviationFormScreen> createState() => _DeviationFormScreenState();
}

class _DeviationFormScreenState extends State<DeviationFormScreen> {
  // ... befintliga variabler ...
  final _deviationService = DeviationService();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _selectedLocaleId = '';
  bool _isLoading = true;
  List<DeviationField> _fields = [];
  String? _error;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};

  // NYTT: Variabler för bildhantering
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadForm();
  }
  
  // --- INGEN ÄNDRING I NEDANSTÅENDE METODER ---
  void _initSpeech() async { /* ... oförändrad ... */ 
    _speechEnabled = await _speechToText.initialize();
    if (_speechEnabled) {
      var locales = await _speechToText.locales();
      var foundLocale = locales.firstWhere((l) => l.localeId.startsWith('sv'), orElse: () => locales.firstWhere((l) => l.localeId == 'en_US', orElse: () => locales.first));
      _selectedLocaleId = foundLocale.localeId;
    }
    setState(() {});
  }
  void _startListening(TextEditingController controller) async { /* ... oförändrad ... */ 
    await _speechToText.listen(onResult: (result) => setState(() => controller.text = result.recognizedWords), localeId: _selectedLocaleId);
    setState(() => _isListening = true);
  }
  void _stopListening() async { /* ... oförändrad ... */ 
    await _speechToText.stop();
    setState(() => _isListening = false);
  }
  Future<void> _loadForm() async { /* ... oförändrad ... */ 
    final token = await _authService.getToken();
    if (token == null) { setState(() { _isLoading = false; _error = "Autentiseringstoken saknas. Logga in igen."; }); return; }
    try {
      final fetchedFields = await _deviationService.getDeviationFields(token: token);
      setState(() {
        _fields = fetchedFields;
        _isLoading = false;
        for (var field in _fields) {
          _controllers[field.id] = TextEditingController();
          if (field.title.toLowerCase().contains('händelsedatum')) { _controllers[field.id]!.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); }
        }
      });
    } catch (e) { setState(() { _isLoading = false; _error = e.toString(); }); }
  }
  Future<void> _selectDate(BuildContext context, String fieldId) async { /* ... oförändrad ... */ 
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2101));
    if (picked != null) { setState(() { _controllers[fieldId]!.text = DateFormat('yyyy-MM-dd').format(picked); }); }
  }
  // --- SLUT PÅ OFÖRÄNDRADE METODER ---


  /// MODIFIERAD: Inkluderar nu bilderna (när vi vet hur de ska skickas)
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // VIKTIGT: Denna logik är ofullständig tills vi får svar från server-teamet
      // Just nu visar vi bara ett meddelande.
      if (_imageFiles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_imageFiles.length} bilder valda, men uppladdning är ej implementerad än.')),
        );
        print("Bilder som ska laddas upp: ${_imageFiles.map((f) => f.path).toList()}");
      }
      
      // Den gamla logiken för att skicka textdata kan ligga kvar,
      // men hela denna metod måste byggas om till en multipart-request senare.
      // Vi avvaktar med det.
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // --- NYA METODER FÖR BILDHANTERING ---

  /// Visar en dialog för att välja mellan kamera eller galleri
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Välj från galleri'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ta en ny bild'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Öppnar kameran eller galleriet för att välja en bild
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(pickedFile);
      });
    }
  }
  
  /// Tar bort en vald bild från listan
  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapportera Avvikelse')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Ett fel uppstod: $_error')))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      ..._buildFormFields(),
                      const SizedBox(height: 16),
                      // NYTT: Sektion för bilagor
                      _buildAttachmentSection(),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Skicka Rapport'),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  // --- OFÖRÄNDRADE WIDGET-BYGGARE ---
  List<Widget> _buildFormFields() { /* ... oförändrad ... */
    return _fields.map((field) {
      String titleLower = field.title.toLowerCase();
      if (titleLower.contains('händelsedatum')) { return _buildDatePickerField(field); } 
      else if (titleLower.contains('ärendetyp')) { return _buildDropdownField(field); } 
      else { return _buildTextField(field); }
    }).toList();
  }
  Widget _buildTextField(DeviationField field) { /* ... oförändrad ... */ 
    bool isDescriptionField = field.title.toLowerCase().contains('beskrivning');
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: TextFormField(controller: _controllers[field.id], decoration: InputDecoration(labelText: field.title, helperText: field.description, helperMaxLines: 3, helperStyle: TextStyle(color: Colors.grey[600]), border: const OutlineInputBorder(), suffixIcon: isDescriptionField && _speechEnabled ? IconButton(icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : null), onPressed: () => _isListening ? _stopListening() : _startListening(_controllers[field.id]!),) : null,), maxLines: isDescriptionField ? 5 : 1, keyboardType: isDescriptionField ? TextInputType.multiline : TextInputType.text, validator: (value) { if (field.isRequired && (value == null || value.isEmpty)) { return 'Detta fält är obligatoriskt.'; } return null; },),);
  }
  Widget _buildDatePickerField(DeviationField field) { /* ... oförändrad ... */ 
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: TextFormField(controller: _controllers[field.id], decoration: InputDecoration(labelText: field.title, helperText: field.description, helperMaxLines: 3, helperStyle: TextStyle(color: Colors.grey[600]), border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today),), readOnly: true, onTap: () => _selectDate(context, field.id),),);
  }
  Widget _buildDropdownField(DeviationField field) { /* ... oförändrad ... */
    final List<String> items = ['förslag', 'klagomål', 'negativ händelse', 'risk'];
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: DropdownButtonFormField<String>(value: _dropdownValues[field.id], decoration: InputDecoration(labelText: field.title, helperText: field.description, helperMaxLines: 3, helperStyle: TextStyle(color: Colors.grey[600]), border: const OutlineInputBorder(),), hint: const Text('Välj en ärendetyp'), items: items.map<DropdownMenuItem<String>>((String value) { return DropdownMenuItem<String>(value: value, child: Text(value),); }).toList(), onChanged: (String? newValue) { setState(() { _dropdownValues[field.id] = newValue; _controllers[field.id]!.text = newValue ?? ''; }); }, validator: (value) { if (field.isRequired && value == null) { return 'Vänligen välj en ärendetyp.'; } return null; },),);
  }
  // --- SLUT PÅ OFÖRÄNDRADE WIDGET-BYGGARE ---


  // NYTT: Bygger upp sektionen för bilagor
  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bilagor', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        // Visar valda bilder
        Container(
          height: 100,
          child: _imageFiles.isEmpty
              ? const Center(child: Text('Inga bilder valda.'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Image.file(File(_imageFiles[index].path), height: 100, width: 100, fit: BoxFit.cover),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        // Knappen för att lägga till en bild
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('Lägg till bild'),
          onPressed: () => _showImageSourceActionSheet(context),
        ),
      ],
    );
  }
}