import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// Leyenda del mapa: marcadores por tipo de hurto o gradiente de calor.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key, required this.modoCalor});

  final bool modoCalor;

  @override
  Widget build(BuildContext context) {
    return modoCalor ? _leyendaCalor(context) : _leyendaMarcadores(context);
  }

  Widget _leyendaMarcadores(BuildContext context) {
    const items = [
      ('Atraco',     AppColors.hurtoAtraco),
      ('Raponazo',   AppColors.hurtoRaponazo),
      ('Fleteo',     AppColors.hurtoFleteo),
      ('Cosquilleo', AppColors.hurtoCosquilleo),
    ];
    return _contenedor(context,
      children: items.map((e) => _fila(context, e.$2, e.$1)).toList(),
    );
  }

  Widget _leyendaCalor(BuildContext context) {
    return _contenedor(context, children: [
      _fila(context, const Color(0xFF22C55E), 'Zona segura'),
      _fila(context, const Color(0xFFFACC15), 'Bajo riesgo'),
      _fila(context, const Color(0xFFF97316), 'Riesgo medio'),
      _fila(context, const Color(0xFFBE185D), 'Alto riesgo'),
    ]);
  }

  Widget _contenedor(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.93)
            : Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children),
    );
  }

  Widget _fila(BuildContext context, Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white : AppColors.textMain)),
      ]),
    );
  }
}
