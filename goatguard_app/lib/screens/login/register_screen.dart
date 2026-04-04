import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de registro con invitation token [RF-13, RF-16]
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _tokenController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text;

  bool get _passwordLongEnough => _passwordController.text.length >= 15;

  Future<void> _handleRegister() async {
    final token = _tokenController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (token.isEmpty || username.isEmpty || password.isEmpty) return;

    if (!_passwordLongEnough) {
      _showError('La contraseña debe tener al menos 15 caracteres');
      return;
    }
    if (!_passwordsMatch) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.register(username, password, token);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final recoveryCode = auth.pendingRecoveryCode;
      if (recoveryCode != null) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/recovery-code', arguments: recoveryCode);
      }
    } else {
      _showError(auth.error ?? 'Error en el registro');
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
    _tokenController.dispose();
    _usernameController.dispose();
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
          'Primera configuración',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _label('Invitation Token'),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: 'Pega aquí el token del servidor',
                  prefixIcon: Icon(
                    Icons.vpn_key_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label('Username'),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
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
              _label('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Mínimo 15 caracteres',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
              _label('Confirmar Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                obscureText: true,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleRegister(),
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.critical,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.base,
                            ),
                          ),
                        )
                      : Text(
                          'Registrar Administrador',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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
