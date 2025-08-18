// lib/models/login_result.dart

// Definierar de möjliga utfallen av ett inloggningsförsök.
enum LoginResultStatus {
  success,
  failure,
  twoFactorRequired,
}

// Ett objekt som håller resultatet av ett inloggningsförsök.
class LoginResult {
  final LoginResultStatus status;
  final String? errorMessage;

  LoginResult({required this.status, this.errorMessage});
}