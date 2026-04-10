class LoginResult {
  final String token;
  final bool totpRequired;
  final bool needsEnrollment;

  const LoginResult({
    required this.token,
    required this.totpRequired,
    required this.needsEnrollment,
  });
}

class TotpResult {
  final String token;
  final List<String>? backupCodes;

  const TotpResult({
    required this.token,
    this.backupCodes,
  });
}
