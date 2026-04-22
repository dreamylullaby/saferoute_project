import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme.dart';
import '../../data/datasources/estadisticas_datasource.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  final _ds = EstadisticasDatasource();

  String _agruparPor = 'mes';
  List<Map<String, dynamic>> _periodos  = [];
  Map<String, dynamic>?      _comparacion;
  bool _cargando = true;

  // Rango por defecto: últimos 6 meses
  late String _fechaDesde;
  late String _fechaHasta;

  // Comparación: mes actual vs mes anterior
  late String _p1Desde, _p1Hasta, _p2Desde, _p2Hasta;

  @override
  void initState() {
    super.initState();
    final hoy    = DateTime.now();
    final hace6m = DateTime(hoy.year, hoy.month - 5, 1);
    _fechaDesde  = _fmt(hace6m);
    _fechaHasta  = _fmt(hoy);

    // Mes actual vs mes anterior
    final inicioMesActual   = DateTime(hoy.year, hoy.month, 1);
    final finMesAnterior    = DateTime(hoy.year, hoy.month, 0);
    final inicioMesAnterior = DateTime(hoy.year, hoy.month - 1, 1);
    _p2Desde = _fmt(inicioMesActual);
    _p2Hasta = _fmt(hoy);
    _p1Desde = _fmt(inicioMesAnterior);
    _p1Hasta = _fmt(finMesAnterior);

    _cargar();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        _ds.getEstadisticasPorPeriodo(
          fechaDesde: _fechaDesde,
          fechaHasta: _fechaHasta,
          agruparPor: _agruparPor,
        ),
        _ds.getComparacion(
          p1Desde: _p1Desde, p1Hasta: _p1Hasta,
          p2Desde: _p2Desde, p2Hasta: _p2Hasta,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _periodos    = results[0] as List<Map<String, dynamic>>;
        _comparacion = results[1] as Map<String, dynamic>;
        _cargando    = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas de hurtos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _selectorAgrupacion(),
                  const SizedBox(height: 16),
                  if (_comparacion != null) _tarjetaTendencia(),
                  const SizedBox(height: 16),
                  _graficoBarras(),
                  const SizedBox(height: 16),
                  if (_comparacion != null) _comparacionDetalle(),
                ],
              ),
            ),
    );
  }

  Widget _selectorAgrupacion() {
    return Row(
      children: ['dia', 'semana', 'mes'].map((op) {
        final sel = _agruparPor == op;
        return GestureDetector(
          onTap: () {
            setState(() => _agruparPor = op);
            _cargar();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              op[0].toUpperCase() + op.substring(1),
              style: GoogleFonts.inter(
                color: sel ? Colors.white : AppColors.textSub,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tarjetaTendencia() {
    final c          = _comparacion!;
    final tendencia  = c['tendencia'] as String;
    final diferencia = c['diferencia'] as int;
    final porcentaje = c['porcentaje'];
    final total2     = (c['periodo2'] as Map)['total'] as int;

    final color = tendencia == 'incremento'
        ? AppColors.tendenciaIncremento
        : tendencia == 'decremento'
            ? AppColors.tendenciaDecremento
            : AppColors.tendenciaVariacion;

    final icono = tendencia == 'incremento'
        ? Icons.trending_up
        : tendencia == 'decremento'
            ? Icons.trending_down
            : Icons.trending_flat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icono, color: color, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Este mes: $total2 reportes',
              style: GoogleFonts.montserrat(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              porcentaje != null
                  ? '${diferencia > 0 ? '+' : ''}$diferencia ($porcentaje%) vs mes anterior'
                  : 'Sin datos del mes anterior',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _graficoBarras() {
    if (_periodos.isEmpty) {
      return Center(
        child: Text('Sin datos para el período',
            style: GoogleFonts.inter(color: AppColors.textSub)),
      );
    }

    final maxTotal = _periodos
        .map((p) => (p['total'] as int))
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportes por período',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _periodos.map((p) {
                final total = (p['total'] as int).toDouble();
                final alto  = maxTotal > 0 ? (total / maxTotal) * 140 : 0.0;
                final label = (p['periodo'] as String).length > 7
                    ? (p['periodo'] as String).substring(5)
                    : p['periodo'] as String;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${p['total']}',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppColors.textSub)),
                        const SizedBox(height: 2),
                        Container(
                          height: alto,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(label,
                            style: GoogleFonts.inter(
                                fontSize: 8, color: AppColors.textSub),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparacionDetalle() {
    final c  = _comparacion!;
    final p1 = c['periodo1'] as Map;
    final p2 = c['periodo2'] as Map;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comparación de períodos',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _colPeriodo('Mes anterior', p1)),
            const SizedBox(width: 12),
            Expanded(child: _colPeriodo('Mes actual', p2)),
          ]),
        ],
      ),
    );
  }

  Widget _colPeriodo(String titulo, Map periodo) {
    final porTipo = Map<String, dynamic>.from(periodo['porTipo'] ?? {});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub)),
        const SizedBox(height: 4),
        Text('${periodo['total']} total',
            style: GoogleFonts.montserrat(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 8),
        ...porTipo.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub)),
              Text('${e.value}', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain)),
            ],
          ),
        )),
      ],
    );
  }
}
