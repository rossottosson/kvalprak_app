// lib/login_screen.dart
// SLUTGILTIG VERSION: "Glömt lösenord?" länkar nu till den exakta /recover-sökvägen.

import 'package:flutter/material.dart';
import 'package:kvalprak_app/services/auth_service.dart';
import 'package:kvalprak_app/action_select_screen.dart';
import 'package:kvalprak_app/screens/clinic_selection_screen.dart';
import 'package:kvalprak_app/services/url_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Metod för att öppna länken för glömt lösenord
  Future<void> _launchForgotPasswordURL() async {
    final apiHost = await UrlService.getApiHost();
    
    // KORRIGERAD SÖKVÄG enligt din senaste instruktion
    final url = Uri.parse('https://$apiHost/login/recover');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunde inte öppna länken: $url')),
        );
      }
    }
  }

  Future<void> _goBackToClinicSelection() async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Byta klinik?'),
        content: const Text('Är du säker på att du vill gå tillbaka och välja en annan klinik?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ja, byt klinik'),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      if (!mounted) return;
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
      
      await _authService.clearSelectedClinic();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ClinicSelectionScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _authService.getSavedEmail();
    final savedPassword = await _authService.getSavedPassword();

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _performLogin() async {
    setState(() => _isLoading = true);

    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActionSelectScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inloggningen misslyckades. Kontrollera dina uppgifter.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            Image.asset(
              'assets/images/logo.png',
              height: 100,
            ),
            const SizedBox(height: 24),
            
            FutureBuilder<String?>(
              future: UrlService.getSelectedClinicName(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
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
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Lösenord'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _launchForgotPasswordURL,
                child: const Text('Glömt lösenord?'),
              ),
            ),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text("Kom ihåg mig"),
              value: _rememberMe,
              onChanged: (newValue) {
                setState(() {
                  _rememberMe = newValue ?? false;
                });
              },
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
                    child: const Text('Logga in'),
                  ),
          ],
        ),
      ),
    );
  }
}