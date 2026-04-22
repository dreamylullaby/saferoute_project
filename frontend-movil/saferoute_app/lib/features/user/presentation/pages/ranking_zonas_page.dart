import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme.dart';
import '../../data/datasources/estadisticas_datasource.dart';

class RankingZonasPage extends StatefulWidget {
  const RankingZonasPage({super.key});

  @override
  State<RankingZonasPage> createState() => _RankingZonasPageState();
}

class _RankingZonasPageState extends State<RankingZonasPage> {
  final _ds = EstadisticasDatasource();

  int       _top        = 10;
  String?   _fechaDesde;
  String?   _fechaHasta;
  List<Map<String, dynamic>> _zonas = [];
  bool _cargando = true;

  static const _opciones = [5, 10, 20];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await _ds.getTopZonas(
        top:        _top,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );
      if (!mounted) return;
      setState(() { _zonas = data; _cargando = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final str = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
    setState(() => esDesde ? _fechaDesde = str : _fechaHasta = str);
    _cargar();
  }

  void _limpiarFechas() {
    setState(() { _fechaDesde = null; _fechaHasta = null; });
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final maxTotal = _zonas.isEmpty ? 1 :
        (_zonas.map((z) => z['total'] as int).reduce((a, b) => a > b ? a : b));

    return Scaffold(
      appBar: AppBar(title: const Text('Zonas de mayor riesgo')),
      body: Column(
        children: [
          // ── Controles ──
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector top N
                Row(children: [
                  Text('Mostrar top:', style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSub)),
                  const SizedBox(width: 8),
                  ..._opciones.map((n) {
                    final sel = _top == n;
                    return GestureDetector(
                      onTap: () { setState(() => _top = n); _cargar(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text('$n', style: GoogleFonts.inter(
                            fontSize: 13,
                            color: sel ? Colors.white : AppColors.textSub,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                      ),
                    );
                  }),
                ]),
                const SizedBox(height: 10),
                // Filtros de fecha
                Row(children: [
                  _chipFecha('Desde', _fechaDesde, () => _seleccionarFecha(true)),
                  const SizedBox(width: 8),
                  _chipFecha('Hasta', _fechaHasta, () => _seleccionarFecha(false)),
                  if (_fechaDesde != null || _fechaHasta != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _limpiarFechas,
                      child: Text('Limpiar',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Lista ──
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _zonas.isEmpty
                    ? Center(child: Text('Sin datos',
                        style: GoogleFonts.inter(color: AppColors.textSub)))
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _zonas.length,
                          itemBuilder: (_, i) {
                            final z     = _zonas[i];
                            final total = z['total'] as int;
                            final pct   = total / maxTotal;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(children: [
                                // Posición
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: _colorPosicion(i),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${i + 1}',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(z['barrio'] ?? 'Sin definir',
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMain)),
                                      if (z['comuna'] != null)
                                        Text('Comuna ${z['comuna']}',
                                            style: GoogleFonts.inter(
                                                fontSize: 12, color: AppColors.textSub)),
                                      const SizedBox(height: 6),
                                      // Barra proporcional
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 6,
                                          backgroundColor: AppColors.border,
                                          valueColor: AlwaysStoppedAnimation(
                                              _colorPosicion(i)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Conteo
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$total',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: _colorPosicion(i))),
                                    Text('hurtos',
                                        style: GoogleFonts.inter(
                                            fontSize: 11, color: AppColors.textSub)),
                                  ],
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chipFecha(String label, String? valor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: valor != null ? AppColors.primary.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: valor != null ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          valor != null ? '$label: $valor' : label,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: valor != null ? AppColors.primary : AppColors.textSub),
        ),
      ),
    );
  }

  Color _colorPosicion(int i) {
    if (i == 0) return AppColors.altoRiesgo;
    if (i == 1) return AppColors.riesgoMedio;
    if (i == 2) return AppColors.bajoRiesgo;
    return AppColors.primary;
  }
}
