// lib/screens/clinic_selection_screen.dart
// UPPDATERAD FÖR ALTERNATIV A (EXAKT MATCH, INGEN LISTA)
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
  String? _feedbackMessage; // För att visa meddelanden till användaren

  Future<void> _findAndProceedToClinic() async {
    final userInput = _clinicInputController.text.trim();
    if (userInput.isEmpty) {
      if (mounted) { 
        setState(() {
          _feedbackMessage = "Vänligen ange din kliniks namn eller ID.";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _feedbackMessage = null; // Rensa tidigare meddelanden
      });
    }

    // Använd den nya metoden i UrlService
    Clinic? foundClinic = await UrlService.findClinicByUserInput(userInput);

    if (!mounted) return; // Kolla igen om widgeten fortfarande är aktiv

    if (foundClinic != null) {
      await UrlService.setSelectedClinic(foundClinic);
      setState(() {
        _isLoading = false;
        _feedbackMessage = "Klinik '${foundClinic.name}' vald. Omdirigerar till login...";
      });
      // En liten fördröjning för att visa meddelandet innan navigering
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _feedbackMessage = "Kunde inte hitta kliniken. Kontrollera stavningen och försök igen, eller kontakta support.";
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
        onTap: () => FocusScope.of(context).unfocus(), // Dölj tangentbord vid tryck utanför
        child: SingleChildScrollView( // För att undvika overflow om tangentbordet visas
          padding: const EdgeInsets.all(24.0), // Ökat padding lite
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                height: 120, // Justerad höjd
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("Error loading logo in ClinicSelectionScreen: $error");
                  return const SizedBox(
                      height: 120,
                      child: Center(child: Icon(Icons.business_rounded, size: 60, color: Colors.grey)));
                },
              ),
              const SizedBox(height: 30),
              Text(
                'Ange din kliniks namn eller unika webbadress-prefix (t.ex. "min Klinik" eller "minklinik" för minklinik.kiv.kvalprak.se).',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _clinicInputController,
                focusNode: _clinicInputFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Kliniknamn eller ID',
                  hintText: 't.ex. Solrosen Vårdcentral eller solrosen',
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
                  if (!_isLoading) _findAndProceedToClinic();
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
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary // Säkerställ textfärg
                    ),
                  ),
                  onPressed: _findAndProceedToClinic,
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