// lib/screens/checklist_detail_screen.dart
// UPPDATERAD: Fångar nu SessionExpiredException och navigerar till login.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/models/api_checklist_models.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/services/checklist_service.dart'; // Importera för exception
import 'package:kvalprak_app/login_screen.dart'; // Importera för navigation

class ChecklistDetailScreen extends StatefulWidget {
  final String pageId;
  final String checklistTitle;

  const ChecklistDetailScreen({
    required this.pageId,
    required this.checklistTitle,
    super.key,
  });

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestions();
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

  Future<void> _fetchQuestions() async {
    try {
      await context.read<ChecklistProvider>().fetchQuestions(widget.pageId);
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  Future<void> _submitChecklist() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vänligen fyll i alla obligatoriska fält.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = context.read<ChecklistProvider>();
    final Map<String, dynamic> formattedAnswers = {};
    _answers.forEach((questionId, answer) {
      formattedAnswers['form_$questionId'] = answer;
    });

    try {
      final success = await provider.submitAnswers(widget.pageId, formattedAnswers);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checklistan har skickats in!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kunde inte skicka in checklistan: ${provider.error ?? 'Okänt fel'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    }
  }

  Future<void> _selectChecklistDate(ApiQuestion question) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _answers[question.questionId] = formattedDate;
      });
    }
  }

  ApiQuestion? _findQuestionById(String id) {
    final questions = context.read<ChecklistProvider>().currentPageData?.questions;
    if (questions == null) return null;
    try {
      return questions.firstWhere((q) => q.questionId == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checklistTitle),
        leading: BackButton(
          onPressed: () {
            context.read<ChecklistProvider>().clearCurrentPage();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Consumer<ChecklistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || provider.currentPageData == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitChecklist,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Skicka in'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    final provider = context.watch<ChecklistProvider>();

    if (provider.isLoading && provider.currentPageData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Fel: ${provider.error}', style: const TextStyle(color: Colors.red)),
      ));
    }
    if (provider.currentPageData == null || provider.currentPageData!.questions.isEmpty) {
      return const Center(child: Text('Inga frågor hittades för denna checklista.'));
    }

    final questions = provider.currentPageData!.questions;
    final headings = questions.where((q) => q.parentId == null).toList();
    headings.sort((a, b) => a.sort.compareTo(b.sort));

    return Form(
      key: _formKey,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: headings.length,
        itemBuilder: (context, index) {
          final heading = headings[index];

          if (heading.type == 'heading') {
            final subQuestions = questions
                .where((q) => q.parentId == heading.questionId)
                .toList();
            subQuestions.sort((a, b) => a.sort.compareTo(b.sort));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
                  child: Text(
                    heading.text,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ...subQuestions.map((question) => _buildQuestionWidget(question)),
              ],
            );
          }
          return _buildQuestionWidget(heading);
        },
      ),
    );
  }

  Widget _buildQuestionWidget(ApiQuestion question, {bool isInTable = false}) {
    final bool isRequired = question.validate.contains('required');

    Widget content;

    final descriptionWidget = (question.description.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              question.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          )
        : const SizedBox.shrink();

    switch (question.type) {
      case 'radio':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${question.text}${isRequired ? " *" : ""}', style: Theme.of(context).textTheme.titleMedium),
            descriptionWidget,
            if (question.options.length >= 2)
              FormField<String>(
                validator: (value) {
                  if (isRequired && _answers[question.questionId] == null) {
                    return 'Vänligen gör ett val.';
                  }
                  return null;
                },
                builder: (formFieldState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8.0, // Mellanrum i sidled
                        runSpacing: 8.0, // Mellanrum i höjdled när de bryts till ny rad
                        children: question.options.map((opt) {
                          final bool isSelected = _answers[question.questionId] == opt.optionId;
                          return ChoiceChip(
                            label: Text(opt.name),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                // Vid radio-knappar sätter vi alltid värdet till det valda alternativet
                                _answers[question.questionId] = opt.optionId;
                                formFieldState.didChange(opt.optionId);
                              });
                            },
                            // Lite styling så det ser snyggt ut och passar appens färgtema
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      if (formFieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                          child: Text(
                            formFieldState.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        );
        break;

      case 'users':
      case 'dropdown':
        content = DropdownButtonFormField<String>(
          value: _answers[question.questionId] as String?,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: '${question.text}${isRequired ? " *" : ""}',
            helperText: question.description,
            border: const OutlineInputBorder(),
          ),
          items: question.options.map((opt) {
            return DropdownMenuItem(value: opt.optionId, child: Text(opt.name));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _answers[question.questionId] = newValue;
            });
          },
          validator: (value) {
            if (isRequired && value == null) {
              return 'Vänligen gör ett val.';
            }
            return null;
          },
        );
        break;

      case 'checkbox':
        content = FormField<List<dynamic>>(
          initialValue: _answers[question.questionId] as List<dynamic>? ?? [],
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Minst ett val måste göras.';
            }
            return null;
          },
          builder: (formFieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${question.text}${isRequired ? " *" : ""}', style: Theme.of(context).textTheme.titleMedium),
                descriptionWidget,
                ...question.options.map((option) {
                  final bool isChecked = (formFieldState.value ?? []).contains(option.optionId);
                  return CheckboxListTile(
                    title: Text(option.name),
                    value: isChecked,
                    onChanged: (bool? value) {
                      final currentAnswers = List<dynamic>.from(formFieldState.value ?? []);
                      if (value == true) {
                        currentAnswers.add(option.optionId);
                      } else {
                        currentAnswers.remove(option.optionId);
                      }
                      setState(() {
                        _answers[question.questionId] = currentAnswers;
                        formFieldState.didChange(currentAnswers);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
                if (formFieldState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                    child: Text(
                      formFieldState.errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );
        break;

      case 'date':
        if (_answers[question.questionId] == null && !isRequired) {
          _answers[question.questionId] = DateFormat('yyyy-MM-dd').format(DateTime.now());
        }
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${question.text}${isRequired ? " *" : ""}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            descriptionWidget,
            const SizedBox(height: 8),
            TextFormField(
              controller: TextEditingController(text: _answers[question.questionId]),
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_month),
              ),
              onTap: () => _selectChecklistDate(question),
              validator: (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return 'Vänligen välj ett datum.';
                }
                return null;
              },
            ),
          ],
        );
        break;

      case 'input':
      case 'text':
      case 'text_wysiwyg':
        content = TextFormField(
          decoration: InputDecoration(
            labelText: '${question.text}${isRequired ? " *" : ""}',
            hintText: question.description.isNotEmpty ? question.description : null,
            border: const OutlineInputBorder(),
          ),
          maxLines: question.type.contains('text') ? 3 : 1,
          onChanged: (value) {
            _answers[question.questionId] = value;
          },
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'Detta fält är obligatoriskt.';
            }
            if (question.validate.contains('numeric') && value != null && value.isNotEmpty && double.tryParse(value) == null) {
              return 'Ange ett numeriskt värde.';
            }
            return null;
          },
          keyboardType: question.validate.contains('numeric') ? TextInputType.number : TextInputType.text,
        );
        break;

      case 'table':
        final settingsJson = question.settings.isNotEmpty ? json.decode(question.settings) : {};
        final headers = List<String>.from(settingsJson['header'] ?? []);
        final body = List<List<dynamic>>.from((settingsJson['body'] ?? []).map((row) => List<dynamic>.from(row)));

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.text, style: Theme.of(context).textTheme.titleLarge),
            descriptionWidget,
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: headers.map((header) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                ...body.map((row) {
                  return TableRow(
                    children: row.map((cell) {
                      final subQuestion = _findQuestionById(cell.toString());
                      if (subQuestion != null) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildQuestionWidget(subQuestion, isInTable: true),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(cell.toString()),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ],
        );
        break;

      case 'heading':
        content = const SizedBox.shrink();
        break;

      default:
        content = ListTile(title: Text('Okänd frågetyp: ${question.type} - ${question.text}'));
    }

    if (isInTable) {
      return content;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }
}