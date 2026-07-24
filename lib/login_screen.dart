// lib/login_screen.dart

import 'package:flutter/material.dart';
import 'package:kvalprak_app/models/login_result.dart';
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/action_select_screen.dart';
import 'package:kvalprak_app/screens/clinic_selection_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isTwoFactorStep = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }
  
  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _authService.getSavedEmail();
    final savedPassword = await _authService.getSavedPassword();

    if (savedEmail != null && savedPassword != null) {
      if (!mounted) return;
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      _rememberMe = true;
      setState(() {});
    }
  }

  Future<void> _performLogin() async {
    setState(() => _isLoading = true);
    final otp = _isTwoFactorStep ? _otpController.text.trim() : null;
    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      otp: otp,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result.status) {
      case LoginResultStatus.success:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ActionSelectScreen()),
        );
        break;
      case LoginResultStatus.twoFactorRequired:
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
  
  // ===================================
  // === HÄR ÄR ÄNDRINGEN ===
  // ===================================
  Future<void> _launchForgotPasswordURL() async {
    final host = await UrlService.getWebHost();
    // Byt ut '/login/forgot' mot '/login/recover'
    final forgotPasswordUrl = Uri.parse('https://$host/login/recover');
    
    if (await canLaunchUrl(forgotPasswordUrl)) {
      await launchUrl(forgotPasswordUrl, mode: LaunchMode.externalApplication);
    } else {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Kunde inte öppna länken.')),
            );
        }
    }
  }

  final LocalAuthentication _localAuth = LocalAuthentication();

Future<void> _loginWithBiometrics() async {
    try {
      // 1. Kolla om telefonen har Face ID/Touch ID aktiverat överhuvudtaget
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canAuthenticateWithBiometrics || !isDeviceSupported) return;

      // 2. Poppa upp Face ID-rutan på skärmen
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Skanna ditt ansikte för att logga in snabbt',
        options: const AuthenticationOptions(
          stickyAuth: true, // Håller rutan vaken om användaren tittar bort en sekund
          biometricOnly: true, // Tillåter inte pinkod som fallback, endast biometri
        ),
      );

      if (didAuthenticate) {
        setState(() => _isLoading = true);
        
        // 3. Om Face ID lyckades, försök förnya sessionen via vårt API
        final String? newToken = await _authService.trySilentRefreshToken();
        
        setState(() => _isLoading = false);

        // HÄR ÄR FIXEN: Vi kollar newToken istället för refreshSuccess
        if (newToken != null) {
          // Succé! Släpp in användaren direkt utan 2FA-kod eller lösenord
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ActionSelectScreen()),
          );
        } else {
          // Om refresh_token gått ut efter 30 dagar, visa ett meddelande
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sessionen har gått ut. Vänligen logga in med lösenord.')),
          );
        }
      }
    } catch (e) {
      print("Biometrisk inloggning misslyckades: $e");
    }
  }

  Future<void> _goBackToClinicSelection() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ClinicSelectionScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logga in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Välj en annan klinik',
          onPressed: _goBackToClinicSelection,
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

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-post'),
              keyboardType: TextInputType.emailAddress,
              readOnly: _isTwoFactorStep,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Lösenord'),
              obscureText: true,
              readOnly: _isTwoFactorStep,
            ),

            const SizedBox(height: 16),
            if (_rememberMe && !_isTwoFactorStep && !_isLoading)
              TextButton.icon(
                onPressed: _loginWithBiometrics,
                icon: const Icon(Icons.face, size: 32),
                label: const Text('Logga in med Face ID / Touch ID'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            
            if (_isTwoFactorStep)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: '6-siffrig kod (OTP)'),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
              ),

            if (!_isTwoFactorStep)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _launchForgotPasswordURL,
                  child: const Text('Glömt lösenord?'),
                ),
              ),

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
                    child: Text(_isTwoFactorStep ? 'Verifiera kod' : 'Logga in'),
                  ),
          ],
        ),
      ),
    );
  }
}