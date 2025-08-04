// lib/login_screen.dart
// UPPDATERAD MED ETT KOMPLETT 2FA/OTP-FLÖDE

import 'package:flutter/material.dart';
import 'package:kvalprak_app/models/login_result.dart'; // Importera
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/action_select_screen.dart';
import 'package:kvalprak_app/screens/clinic_selection_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kvalprak_app/services/url_service.dart'; // <-- DEN SAKNADE RADEN

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController(); // NYTT: Controller för OTP-fältet
  final _authService = AuthService();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isTwoFactorStep = false; // NYTT: Styr om OTP-fältet ska visas

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _performLogin() async {
    setState(() => _isLoading = true);

    // Hämta OTP-koden om vi är i 2FA-steget
    final otp = _isTwoFactorStep ? _otpController.text.trim() : null;

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      otp: otp, // Skicka med OTP om den finns
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Hantera de olika resultaten från inloggningsförsöket
    switch (result.status) {
      case LoginResultStatus.success:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ActionSelectScreen()),
        );
        break;
      case LoginResultStatus.twoFactorRequired:
        // Visa OTP-fältet och ett meddelande till användaren
        setState(() => _isTwoFactorStep = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tvåfaktorsautentisering krävs. Ange koden från din app.')),
        );
        break;
      case LoginResultStatus.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Okänt fel vid inloggning.')),
        );
        break;
    }
  }
  
  // ... resten av filen (dispose, build etc) är uppdaterad nedan ...
  Future<void> _loadSavedCredentials() async { /* ... oförändrad ... */ }
  Future<void> _launchForgotPasswordURL() async { /* ... oförändrad ... */ }
  Future<void> _goBackToClinicSelection() async { /* ... oförändrad ... */ }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose(); // Glöm inte att städa upp den nya controllern
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // I lib/login_screen.dart
appBar: AppBar(
  title: const Text('Logga in'),
  // Nu behövs ingen egen 'leading'-knapp, Flutter lägger till en automatiskt.
  // Om du vill ha kvar den för en egen tooltip kan du göra såhär:
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: 'Välj en annan klinik',
    onPressed: () => Navigator.of(context).pop(), // Använder enkel pop()
  ),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/images/logo.png', height: 100),
            const SizedBox(height: 24),
            FutureBuilder<String?>(
              future: UrlService.getSelectedClinicName(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    "Du loggar in på: ${snapshot.data}",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            // E-post och lösenordsfält är nu låsta under 2FA-steget
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-post'),
              keyboardType: TextInputType.emailAddress,
              readOnly: _isTwoFactorStep, // Lås fältet
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Lösenord'),
              obscureText: true,
              readOnly: _isTwoFactorStep, // Lås fältet
            ),
            
            // NYTT: OTP-fältet, visas bara när det behövs
            if (_isTwoFactorStep)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: '6-siffrig kod (OTP)'),
                  keyboardType: TextInputType.number,
                  autofocus: true, // Fokusera på detta fält automatiskt
                ),
              ),

            // "Glömt lösenord?" visas inte under 2FA-steget
            if (!_isTwoFactorStep)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _launchForgotPasswordURL,
                  child: const Text('Glömt lösenord?'),
                ),
              ),

            // "Kom ihåg mig" visas inte under 2FA-steget
            if (!_isTwoFactorStep)
              CheckboxListTile(
                title: const Text("Kom ihåg mig"),
                value: _rememberMe,
                onChanged: (newValue) => setState(() => _rememberMe = newValue ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _performLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18)
                    ),
                    // Ändra text på knappen beroende på steg
                    child: Text(_isTwoFactorStep ? 'Verifiera kod' : 'Logga in'),
                  ),
          ],
        ),
      ),
    );
  }
}