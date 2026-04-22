import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';
import '../../data/models/reporte_mapa_model.dart';

/// Bottom sheet con el detalle de un reporte del mapa.
class ReporteDetailSheet {
  ReporteDetailSheet._();

  static void show(BuildContext context, ReporteMapaModel r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(_iconoTipo(r.tipoHurto), color: _colorTipo(r.tipoHurto), size: 28),
                const SizedBox(width: 10),
                Text(r.tipoHurto[0].toUpperCase() + r.tipoHurto.substring(1),
                    style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              _fila(ctx, Icons.location_on_outlined, r.barrioIngresado),
              _fila(ctx, Icons.calendar_today_outlined, r.fechaIncidente),
              _fila(ctx, Icons.access_time_outlined, r.franjaHoraria),
              if (r.comuna != null) _fila(ctx, Icons.map_outlined, 'Comuna ${r.comuna}'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Widget _fila(BuildContext context, IconData ic, String txt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(ic, size: 16, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub),
        const SizedBox(width: 8),
        Expanded(child: Text(txt, style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain))),
      ]),
    );
  }

  static Color _colorTipo(String tipo) => switch (tipo) {
    'atraco'     => AppColors.hurtoAtraco,
    'raponazo'   => AppColors.hurtoRaponazo,
    'fleteo'     => AppColors.hurtoFleteo,
    'cosquilleo' => AppColors.hurtoCosquilleo,
    _            => AppColors.primary,
  };

  static IconData _iconoTipo(String tipo) => switch (tipo) {
    'atraco'     => Icons.warning_rounded,
    'raponazo'   => Icons.directions_run,
    'fleteo'     => Icons.motorcycle,
    'cosquilleo' => Icons.back_hand_outlined,
    _            => Icons.location_on,
  };
}
