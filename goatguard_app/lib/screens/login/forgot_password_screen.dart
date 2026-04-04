import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Recuperación de contraseña con Stepper de 2 pasos [RF-13, RF-16]
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _recoveryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  int _step = 0; // 0: verify code, 1: new password
  bool _isLoading = false;
  String? _resetToken;

  bool get _passwordLongEnough => _passwordController.text.length >= 15;
  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text;

  Future<void> _verifyCode() async {
    final username = _usernameController.text.trim();
    final code = _recoveryController.text.trim();
    if (username.isEmpty || code.isEmpty) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final token = await auth.verifyRecoveryCode(username, code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (token != null) {
      _resetToken = token;
      setState(() => _step = 1);
    } else {
      _showError(auth.error ?? 'Código inválido');
    }
  }

  Future<void> _resetPassword() async {
    if (!_passwordLongEnough || !_passwordsMatch || _resetToken == null) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      _resetToken!,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      _showError(auth.error ?? 'Error al cambiar contraseña');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.critical,
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _recoveryController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _step == 0 ? _buildStep1() : _buildStep2(),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Paso 1: Verificar código de recuperación',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _label('Username'),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'admin',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _label('Código de Recuperación'),
        const SizedBox(height: 8),
        TextField(
          controller: _recoveryController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [_RecoveryCodeFormatter()],
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textPrimary,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
          decoration: const InputDecoration(
            hintText: 'XXXX-XXXX-XXXX-XXXX',
            prefixIcon: Icon(
              Icons.key_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.base),
                    ),
                  )
                : Text(
                    'Verificar código',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.healthy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.healthy,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Código verificado',
                style: GoogleFonts.inter(
                  color: AppColors.healthy,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Paso 2: Nueva contraseña',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _label('Nueva Contraseña'),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Mínimo 15 caracteres',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _passwordLongEnough ? '15+ caracteres' : 'Mínimo 15 caracteres',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _passwordLongEnough
                ? AppColors.healthy
                : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        _label('Confirmar Contraseña'),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmController,
          obscureText: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _resetPassword(),
          decoration: const InputDecoration(
            hintText: 'Repite la contraseña',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ),
        if (_confirmController.text.isNotEmpty && !_passwordsMatch)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Las contraseñas no coinciden',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.critical),
            ),
          ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.base),
                    ),
                  )
                : Text(
                    'Cambiar Contraseña',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Formatter que convierte a mayúsculas e inserta guiones cada 4 caracteres
class _RecoveryCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final stripped = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    if (stripped.length > 16) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < stripped.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(stripped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
