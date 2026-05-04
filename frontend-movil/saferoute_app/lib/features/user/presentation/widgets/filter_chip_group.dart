import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// Componente reutilizable de selección múltiple tipo "toggle pill".
/// Unifica la UI de comunas, franjas horarias y tipos de hurto
/// con el mismo comportamiento visual y de interacción.
class FilterChipGroup<T> extends StatelessWidget {
  /// Lista de opciones disponibles.
  final List<T> items;

  /// Set de opciones actualmente seleccionadas.
  final Set<T> selected;

  /// Callback al seleccionar/deseleccionar un item.
  final void Function(T item) onToggle;

  /// Texto a mostrar para cada item.
  final String Function(T item) labelBuilder;

  /// Color de acento cuando el item está seleccionado.
  /// Si es null, usa AppColors.primary.
  final Color Function(T item)? activeColorBuilder;

  /// Ícono opcional a la izquierda del label.
  final IconData Function(T item)? iconBuilder;

  /// Si true, usa layout de grid (para comunas). Si false, usa Wrap (para chips).
  final bool useGrid;

  /// Columnas del grid (solo aplica si useGrid = true).
  final int gridColumns;

  /// Aspect ratio de los items del grid (default: 1.4 para comunas compactas).
  final double gridAspectRatio;

  const FilterChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.labelBuilder,
    this.activeColorBuilder,
    this.iconBuilder,
    this.useGrid = false,
    this.gridColumns = 4,
    this.gridAspectRatio = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    if (useGrid) return _buildGrid(context);
    return _buildWrap(context);
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: gridColumns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: gridAspectRatio,
      children: items.map((item) => _buildChip(context, item)).toList(),
    );
  }

  Widget _buildWrap(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _buildChip(context, item)).toList(),
    );
  }

  Widget _buildChip(BuildContext context, T item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selected.contains(item);
    final accentColor = activeColorBuilder?.call(item) ?? AppColors.filterActive;

    final defaultBg = isDark ? const Color(0xFF334155) : Colors.white;
    final defaultBorder = isDark ? const Color(0xFF475569) : AppColors.border;
    final defaultText = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;

    final bg = isSelected ? accentColor : defaultBg;
    final border = isSelected ? accentColor : defaultBorder;
    final textColor = isSelected ? Colors.white : defaultText;

    final icon = iconBuilder?.call(item);
    final label = labelBuilder(item);

    return GestureDetector(
      onTap: () => onToggle(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: useGrid ? 4 : 14,
          vertical: useGrid ? 0 : 10,
        ),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: useGrid ? Alignment.center : null,
        child: Row(
          mainAxisSize: useGrid ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              useGrid ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: textColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: useGrid ? 13 : 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
