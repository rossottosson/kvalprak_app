// lib/screens/deviation_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadForm();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (_speechEnabled) {
      var locales = await _speechToText.locales();
      var foundLocale = locales.firstWhere(
        (l) => l.localeId.startsWith('sv'),
        orElse: () => locales.firstWhere(
          (l) => l.localeId == 'en_US',
          orElse: () => locales.first,
        ),
      );
      _selectedLocaleId = foundLocale.localeId;
    }
    setState(() {});
  }

  void _startListening(TextEditingController controller) async {
    await _speechToText.listen(
      onResult: (result) => setState(() => controller.text = result.recognizedWords),
      localeId: _selectedLocaleId,
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _loadForm() async {
    final token = await _authService.getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = "Autentiseringstoken saknas. Logga in igen.";
      });
      return;
    }
    try {
      final fetchedFieldsFuture = _deviationService.getDeviationFields(token: token);
      final userNameFuture = _authService.getCurrentUserName();
      final userEmailFuture = _authService.getCurrentUserEmail();

      final fetchedFields = await fetchedFieldsFuture;
      final userName = await userNameFuture;
      final userEmail = await userEmailFuture;

      setState(() {
        _fields = fetchedFields;
        _isLoading = false;

        final arendeTypOptions = ['förslag', 'klagomål', 'negativ händelse', 'risk'];

        for (var field in _fields) {
          final controller = TextEditingController();
          final titleLower = field.title.toLowerCase();

          if (titleLower.contains('händelsedatum')) {
            controller.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
          } else if (titleLower.contains('anmält av') && userName != null) {
            controller.text = userName;
          } else if (titleLower.contains('e-post') && userEmail != null) {
            controller.text = userEmail;
          } else if (titleLower.contains('ärendetyp')) {
            final firstOption = arendeTypOptions.first;
            controller.text = firstOption;
            _dropdownValues[field.id] = firstOption;
          }
          _controllers[field.id] = controller;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = "Autentisering saknas.";
        });
        return;
      }

      Map<String, dynamic> submissionData = {'page': 1};
      _controllers.forEach((fieldId, controller) {
        final apiKey = 'deviation_$fieldId';
        submissionData[apiKey] = controller.text;
      });

      final success = await _deviationService.submitDeviation(
        token: token,
        submissionData: submissionData,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avvikelse rapporterad!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte rapportera avvikelse (se terminal för fel).'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vänligen fyll i alla obligatoriska fält.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String fieldId) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        _controllers[fieldId]!.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(pickedFile);
      });
    }
  }

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

  List<Widget> _buildFormFields() {
    return _fields.map((field) {
      String titleLower = field.title.toLowerCase();
      if (titleLower.contains('händelsedatum')) {
        return _buildDatePickerField(field);
      } else if (titleLower.contains('ärendetyp')) {
        return _buildDropdownField(field);
      } else {
        return _buildTextField(field);
      }
    }).toList();
  }

  Widget _buildTextField(DeviationField field) {
    bool isDescriptionField = field.title.toLowerCase().contains('beskrivning');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[field.id],
        decoration: InputDecoration(
          labelText: field.title,
          helperText: field.description,
          helperMaxLines: 3,
          helperStyle: TextStyle(color: Colors.grey[600]),
          border: const OutlineInputBorder(),
          suffixIcon: isDescriptionField && _speechEnabled
              ? IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : null),
                  onPressed: () => _isListening ? _stopListening() : _startListening(_controllers[field.id]!),
                )
              : null,
        ),
        maxLines: isDescriptionField ? 5 : 1,
        keyboardType: isDescriptionField ? TextInputType.multiline : TextInputType.text,
        validator: (value) {
          if (field.isRequired && (value == null || value.isEmpty)) {
            return 'Detta fält är obligatoriskt.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePickerField(DeviationField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[field.id],
        decoration: InputDecoration(
          labelText: field.title,
          helperText: field.description,
          helperMaxLines: 3,
          helperStyle: TextStyle(color: Colors.grey[600]),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () => _selectDate(context, field.id),
      ),
    );
  }

  Widget _buildDropdownField(DeviationField field) {
    final List<String> items = ['förslag', 'klagomål', 'negativ händelse', 'risk'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _dropdownValues[field.id],
        decoration: InputDecoration(
          labelText: field.title,
          helperText: field.description,
          helperMaxLines: 3,
          helperStyle: TextStyle(color: Colors.grey[600]),
          border: const OutlineInputBorder(),
        ),
        hint: const Text('Välj en ärendetyp'),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _dropdownValues[field.id] = newValue;
            _controllers[field.id]!.text = newValue ?? '';
          });
        },
        validator: (value) {
          if (field.isRequired && value == null) {
            return 'Vänligen välj en ärendetyp.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bilagor', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
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
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('Lägg till bild'),
          onPressed: () => _showImageSourceActionSheet(context),
        ),
      ],
    );
  }
}