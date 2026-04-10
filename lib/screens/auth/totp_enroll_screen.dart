import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de enrollment TOTP — confirmar primer código tras registro [RF-16].
/// Muestra QR code + input de 6 dígitos. Tras éxito, muestra backup codes.
class TotpEnrollScreen extends StatefulWidget {
  final String totpUri;
  final String qrBase64;

  const TotpEnrollScreen({
    super.key,
    required this.totpUri,
    required this.qrBase64,
  });

  @override
  State<TotpEnrollScreen> createState() => _TotpEnrollScreenState();
}

class _TotpEnrollScreenState extends State<TotpEnrollScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _showBackupCodes = false;

  bool get _isCodeValid => RegExp(r'^\d{6}$').hasMatch(_codeController.text);

  Future<void> _handleConfirm() async {
    if (!_isCodeValid) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    await auth.completeEnrollment(_codeController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (auth.state == AuthState.authenticated && auth.backupCodes != null) {
      setState(() => _showBackupCodes = true);
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

  void _handleContinue() {
    context.read<AuthProvider>().clearBackupCodes();
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showBackupCodes) {
      return _buildBackupCodesView();
    }
    return _buildEnrollView();
  }

  Widget _buildEnrollView() {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Configura tu autenticador',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escanea el código QR con tu app autenticadora '
                '(Google Authenticator, Authy, etc.)',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // QR code image
              if (widget.qrBase64.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.memory(
                      base64Decode(widget.qrBase64),
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // TOTP URI para copiar manualmente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.totpUri,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.brand),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.totpUri));
                        Future.delayed(const Duration(seconds: 30), () {
                          Clipboard.setData(const ClipboardData(text: ''));
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URI copiada')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ingresa el código de 6 dígitos',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
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
                onSubmitted: (_) => _handleConfirm(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _isCodeValid && !_isLoading ? _handleConfirm : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Confirmar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupCodesView() {
    final codes =
        context.read<AuthProvider>().backupCodes ?? [];
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.check_circle, color: AppColors.healthy, size: 64),
              const SizedBox(height: 16),
              Text(
                'TOTP configurado',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Guarda estos códigos de respaldo en un lugar seguro. '
                'Cada código solo se puede usar una vez.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.warning,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: codes.map((code) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        code,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: codes.join('\n')),
                  );
                  Future.delayed(const Duration(seconds: 30), () {
                    Clipboard.setData(const ClipboardData(text: ''));
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Códigos copiados')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar códigos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleContinue,
                child: Text('Continuar',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
