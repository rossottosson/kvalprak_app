// lib/screens/clinic_selection_screen.dart
// UPPDATERAD: Använder nu en textinmatning och validerar mot API.

import 'package:flutter/material.dart';
import 'package:kvalprak_app/models/clinic_model.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:kvalprak_app/login_screen.dart';

class ClinicSelectionScreen extends StatefulWidget {
  const ClinicSelectionScreen({super.key});

  @override
  State<ClinicSelectionScreen> createState() => _ClinicSelectionScreenState();
}

class _ClinicSelectionScreenState extends State<ClinicSelectionScreen> {
  final TextEditingController _clinicInputController = TextEditingController();
  final FocusNode _clinicInputFocusNode = FocusNode();
  bool _isLoading = false;
  String? _feedbackMessage;

  // Ändrad logik för att validera mot API
  Future<void> _validateAndProceedToClinic() async {
    final userInput = _clinicInputController.text.trim();
    if (userInput.isEmpty) {
      if (mounted) {
        setState(() {
          _feedbackMessage = "Vänligen ange din kliniks unika webbadress.";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _feedbackMessage = null;
      });
    }

    // Använd den nya valideringsmetoden i UrlService
    Clinic? foundClinic = await UrlService.validateAndGetClinic(userInput);

    if (!mounted) return;

    if (foundClinic != null) {
      await UrlService.setSelectedClinic(foundClinic);
      setState(() {
        _isLoading = false;
        _feedbackMessage = "Klinik '${foundClinic.name}' hittades. Omdirigerar till login...";
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _feedbackMessage = "Kunde inte hitta någon klinik med den adressen. Kontrollera stavningen och försök igen.";
      });
    }
  }

  @override
  void dispose() {
    _clinicInputController.dispose();
    _clinicInputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anslut till din klinik'),
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 30),
              Text(
                'Ange din kliniks unika webbadress-prefix (t.ex. "klinik" för klinik.orna.vardna.se).',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _clinicInputController,
                focusNode: _clinicInputFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Klinikens webbadress',
                  hintText: 't.ex. klinik',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  suffixIcon: _clinicInputController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _clinicInputController.clear(),
                      )
                    : null,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isLoading) _validateAndProceedToClinic();
                },
              ),
              const SizedBox(height: 25),
              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                ))
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Fortsätt'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _validateAndProceedToClinic,
                ),
              const SizedBox(height: 20),
              if (_feedbackMessage != null && _feedbackMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _feedbackMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _feedbackMessage!.startsWith("Kunde inte") ? Colors.redAccent : Colors.green[700],
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}