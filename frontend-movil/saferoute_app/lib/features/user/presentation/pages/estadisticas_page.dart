import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/app_theme.dart';
import '../../../../services/auth_storage.dart';
import '../../data/datasources/estadisticas_datasource.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key, this.datasource});
  final EstadisticasDatasource? datasource;
  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  late final EstadisticasDatasource _ds =
      widget.datasource ?? EstadisticasDatasource();
  bool _cargando = true;

  Map<String, dynamic> _resumen = {};
  Map<String, dynamic>? _comparacion;
  List<Map<String, dynamic>> _topZonas = [];

  String? _filtroComuna;
  String? _filtroFranja;
  String? _filtroTipo;
  String? _fechaDesde;
  String? _fechaHasta;
  bool _hayFiltros = false;
  bool _modoRural = false;
  String? _filtroCorregimiento;
  List<Map<String, dynamic>> _corregimientos = [];

  static const _coloresTipo = {
    'atraco': AppColors.hurtoAtraco,
    'raponazo': AppColors.hurtoRaponazo,
    'fleteo': AppColors.hurtoFleteo,
    'cosquilleo': AppColors.hurtoCosquilleo,
  };

  static const _coloresFranja = {
    '06:00-11:59': AppColors.franjaMannana,
    '12:00-17:59': AppColors.franjaTarde,
    '18:00-23:59': AppColors.franjaNoche,
    '00:00-05:59': AppColors.franjaMadrugada,
  };

  static const _nombresFranja = {
    '06:00-11:59': 'Mañana (06:00-11:59)',
    '12:00-17:59': 'Tarde (12:00-17:59)',
    '18:00-23:59': 'Noche (18:00-23:59)',
    '00:00-05:59': 'Madrugada (00:00-05:59)',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarCorregimientos();
  }

  Future<void> _cargarCorregimientos() async {
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final token = await AuthStorage.getToken();
      final res = await http.get(Uri.parse('$base/api/reportes/corregimientos'),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) setState(() => _corregimientos = List<Map<String, dynamic>>.from(body['data'] ?? []));
      }
    } catch (_) {}
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final hoy = DateTime.now();
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      final finMesAnt = DateTime(hoy.year, hoy.month, 0);
      final inicioMesAnt = DateTime(hoy.year, hoy.month - 1, 1);

      _hayFiltros = _filtroComuna != null || _filtroFranja != null || _filtroTipo != null || _fechaDesde != null || _fechaHasta != null || _filtroCorregimiento != null || _modoRural;

      final resumenFuture = _hayFiltros
          ? _ds.getResumenFiltrado(
              comunas: _filtroComuna != null ? [int.parse(_filtroComuna!)] : null,
              franjas: _filtroFranja != null ? [_filtroFranja!] : null,
              tipos: _filtroTipo != null ? [_filtroTipo!] : null,
              fechaDesde: _fechaDesde,
              fechaHasta: _fechaHasta,
              corregimientoId: _filtroCorregimiento != null ? int.parse(_filtroCorregimiento!) : null,
              esRural: _modoRural ? true : null,
            )
          : _ds.getResumenUsuario();

      final results = await Future.wait([
        resumenFuture,
        _ds.getComparacion(p1Desde: _fmt(inicioMesAnt), p1Hasta: _fmt(finMesAnt), p2Desde: _fmt(inicioMes), p2Hasta: _fmt(hoy)),
        _ds.getTopZonas(top: 5, fechaDesde: _fechaDesde, fechaHasta: _fechaHasta),
      ]);
      if (!mounted) return;
      setState(() {
        _resumen = results[0] as Map<String, dynamic>;
        _comparacion = results[1] as Map<String, dynamic>;
        _topZonas = results[2] as List<Map<String, dynamic>>;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _limpiarFiltros() {
    setState(() { _filtroComuna = null; _filtroFranja = null; _filtroTipo = null; _fechaDesde = null; _fechaHasta = null; _filtroCorregimiento = null; _modoRural = false; });
    _cargar();
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: esDesde ? DateTime(2020) : (_fechaDesde != null ? DateTime.parse(_fechaDesde!) : DateTime(2020)),
      lastDate: esDesde ? (_fechaHasta != null ? DateTime.parse(_fechaHasta!) : DateTime.now()) : DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => esDesde ? _fechaDesde = _fmt(picked) : _fechaHasta = _fmt(picked));
    _cargar();
  }

  Widget _buildFiltros(Color card, Color textM, Color textS) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF475569) : AppColors.border;
    const ruralColor = Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.filter_list, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Filtros', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textM)),
          const Spacer(),
          if (_hayFiltros) GestureDetector(onTap: _limpiarFiltros, child: Text('Limpiar', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500))),
        ]),
        const SizedBox(height: 16),

        // Toggle Urbano / Rural
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () { setState(() { _modoRural = false; _filtroCorregimiento = null; }); _cargar(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_modoRural ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.location_city, size: 16, color: !_modoRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
                  const SizedBox(width: 6),
                  Text('Urbano', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: !_modoRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub))),
                ]),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () { setState(() { _modoRural = true; _filtroComuna = null; }); _cargar(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _modoRural ? ruralColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.park_outlined, size: 16, color: _modoRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
                  const SizedBox(width: 6),
                  Text('Rural', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _modoRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub))),
                ]),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Zona según modo
        if (!_modoRural) ...[
          Text('Zona (Comuna)', style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          _dropdownField(
            value: _filtroComuna != null ? 'Comuna $_filtroComuna' : 'Todas las comunas',
            onTap: () => _showFilterSheet('Comuna', List.generate(12, (i) => MapEntry('${i + 1}', 'Comuna ${i + 1}')), _filtroComuna, (v) { setState(() => _filtroComuna = v); _cargar(); }),
            borderColor: borderColor, textM: textM, textS: textS,
          ),
        ] else ...[
          Text('Corregimiento', style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          _dropdownField(
            value: _filtroCorregimiento != null
                ? _corregimientos.firstWhere((c) => '${c['id']}' == _filtroCorregimiento, orElse: () => {'nombre': 'Corregimiento $_filtroCorregimiento'})['nombre'] as String
                : 'Todos los corregimientos',
            onTap: () => _showFilterSheet(
              'Corregimiento',
              _corregimientos.map((c) => MapEntry('${c['id']}', c['nombre'] as String)).toList(),
              _filtroCorregimiento,
              (v) { setState(() => _filtroCorregimiento = v); _cargar(); },
            ),
            borderColor: borderColor, textM: textM, textS: textS,
          ),
        ],
        const SizedBox(height: 14),

        // Tipo de hurto
        Text('Tipo de hurto', style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        _dropdownField(
          value: _filtroTipo != null ? '${_filtroTipo![0].toUpperCase()}${_filtroTipo!.substring(1)}' : 'Todos los tipos',
          onTap: () => _showFilterSheet('Tipo de hurto', [MapEntry('atraco', 'Atraco'), MapEntry('raponazo', 'Raponazo'), MapEntry('fleteo', 'Fleteo'), MapEntry('cosquilleo', 'Cosquilleo')], _filtroTipo, (v) { setState(() => _filtroTipo = v); _cargar(); }),
          borderColor: borderColor, textM: textM, textS: textS,
        ),
        const SizedBox(height: 14),
        // Rango de tiempo (franja)
        Text('Rango de tiempo', style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        _dropdownField(
          value: _filtroFranja != null ? (_nombresFranja[_filtroFranja] ?? _filtroFranja!) : 'Todos los horarios',
          onTap: () => _showFilterSheet('Franja horaria', _nombresFranja.entries.map((e) => MapEntry(e.key, e.value)).toList(), _filtroFranja, (v) { setState(() => _filtroFranja = v); _cargar(); }),
          borderColor: borderColor, textM: textM, textS: textS,
        ),
        const SizedBox(height: 14),
        // Fechas
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fecha desde', style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _dateField(_fechaDesde, () => _seleccionarFecha(true), borderColor, textM, textS),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fecha hasta', style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _dateField(_fechaHasta, () => _seleccionarFecha(false), borderColor, textM, textS),
          ])),
        ]),
      ]),
    );
  }

  Widget _dropdownField({required String value, required VoidCallback onTap, required Color borderColor, required Color textM, required Color textS}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
        child: Row(children: [
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: textM), overflow: TextOverflow.ellipsis)),
          Icon(Icons.keyboard_arrow_down, size: 22, color: textS),
        ]),
      ),
    );
  }

  Widget _dateField(String? value, VoidCallback onTap, Color borderColor, Color textM, Color textS) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
        child: Row(children: [
          Expanded(child: Text(value ?? 'dd/mm/aaaa', style: GoogleFonts.inter(fontSize: 14, color: value != null ? textM : textS))),
          Icon(Icons.calendar_today_outlined, size: 16, color: textS),
        ]),
      ),
    );
  }

  void _showFilterSheet(String title, List<MapEntry<String, String>> options, String? current, void Function(String?) onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final sheetText = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final sheetSub = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: sheetBg, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: sheetText)),
            const Spacer(),
            if (current != null) GestureDetector(onTap: () { Navigator.pop(ctx); onSelect(null); }, child: Text('Quitar filtro', style: GoogleFonts.inter(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500))),
          ])),
          Divider(height: 1, color: isDark ? const Color(0xFF475569) : AppColors.border),
          Expanded(child: ListView.builder(
            controller: scrollController,
            itemCount: options.length,
            itemBuilder: (_, i) {
              final o = options[i];
              final selected = current == o.key;
              return ListTile(
                leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? AppColors.primary : sheetSub, size: 20),
                title: Text(o.value, style: GoogleFonts.inter(fontSize: 14, color: sheetText, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                onTap: () { Navigator.pop(ctx); onSelect(o.key); },
              );
            },
          )),
        ])),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : AppColors.surface;
    final textMain = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final textSub = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                // Filtros
                _buildFiltros(cardColor, textMain, textSub),
                const SizedBox(height: 16),
                // KPIs
                _buildKpis(cardColor, textMain, textSub),
                const SizedBox(height: 16),
                // Tendencia
                if (_comparacion != null) _buildTendencia(cardColor, textMain, textSub),
                if (_comparacion != null) const SizedBox(height: 16),
                // Incidentes por zona (Comuna o Corregimiento)
                _buildBarrasZona(cardColor, textMain, textSub),
                const SizedBox(height: 16),
                // Incidentes por Horario
                _buildLineaHorario(cardColor, textMain, textSub),
                const SizedBox(height: 16),
                // Donut Tipo de Hurto
                _buildDonutTipo(cardColor, textMain, textSub),
                const SizedBox(height: 16),
                // Top 5 Zonas
                _buildTopZonas(cardColor, textMain, textSub),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _buildKpis(Color card, Color textM, Color textS) {
    final total = _resumen['total'] ?? 0;
    final porComuna = Map<String, dynamic>.from(_resumen['porComuna'] ?? {});
    final porFranja = Map<String, dynamic>.from(_resumen['porFranja'] ?? {});

    String comunaMax = '—';
    int comunaMaxVal = 0;
    porComuna.forEach((k, v) { if ((v as int) > comunaMaxVal) { comunaMax = 'Comuna $k'; comunaMaxVal = v; } });

    String franjaMax = '—';
    int franjaMaxVal = 0;
    porFranja.forEach((k, v) { if ((v as int) > franjaMaxVal) { franjaMax = _nombresFranja[k] ?? k; franjaMaxVal = v; } });

    return Column(children: [
      _kpiCard(Icons.assessment, 'Total de incidentes', '$total', AppColors.primary, card, textM, textS),
      const SizedBox(height: 10),
      _kpiCard(Icons.location_on, 'Zona más peligrosa', comunaMax, AppColors.altoRiesgo, card, textM, textS),
      const SizedBox(height: 10),
      _kpiCard(Icons.access_time, 'Horario más peligroso', franjaMax, AppColors.franjaNoche, card, textM, textS),
    ]);
  }

  Widget _kpiCard(IconData icon, String label, String value, Color color, Color card, Color textM, Color textS) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w300)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ])),
      ]),
    );
  }

  Widget _buildTendencia(Color card, Color textM, Color textS) {
    final c = _comparacion!;
    final tendencia = c['tendencia'] as String;
    final diferencia = c['diferencia'] as int;
    final porcentaje = c['porcentaje'];
    final total2 = (c['periodo2'] as Map)['total'] as int;

    final color = tendencia == 'incremento' ? AppColors.tendenciaIncremento : tendencia == 'decremento' ? AppColors.tendenciaDecremento : AppColors.tendenciaVariacion;
    final icono = tendencia == 'incremento' ? Icons.trending_up : tendencia == 'decremento' ? Icons.trending_down : Icons.trending_flat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(icono, color: color, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Este mes: $total2 reportes', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          Text(porcentaje != null ? '${diferencia > 0 ? '+' : ''}$diferencia ($porcentaje%) vs mes anterior' : 'Sin datos del mes anterior', style: GoogleFonts.inter(fontSize: 12, color: textS)),
        ])),
      ]),
    );
  }

  Widget _buildBarrasZona(Color card, Color textM, Color textS) {
    if (_modoRural) {
      // Modo rural: barras por corregimiento
      final porComuna = Map<String, dynamic>.from(_resumen['porComuna'] ?? {});
      // porComuna en rural puede tener IDs de corregimiento como keys
      final entries = _corregimientos.map((c) {
        final id = '${c['id']}';
        final nombre = (c['nombre'] as String?) ?? '?';
        final abrev = nombre.length > 6 ? nombre.substring(0, 6) : nombre;
        return MapEntry(abrev, (porComuna[id] ?? 0) as int);
      }).toList();
      final maxVal = entries.isEmpty ? 0.0 : entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b).toDouble();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Incidentes por Corregimiento', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textM)),
          const SizedBox(height: 16),
          entries.isEmpty
            ? Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Sin datos rurales', style: GoogleFonts.inter(fontSize: 13, color: textS))))
            : SizedBox(
                height: 180,
                child: BarChart(BarChartData(
                  maxY: maxVal > 0 ? maxVal + 1 : 5,
                  barGroups: entries.asMap().entries.map((e) {
                    final isMax = e.value.value == maxVal.toInt() && maxVal > 0;
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(toY: e.value.value.toDouble(), color: isMax ? AppColors.altoRiesgo : const Color(0xFF16A34A), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    ]);
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                      return Padding(padding: const EdgeInsets.only(top: 6), child: Text(entries[idx].key, style: GoogleFonts.inter(fontSize: 8, color: textS)));
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: textS)))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5)),
                  borderData: FlBorderData(show: false),
                )),
              ),
        ]),
      );
    }

    // Modo urbano: barras por comuna (original)
    final porComuna = Map<String, dynamic>.from(_resumen['porComuna'] ?? {});
    final entries = List.generate(12, (i) => MapEntry('C${i + 1}', (porComuna['${i + 1}'] ?? 0) as int));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Incidentes por Comuna', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textM)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            maxY: maxVal > 0 ? maxVal + 1 : 5,
            barGroups: entries.asMap().entries.map((e) {
              final isMax = e.value.value == maxVal.toInt() && maxVal > 0;
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(toY: e.value.value.toDouble(), color: isMax ? AppColors.altoRiesgo : AppColors.primary, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              ]);
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(entries[v.toInt()].key, style: GoogleFonts.inter(fontSize: 9, color: textS))))),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: textS)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5)),
            borderData: FlBorderData(show: false),
          )),
        ),
      ]),
    );
  }

  Widget _buildLineaHorario(Color card, Color textM, Color textS) {
    final porFranja = Map<String, dynamic>.from(_resumen['porFranja'] ?? {});
    final franjas = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
    final valores = franjas.map((f) => (porFranja[f] ?? 0) as int).toList();
    final maxVal = valores.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Incidentes por Horario', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textM)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            maxY: maxVal > 0 ? maxVal + 2 : 5,
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: valores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                isCurved: true, color: AppColors.primary, barWidth: 3,
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
                dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white)),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final labels = ['00:00\n05:59', '06:00\n11:59', '12:00\n17:59', '18:00\n23:59'];
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(labels[v.toInt()], style: GoogleFonts.inter(fontSize: 9, color: textS), textAlign: TextAlign.center));
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: textS)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5), getDrawingVerticalLine: (_) => FlLine(color: AppColors.border.withValues(alpha: 0.2), strokeWidth: 0.5)),
            borderData: FlBorderData(show: false),
          )),
        ),
      ]),
    );
  }

  Widget _buildDonutTipo(Color card, Color textM, Color textS) {
    final porTipo = Map<String, dynamic>.from(_resumen['porTipo'] ?? {});
    final total = porTipo.values.fold(0, (int a, b) => a + (b as int));
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tipo de Hurto', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textM)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: porTipo.entries.map((e) {
              final pct = ((e.value as int) / total * 100);
              final color = _coloresTipo[e.key] ?? AppColors.textSub;
              return PieChartSectionData(
                value: (e.value as int).toDouble(), color: color, radius: 50,
                title: '${pct.toStringAsFixed(0)}%',
                titleStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              );
            }).toList(),
          )),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 8, children: porTipo.entries.map((e) {
          final color = _coloresTipo[e.key] ?? AppColors.textSub;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('${e.key[0].toUpperCase()}${e.key.substring(1)}: ${e.value}', style: GoogleFonts.inter(fontSize: 12, color: textM)),
          ]);
        }).toList()),
      ]),
    );
  }

  Widget _buildTopZonas(Color card, Color textM, Color textS) {
    if (_topZonas.isEmpty) return const SizedBox.shrink();
    final maxTotal = _topZonas.first['total'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top 5 Zonas más peligrosas', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textM)),
        const SizedBox(height: 12),
        ..._topZonas.asMap().entries.map((e) {
          final z = e.value;
          final i = e.key;
          final total = z['total'] as int;
          final pct = maxTotal > 0 ? total / maxTotal : 0.0;
          final color = i == 0 ? AppColors.altoRiesgo : i == 1 ? AppColors.riesgoMedio : i == 2 ? AppColors.bajoRiesgo : AppColors.primary;

          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: color, shape: BoxShape.circle), alignment: Alignment.center,
              child: Text('${i + 1}', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(z['barrio'] ?? '—', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textM)),
              if (z['comuna'] != null) Text('Comuna ${z['comuna']}', style: GoogleFonts.inter(fontSize: 11, color: textS)),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.border.withValues(alpha: 0.3), valueColor: AlwaysStoppedAnimation(color))),
            ])),
            const SizedBox(width: 10),
            Text('$total', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ]));
        }),
      ]),
    );
  }
}
