import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de enrollment TOTP — escanear QR + verificar primer código [RF-13]
class TotpEnrollmentScreen extends StatefulWidget {
  final String totpUri;
  final String qrPngBase64;

  const TotpEnrollmentScreen({
    super.key,
    required this.totpUri,
    required this.qrPngBase64,
  });

  @override
  State<TotpEnrollmentScreen> createState() => _TotpEnrollmentScreenState();
}

class _TotpEnrollmentScreenState extends State<TotpEnrollmentScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _showManualKey = false;

  /// Extrae el secreto del URI otpauth://totp/GOATGuard:user?secret=XXXX&...
  String get _manualSecret {
    final uri = Uri.tryParse(widget.totpUri);
    return uri?.queryParameters['secret'] ?? '';
  }

  Future<void> _verifyAndEnroll() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final backupCodes = await auth.enrollTotp(code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (backupCodes != null) {
      Navigator.of(
        context,
      ).pushReplacementNamed('/backup-codes', arguments: backupCodes);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.critical,
          content: Text(
            auth.error ?? 'Código inválido',
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.base,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'Configurar Autenticación',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Abre Google Authenticator o Microsoft Authenticator y escanea este código QR',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.totpUri.isNotEmpty
                      ? QrImageView(
                          data: widget.totpUri,
                          version: QrVersions.auto,
                          size: 240,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        )
                      : widget.qrPngBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(widget.qrPngBase64),
                          width: 240,
                          height: 240,
                        )
                      : const SizedBox(
                          width: 240,
                          height: 240,
                          child: Center(child: Text('QR no disponible')),
                        ),
                ),

                const SizedBox(height: 16),

                // Entrada manual como fallback
                TextButton(
                  onPressed: () =>
                      setState(() => _showManualKey = !_showManualKey),
                  child: Text(
                    _showManualKey
                        ? 'Ocultar clave manual'
                        : '¿No puedes escanear? Ingresa la clave manualmente',
                    style: GoogleFonts.inter(
                      color: AppColors.brand,
                      fontSize: 13,
                    ),
                  ),
                ),

                if (_showManualKey) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF30363D),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _manualSecret,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: AppColors.brand,
                            size: 20,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _manualSecret),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.healthy,
                                content: Text(
                                  'Clave copiada',
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                Text(
                  'Ingresa el código de 6 dígitos que muestra la app',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                // Campo de verificación
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '000000',
                  ),
                  onChanged: (value) {
                    if (value.length == 6) _verifyAndEnroll();
                  },
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndEnroll,
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
                            'Verificar y Activar',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
