// lib/screens/create_checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/checklist_provider.dart';
import 'package:kvalprak_app/models/checklist.dart';
import 'package:kvalprak_app/models/checklist_item.dart';

class CreateChecklistScreen extends StatefulWidget {
  const CreateChecklistScreen({super.key});

  @override
  State<CreateChecklistScreen> createState() => _CreateChecklistScreenState();
}

class _CreateChecklistScreenState extends State<CreateChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  // --- Focus Node Management ---
  final _titleFocusNode = FocusNode(); // Focus node for the title
  // Lists to hold controllers and focus nodes for each item text field
  final List<TextEditingController> _itemControllers = [];
  final List<FocusNode> _itemFocusNodes = [];
  // --- End Focus Node Management ---

  @override
  void initState() {
    super.initState();
    // Start with one empty item field when the screen loads
    _addItemField(requestFocus: false); // Don't request focus initially
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    for (var focusNode in _itemFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Adds a new item field and its focus node
  void _addItemField({bool requestFocus = true}) {
    setState(() {
      final newController = TextEditingController();
      final newFocusNode = FocusNode();
      _itemControllers.add(newController);
      _itemFocusNodes.add(newFocusNode);

      // Request focus for the new field slightly after build, if requested
      if (requestFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if(newFocusNode.canRequestFocus) { // Check if node is still valid
             newFocusNode.requestFocus();
           }
        });
      }
    });
  }

  // Removes an item field and its focus node
  void _removeItemField(int index) {
    if (_itemControllers.length > 1) {
       setState(() {
         // Dispose before removing
         _itemFocusNodes[index].dispose();
         _itemControllers[index].dispose();
         // Remove from lists
         _itemFocusNodes.removeAt(index);
         _itemControllers.removeAt(index);
       });
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En checklista måste ha minst ett objekt.'), duration: Duration(seconds: 2)),
       );
    }
  }

  // Handles submission from an item field
  void _onItemSubmitted(int index) {
     // If submitted from the *last* item field, add a new one
     if (index == _itemControllers.length - 1) {
        _addItemField(); // Adds new field and requests focus for it
     } else {
        // If not the last item, move focus to the next item field
        _itemFocusNodes[index + 1].requestFocus();
     }
  }

  // Saves the checklist
  void _saveChecklist() {
    // Unfocus any text field to ensure latest value is captured (and hide keyboard)
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text.trim();
      final List<ChecklistItem> items = _itemControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .map((text) => ChecklistItem.newItem(text: text))
          .toList();

      if (items.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lägg till minst ett giltigt objekt i checklistan.'), duration: Duration(seconds: 2)),
         );
         return;
      }

      final newChecklist = Checklist.newChecklist(title: title, items: items);
      // Use context.read in callbacks/event handlers
      context.read<ChecklistProvider>().addChecklist(newChecklist);
      Navigator.pop(context); // Go back after saving
    } else {
       // Show message if validation fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Var god fyll i titel och minst ett objekt.'), duration: Duration(seconds: 2)),
         );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skapa Ny Checklista'),
        // --- Removed Save Icon Button ---
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.save),
        //     tooltip: 'Spara Checklista',
        //     onPressed: _saveChecklist,
        //   ),
        // ],
      ),
      // Use GestureDetector to unfocus text fields when tapping outside
      body: GestureDetector(
         onTap: () => FocusScope.of(context).unfocus(),
         child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrolling
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Title Field ---
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocusNode, // Assign focus node
                decoration: const InputDecoration(
                  labelText: 'Titel på Checklista',
                  border: OutlineInputBorder(),
                  hintText: 't.ex. Städa Lägenheten',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ange en titel';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next, // Move to first item on submit
                onFieldSubmitted: (_) { // Move focus to the first item field
                    if(_itemFocusNodes.isNotEmpty) {
                       _itemFocusNodes.first.requestFocus();
                    }
                 },
              ),
              const SizedBox(height: 20),

               // --- Items Section Header ---
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Objekt', style: Theme.of(context).textTheme.titleLarge),
                    // Add Item Button (still useful for manual adding)
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                      tooltip: 'Lägg till objekt',
                      onPressed: _addItemField, // Manually add field
                    ),
                  ],
               ),
               const Divider(),

              // --- Item Fields ---
              // Generate fields based on controllers list
              if (_itemControllers.isNotEmpty)
               ...List.generate(_itemControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemControllers[index],
                            focusNode: _itemFocusNodes[index], // Assign focus node
                            decoration: InputDecoration(
                              labelText: 'Objekt ${index + 1}',
                              border: const OutlineInputBorder(),
                              hintText: 't.ex. Dammsug golvet',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            // Set action button to 'next' or 'done'
                            textInputAction: TextInputAction.done, // Or TextInputAction.next
                            // --- Call submission handler ---
                            onFieldSubmitted: (_) => _onItemSubmitted(index),
                          ),
                        ),
                        // Remove button for items
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          tooltip: 'Ta bort objekt',
                          // Disable removing if only one item exists
                          onPressed: _itemControllers.length > 1
                              ? () => _removeItemField(index)
                              : null, // Disable button if only one item
                           visualDensity: VisualDensity.compact, // Make button less tall
                        ),
                      ],
                    ),
                  );
               }),
              if (_itemControllers.isEmpty) // Should not happen with current logic but good fallback
                 const Padding(
                   padding: EdgeInsets.only(top: 16.0),
                   child: Text('Lägg till objekt med plus-knappen ovan.'),
                 ),

              const SizedBox(height: 40), // Spacing before save button

              // --- Large Save Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Spara Checklista'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16), // Make button taller
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary, // Ensure text color contrast
                      ),
                  minimumSize: const Size(double.infinity, 50), // Make button wide and reasonably tall
                ),
                onPressed: _saveChecklist,
              ),
              const SizedBox(height: 20), // Extra padding at bottom
            ],
          ),
             ),
       ),
    );
  }
}