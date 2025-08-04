// lib/screens/checklist_detail_screen.dart
// UPPDATERAD: Hanterar nu frågetyperna 'checkbox' och 'users' korrekt.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/models/api_checklist_models.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';

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
  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecklistProvider>().fetchQuestions(widget.pageId);
    });
  }

  Future<void> _submitChecklist() async {
    final provider = context.read<ChecklistProvider>();
    
    final Map<String, dynamic> formattedAnswers = {};
    _answers.forEach((questionId, answer) {
      formattedAnswers['form_$questionId'] = answer;
    });

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

    if (headings.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: headings.length,
        itemBuilder: (context, index) {
          final heading = headings[index];
          final subQuestions = questions
              .where((q) => q.parentId == heading.questionId)
              .toList();
          subQuestions.sort((a, b) => a.sort.compareTo(b.sort));

          if (subQuestions.isEmpty) {
            return _buildQuestionWidget(heading);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (heading.type == 'heading')
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
                  child: Text(
                    heading.text,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                )
              else 
                _buildQuestionWidget(heading),

              if (heading.type == 'heading') const Divider(),

              ...subQuestions.map((question) => _buildQuestionWidget(question)),
            ],
          );
        },
      );
    } 
    else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return _buildQuestionWidget(questions[index]);
        },
      );
    }
  }

  Widget _buildQuestionWidget(ApiQuestion question) {
    final descriptionWidget = (question.description.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
            child: Text(
              question.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          )
        : const SizedBox.shrink();

    switch (question.type) {
      case 'radio':
        question.options.sort((a,b) => a.name.compareTo(b.name));
        final isSelected = [
           if (question.options.isNotEmpty)
            _answers[question.questionId] == question.options.first.optionId,
           if (question.options.length > 1)
            _answers[question.questionId] == question.options.last.optionId,
        ];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.text, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                descriptionWidget,
                if (question.options.length >= 2)
                  ToggleButtons(
                    isSelected: isSelected,
                    onPressed: (int index) {
                      setState(() {
                         _answers[question.questionId] = question.options[index].optionId;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 80) / 2, minHeight: 40.0),
                    children: question.options.map((opt) => Text(opt.name)).toList(),
                  ),
              ],
            ),
          ),
        );
      
      // === NY, KOMPLETT LOGIK FÖR USERS (RULLGARDINSMENY) ===
      case 'users':
        final userOptions = question.options;
        final List<DropdownMenuItem<String>> items = userOptions.map((opt) {
          return DropdownMenuItem(
            value: opt.optionId,
            child: Text(opt.name),
          );
        }).toList();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _answers[question.questionId] as String?,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: question.text,
                helperText: question.description.isNotEmpty ? question.description : null,
                border: const OutlineInputBorder(),
              ),
              items: items,
              onChanged: (String? newValue) {
                setState(() {
                  _answers[question.questionId] = newValue;
                });
              },
              validator: (value) {
                // Kan lägga till validering här vid behov
                return null;
              },
            ),
          ),
        );
      
      case 'checkbox':
        final questionOptions = question.options;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.text, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                descriptionWidget,
                ...questionOptions.map((option) {
                  final bool isChecked = (_answers[question.questionId] as List<dynamic>?)?.contains(option.optionId) ?? false;
                  return CheckboxListTile(
                    title: Text(option.name),
                    value: isChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        final currentAnswers = List<dynamic>.from(_answers[question.questionId] ?? []);
                        if (value == true) {
                          if (!currentAnswers.contains(option.optionId)) {
                            currentAnswers.add(option.optionId);
                          }
                        } else {
                          currentAnswers.remove(option.optionId);
                        }
                        _answers[question.questionId] = currentAnswers;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ],
            ),
          ),
        );
        
      case 'date':
        if (_answers[question.questionId] == null) {
          _answers[question.questionId] = DateFormat('yyyy-MM-dd').format(DateTime.now());
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.text, style: Theme.of(context).textTheme.titleMedium),
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
                ),
              ],
            ),
          ),
        );
        
      case 'input':
      case 'text_wysiwyg':
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: question.text,
                hintText: question.description.isNotEmpty ? question.description : null,
                border: const OutlineInputBorder(),
              ),
              maxLines: question.type == 'text_wysiwyg' ? 3 : 1,
              onChanged: (value) {
                _answers[question.questionId] = value;
              },
            ),
          ),
        );

      case 'heading':
      case 'table':
        return const SizedBox.shrink();

      default:
        return Card(
          child: ListTile(title: Text('Okänd frågetyp: ${question.type} - ${question.text}')),
        );
    }
  }
}