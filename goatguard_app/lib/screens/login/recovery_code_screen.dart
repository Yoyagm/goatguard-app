import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Muestra el recovery code UNA SOLA VEZ después del registro [RF-13]
class RecoveryCodeScreen extends StatefulWidget {
  final String recoveryCode;

  const RecoveryCodeScreen({super.key, required this.recoveryCode});

  @override
  State<RecoveryCodeScreen> createState() => _RecoveryCodeScreenState();
}

class _RecoveryCodeScreenState extends State<RecoveryCodeScreen> {
  bool _copied = false;
  bool _confirmed = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.recoveryCode));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.healthy,
        content: Text(
          'Código copiado al portapapeles',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }

  void _continue() {
    final auth = context.read<AuthProvider>();

    // Leer datos ANTES de limpiar
    final totpUri = auth.pendingTotpUri ?? '';
    final qrBase64 = auth.pendingQrBase64 ?? '';
    auth.clearPendingTotpData();

    Navigator.of(context).pushReplacementNamed(
      '/totp-enrollment',
      arguments: {'totp_uri': totpUri, 'qr_png_base64': qrBase64},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.base,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.key_rounded,
                  color: AppColors.warning,
                  size: 48,
                ),
                const SizedBox(height: 20),
                Text(
                  'Código de Recuperación',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este código te permite recuperar tu cuenta si pierdes acceso a la app de autenticación. Solo se muestra UNA VEZ.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      SelectableText(
                        widget.recoveryCode,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _copyCode,
                        icon: Icon(
                          _copied ? Icons.check : Icons.copy_rounded,
                          size: 18,
                          color: AppColors.brand,
                        ),
                        label: Text(
                          _copied ? 'Copiado' : 'Copiar código',
                          style: GoogleFonts.inter(color: AppColors.brand),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Checkbox(
                      value: _confirmed,
                      onChanged: (v) => setState(() => _confirmed = v ?? false),
                      activeColor: AppColors.brand,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _confirmed = !_confirmed),
                        child: Text(
                          'He guardado este código en un lugar seguro',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _confirmed ? _continue : null,
                    child: Text(
                      'Continuar con setup TOTP',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
