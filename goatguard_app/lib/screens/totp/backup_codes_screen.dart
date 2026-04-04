import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Muestra los 10 backup codes UNA SOLA VEZ después del enrollment [RF-13]
class BackupCodesScreen extends StatefulWidget {
  final List<String> backupCodes;

  const BackupCodesScreen({super.key, required this.backupCodes});

  @override
  State<BackupCodesScreen> createState() => _BackupCodesScreenState();
}

class _BackupCodesScreenState extends State<BackupCodesScreen> {
  bool _confirmed = false;

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: widget.backupCodes.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.healthy,
        content: Text(
          '10 códigos copiados al portapapeles',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }

  void _goToDashboard() {
    context.read<AuthProvider>().clearBackupCodes();
    Navigator.of(context).pushReplacementNamed('/main');
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
                const Icon(
                  Icons.shield_rounded,
                  color: AppColors.healthy,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Códigos de Respaldo',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guarda estos códigos en un lugar seguro. Cada uno solo puede usarse una vez. Solo se muestran AHORA.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Grid 2 columnas x 5 filas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: widget.backupCodes.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          widget.backupCodes[index],
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _copyAll,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.brand,
                  ),
                  label: Text(
                    'Copiar todos',
                    style: GoogleFonts.inter(color: AppColors.brand),
                  ),
                ),

                const SizedBox(height: 20),
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
                          'He guardado estos códigos en un lugar seguro',
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
                    onPressed: _confirmed ? _goToDashboard : null,
                    child: Text(
                      'Ir al Dashboard',
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
