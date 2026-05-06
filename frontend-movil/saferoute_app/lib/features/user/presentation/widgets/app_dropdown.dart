import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// Dropdown genérico reutilizable con estilo CIVICTRACKIO.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.display,
    this.required = true,
  });

  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String Function(T)? display;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final subColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;

    return DropdownButtonFormField<T>(
      value: value,
      menuMaxHeight: 260,
      borderRadius: BorderRadius.circular(14),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: subColor),
        prefixIcon: const Icon(Icons.list_alt_rounded, color: AppColors.primary),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: textColor),
      items: items.map((e) {
        final texto = display != null ? display!(e) : e.toString();
        return DropdownMenuItem(
          value: e,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(texto,
                style: GoogleFonts.inter(fontSize: 14, color: textColor)),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Campo obligatorio' : null : null,
    );
  }
}
