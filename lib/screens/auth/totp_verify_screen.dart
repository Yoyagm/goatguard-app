import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de verificación TOTP — paso 2 del login [RF-16].
/// Input de 6 dígitos numéricos + botón verificar.
class TotpVerifyScreen extends StatefulWidget {
  const TotpVerifyScreen({super.key});

  @override
  State<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends State<TotpVerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  bool get _isCodeValid => RegExp(r'^\d{6}$').hasMatch(_codeController.text);

  Future<void> _handleVerify() async {
    if (!_isCodeValid) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();

    // Llamar al método correcto según el estado actual
    if (auth.state == AuthState.pendingEnrollment) {
      await auth.completeEnrollment(_codeController.text);
    } else {
      await auth.completeTotp(_codeController.text);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (auth.state == AuthState.authenticated) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.critical,
          content: Text(
            auth.error!,
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
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
                    Icons.lock_clock_rounded,
                    color: AppColors.brand,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Verificación TOTP',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código de 6 dígitos de tu aplicación autenticadora',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '000000',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleVerify(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isCodeValid && !_isLoading ? _handleVerify : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Verificar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
