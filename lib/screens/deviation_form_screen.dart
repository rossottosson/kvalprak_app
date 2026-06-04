// lib/screens/deviation_form_screen.dart
// UPPDATERAD: Förhandsväljer det första alternativet i alla dropdown-menyer.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kvalprak_app/models/deviation_field.dart';
import 'package:kvalprak_app/models/deviation_form_data.dart';
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/services/deviation_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import 'package:kvalprak_app/login_screen.dart'; // Ny import

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

  late final String _newDeviationId;
  final Set<String> _uploadingFiles = {};

  final List<String> _selectedEmailIds = [];

  bool _speechEnabled = false;
  bool _isListening = false;
  String _selectedLocaleId = '';
  bool _isLoading = true;
  List<DeviationField> _fields = [];
  Map<String, dynamic> _options = {};
  String? _error;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _dropdownValues = {};
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    _newDeviationId = const Uuid().v4();
    _initSpeech();
    _loadForm();
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

  Future<void> _loadForm() async {
    final token = await _authService.getToken();
    if (token == null) {
      _handleSessionExpired();
      return;
    }
    try {
      final formData = await _deviationService.getDeviationFields(token: token);
      final userName = await _authService.getCurrentUserName();
      final userEmail = await _authService.getCurrentUserEmail();

      if (!mounted) return;

      setState(() {
        _fields = formData.fields;
        _options = formData.options;
        _isLoading = false;

        for (var field in _fields) {
          // Sätt upp text controllers och fyll i standardvärden
          final controller = TextEditingController();
          final titleLower = field.title.toLowerCase();
          if (titleLower.contains('händelsedatum')) {
            controller.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
          } else if (titleLower.contains('anmält av') && userName != null && userEmail != null) {
            controller.text = '$userName ($userEmail)';
          } else if (titleLower.contains('e-post') && userEmail != null && field.inputType != 'email') {
            controller.text = userEmail;
          }
          _controllers[field.id] = controller;

          // NY LOGIK: Om fältet är en dropdown, välj det första alternativet
          if (field.inputType == 'dropdown' || field.inputType == 'department' || field.inputType == 'eventanalysis') {
            final fieldOptions = _options[field.id] as Map<String, dynamic>? ?? {};
            if (fieldOptions.isNotEmpty) {
              // Hämta ID för det första alternativet i listan
              final firstOptionId = fieldOptions.keys.first;
              // Sätt det som det valda värdet i state
              _dropdownValues[field.id] = firstOptionId;
            }
          }
        }
      });
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      if (!mounted) return;
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
        _handleSessionExpired();
        return;
      }

      Map<String, dynamic> submissionData = {
        'page': 1,
        'id': _newDeviationId,
      };
      DeviationField? emailField;
      try {
        emailField = _fields.firstWhere((field) => field.inputType == 'email');
      } catch (e) {
        emailField = null;
      }

      for (var field in _fields) {
        final fieldId = field.id;
        final inputType = field.inputType;

        if (inputType == 'department' || inputType == 'eventanalysis') {
          final selectedValue = _dropdownValues[fieldId];
          if (selectedValue != null) submissionData[inputType] = [selectedValue];
        } else if (inputType == 'dropdown') {
          final selectedValue = _dropdownValues[fieldId];
          if (selectedValue != null) submissionData['deviation_$fieldId'] = selectedValue;
        } else if (inputType == 'email') {
          continue;
        } else if (inputType == 'upload') {
          continue;
        } else {
          final controllerValue = _controllers[fieldId]?.text;
          if (controllerValue != null && controllerValue.isNotEmpty) {
            submissionData['deviation_$fieldId'] = controllerValue;
          }
        }
      }

      if (emailField != null && _selectedEmailIds.isNotEmpty) {
        submissionData['emailId'] = emailField.id;
        submissionData['emails'] = _selectedEmailIds;
      }

      try {
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
            const SnackBar(content: Text('Kunde inte rapportera avvikelse.'), backgroundColor: Colors.red),
          );
        }
      } on SessionExpiredException {
        _handleSessionExpired();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ett okänt fel uppstod: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vänligen fyll i alla obligatoriska fält.'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final token = await _authService.getToken();
    if (token == null) {
      _handleSessionExpired();
      return;
    }

    setState(() {
      _imageFiles.add(pickedFile);
      _uploadingFiles.add(pickedFile.path);
    });

    try {
      final success = await _deviationService.uploadAttachment(
        token: token,
        deviationId: _newDeviationId,
        file: pickedFile,
      );

      if (!mounted) return;

      setState(() {
        _uploadingFiles.remove(pickedFile.path);
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kunde inte ladda upp ${pickedFile.name}')));
        setState(() {
          _imageFiles.removeWhere((file) => file.path == pickedFile.path);
        });
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ett okänt fel uppstod vid uppladdning: $e')));
      setState(() {
        _imageFiles.removeWhere((file) => file.path == pickedFile.path);
        _uploadingFiles.remove(pickedFile.path);
      });
    }
  }

  // ----- All kod under denna rad är oförändrad från din version -----

  String? _validateEmails(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    final emails = value.split(',');
    for (final email in emails) {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isNotEmpty && !emailRegex.hasMatch(trimmedEmail)) {
        return 'Innehåller en ogiltig e-postadress: "$trimmedEmail"';
      }
    }
    return null;
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (_speechEnabled) {
      var locales = await _speechToText.locales();
      var foundLocale = locales.firstWhere((l) => l.localeId.startsWith('sv'), orElse: () => locales.firstWhere((l) => l.localeId == 'en_US', orElse: () => locales.first));
      _selectedLocaleId = foundLocale.localeId;
    }
    if (mounted) setState(() {});
  }

  void _startListening(TextEditingController controller) async {
    await _speechToText.listen(onResult: (result) => setState(() => controller.text = result.recognizedWords), localeId: _selectedLocaleId);
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
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
    showModalBottomSheet(context: context, builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Välj från galleri'),
              onTap: () {
                _pickAndUploadImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ta en ny bild'),
              onTap: () {
                _pickAndUploadImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
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
                        onPressed: _uploadingFiles.isNotEmpty ? null : _submitForm,
                        child: _uploadingFiles.isNotEmpty
                            ? const Text('Väntar på filuppladdning...')
                            : const Text('Skicka Rapport'),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildFormFields() {
    final fieldsToBuild = _fields.where((f) => f.inputType != 'upload').toList();

    return fieldsToBuild.map((field) {
      switch (field.inputType) {
        case 'date':
          return _buildDatePickerField(field);
        case 'email':
          return _buildMultiSelectField(field);
        case 'dropdown':
        case 'department':
        case 'eventanalysis':
          return _buildDropdownField(field);
        default:
          return _buildTextField(field);
      }
    }).toList();
  }

  Widget _buildTextField(DeviationField field) {
    bool isDescriptionField = field.title.toLowerCase().contains('beskrivning');
    bool isEmailField = field.title.toLowerCase().contains('e-post');
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
        keyboardType: isDescriptionField ? TextInputType.multiline : isEmailField ? TextInputType.emailAddress : TextInputType.text,
        validator: (value) {
          if (field.isRequired && (value == null || value.isEmpty)) {
            return 'Detta fält är obligatoriskt.';
          }
          if (isEmailField) {
            return _validateEmails(value);
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

  Widget _buildMultiSelectField(DeviationField field) {
    final fieldOptions = _options[field.id] as Map<String, dynamic>? ?? {};
    final selectedNames = _selectedEmailIds.map((id) {
      return fieldOptions[id]?['name'] ?? 'Okänt val';
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FormField<List<String>>(
        initialValue: _selectedEmailIds,
        validator: (value) {
          if (field.isRequired && (value == null || value.isEmpty)) {
            return 'Vänligen gör minst ett val.';
          }
          return null;
        },
        builder: (formFieldState) {
          return InkWell(
            onTap: () async {
              await _showEmailSelectionDialog(field, fieldOptions);
              formFieldState.didChange(_selectedEmailIds);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: field.title,
                helperText: field.description,
                helperMaxLines: 3,
                helperStyle: TextStyle(color: Colors.grey[600]),
                border: const OutlineInputBorder(),
                errorText: formFieldState.errorText,
              ),
              child: _selectedEmailIds.isEmpty
                  ? Text('Välj en eller flera...', style: TextStyle(color: Colors.grey[600]))
                  : Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: selectedNames.map((name) => Chip(label: Text(name))).toList(),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEmailSelectionDialog(DeviationField field, Map<String, dynamic> options) async {
    final tempSelectedIds = List<String>.from(_selectedEmailIds);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(field.title),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.entries.map((entry) {
                    final optionId = entry.key;
                    final optionName = entry.value['name'] as String;
                    final isSelected = tempSelectedIds.contains(optionId);

                    return CheckboxListTile(
                      title: Text(optionName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            tempSelectedIds.add(optionId);
                          } else {
                            tempSelectedIds.remove(optionId);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Avbryt'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedEmailIds.clear();
                  _selectedEmailIds.addAll(tempSelectedIds);
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownField(DeviationField field) {
    final List<DropdownMenuItem<String>> items = [];
    final fieldOptions = _options[field.id] as Map<String, dynamic>? ?? {};

    fieldOptions.forEach((key, value) {
      items.add(DropdownMenuItem(value: key, child: Text(value['name'].toString())));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _dropdownValues[field.id] as String?,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.title,
          helperText: field.description,
          helperMaxLines: 3,
          helperStyle: TextStyle(color: Colors.grey[600]),
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: (String? newValue) {
          setState(() {
            _dropdownValues[field.id] = newValue;
          });
        },
        validator: (value) {
          if (field.isRequired && (value == null || value.isEmpty)) {
            return 'Vänligen gör ett val.';
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
                    final file = _imageFiles[index];
                    final isUploading = _uploadingFiles.contains(file.path);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.file(File(file.path), height: 100, width: 100, fit: BoxFit.cover),
                          if (isUploading)
                            Container(
                              height: 100,
                              width: 100,
                              color: Colors.black.withOpacity(0.5),
                              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                            ),
                          if (!isUploading)
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