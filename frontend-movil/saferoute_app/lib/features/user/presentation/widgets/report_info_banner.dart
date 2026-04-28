import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// Banner informativo del formulario de reporte (anónimo, seguridad).
class ReportInfoBanner extends StatelessWidget {
  const ReportInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A5F).withValues(alpha: 0.4)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.primaryLight : const Color(0xFFF59E0B),
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20,
              color: isDark ? AppColors.primaryLight : const Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu reporte es completamente anónimo. La información que compartes '
              'nos ayuda a identificar zonas de riesgo y mejorar la seguridad en la ciudad.\n'
              'Cada reporte cuenta y puede ayudar a prevenir que otras personas pasen por lo mismo.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
