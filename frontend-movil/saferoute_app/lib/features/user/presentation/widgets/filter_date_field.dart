import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// Campo de fecha para filtros con label externo arriba y ícono de calendario.
/// No permite escritura manual, solo selección vía DatePicker.
class FilterDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime) onPicked;

  const FilterDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null;

    final bg = isDark ? const Color(0xFF334155) : Colors.white;
    final borderColor = hasValue
        ? AppColors.primary
        : (isDark ? const Color(0xFF475569) : AppColors.border);
    final labelColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    final valueColor = hasValue
        ? (isDark ? const Color(0xFFE2E8F0) : AppColors.textMain)
        : labelColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(2020),
              lastDate: lastDate ?? DateTime.now(),
            );
            if (picked != null) onPicked(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor, width: hasValue ? 1.5 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue
                        ? '${value!.day.toString().padLeft(2, '0')}/'
                            '${value!.month.toString().padLeft(2, '0')}/'
                            '${value!.year}'
                        : 'dd/mm/aaaa',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                      color: valueColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: hasValue ? AppColors.primary : labelColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
