import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/failure.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de registro con invitation token [RF-16].
/// 3 campos: username, password, invitation token.
/// Tras registro exitoso, muestra recovery code y navega a enrollment.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _invitationController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBootstrap = false;
  // Datos de enrollment mostrados tras registro exitoso
  Map<String, dynamic>? _enrollmentData;

  bool get _isFormValid =>
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      (_isBootstrap || _invitationController.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _checkBootstrap();
  }

  Future<void> _checkBootstrap() async {
    final result = await context.read<AuthProvider>().checkBootstrapStatus();
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _isBootstrap = data['needs_bootstrap'] == true;
        });
      case Err():
        // Si falla el check, asumir modo normal (requiere invitation)
        break;
    }
  }

  Future<void> _handleRegister() async {
    if (!_isFormValid) return;
    setState(() {
      _isLoading = true;
      _enrollmentData = null;
    });

    final token = _isBootstrap ? null : _invitationController.text.trim();
    final result = await context.read<AuthProvider>().register(
      _usernameController.text.trim(),
      _passwordController.text,
      invitationToken: token,
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        // Limpiar password del controller lo antes posible
        _passwordController.clear();
        setState(() {
          _isLoading = false;
          _enrollmentData = data;
        });
      case Err(:final failure):
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.critical,
            content: Text(
              failure.message,
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
    }
  }

  void _handleContinueToEnroll() {
    if (_enrollmentData == null) return;
    final args = {
      'totp_uri': _enrollmentData!['totp_uri'],
      'qr_base64': _enrollmentData!['qr_png_base64'],
    };
    setState(() => _enrollmentData = null);
    Navigator.of(context).pushReplacementNamed('/totp-enroll', arguments: args);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _invitationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_enrollmentData != null) {
      return _buildRecoveryCodeView();
    }
    return _buildRegisterForm();
  }

  Widget _buildRegisterForm() {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.brand.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: AppColors.brand,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Registro',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isBootstrap
                    ? 'Crea la cuenta de administrador inicial'
                    : 'Necesitas un token de invitación para registrarte',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Username
              TextField(
                controller: _usernameController,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Usuario',
                  prefixIcon: Icon(Icons.person, color: AppColors.textTertiary),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contraseña (mín. 15 caracteres)',
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: AppColors.textTertiary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (!_isBootstrap) ...[
                const SizedBox(height: 16),
                // Invitation token — solo visible si ya hay usuarios
                TextField(
                  controller: _invitationController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Token de invitación',
                    prefixIcon: Icon(
                      Icons.vpn_key,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isFormValid && !_isLoading ? _handleRegister : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Registrarse',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Ya tengo cuenta',
                  style: GoogleFonts.inter(color: AppColors.brand),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryCodeView() {
    final recoveryCode = _enrollmentData!['recovery_code'] as String? ?? '';
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.check_circle,
                color: AppColors.healthy,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Cuenta creada',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Guarda este código de recuperación. '
                'Lo necesitarás si pierdes acceso a tu autenticador.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.warning,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: SelectableText(
                  recoveryCode,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: recoveryCode));
                  Future.delayed(const Duration(seconds: 30), () async {
                    final current = await Clipboard.getData(
                      Clipboard.kTextPlain,
                    );
                    if (current?.text == recoveryCode) {
                      Clipboard.setData(const ClipboardData(text: ''));
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleContinueToEnroll,
                child: Text(
                  'Continuar con TOTP',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
