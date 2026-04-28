import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// Lista de sugerencias reutilizable (dirección, barrio, etc.).
class SuggestionList extends StatelessWidget {
  const SuggestionList({
    super.key,
    required this.items,
    required this.onSelect,
  });

  final List<String> items;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF475569) : AppColors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((s) => InkWell(
          onTap: () => onSelect(s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Icon(Icons.place_outlined, size: 16,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub),
              const SizedBox(width: 8),
              Expanded(child: Text(s,
                  style: GoogleFonts.inter(fontSize: 13,
                      color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain))),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}
