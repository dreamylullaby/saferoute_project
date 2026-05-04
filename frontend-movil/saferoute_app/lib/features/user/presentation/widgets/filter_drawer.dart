import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../services/auth_storage.dart';
import 'filter_chip_group.dart';
import 'filter_date_field.dart';

/// Drawer de filtros del mapa interactivo con toggle Urbano/Rural.
class FilterDrawer extends StatefulWidget {
  const FilterDrawer({
    super.key,
    required this.comunasSeleccionadas,
    required this.corregimientosSeleccionados,
    required this.franjasSeleccionadas,
    required this.tiposSeleccionados,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.conteoFiltros,
    required this.hayFiltros,
    required this.modoRural,
    required this.onModoRuralChanged,
    required this.onAplicar,
    required this.onRestablecer,
    required this.onCerrarSesion,
    this.onPerfil,
    this.onEstadisticas,
    this.onMisReportes,
    this.onFechaDesdeChanged,
    this.onFechaHastaChanged,
  });

  final Set<int> comunasSeleccionadas;
  final Set<int> corregimientosSeleccionados;
  final Set<String> franjasSeleccionadas;
  final Set<String> tiposSeleccionados;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final int conteoFiltros;
  final bool hayFiltros;
  final bool modoRural;
  final void Function(bool) onModoRuralChanged;
  final VoidCallback onAplicar;
  final VoidCallback onRestablecer;
  final VoidCallback onCerrarSesion;
  final VoidCallback? onPerfil;
  final VoidCallback? onEstadisticas;
  final VoidCallback? onMisReportes;
  final void Function(DateTime)? onFechaDesdeChanged;
  final void Function(DateTime)? onFechaHastaChanged;

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late DateTime? _localDesde;
  late DateTime? _localHasta;
  late bool _esRural;

  // Corregimientos cargados del backend
  List<Map<String, dynamic>> _corregimientos = [];
  bool _cargandoCorregimientos = false;

  // Búsqueda rural
  final _busquedaRuralCtrl = TextEditingController();
  List<Map<String, dynamic>> _resultadosBusqueda = [];

  // Búsqueda urbana (barrios)
  final _busquedaBarrioCtrl = TextEditingController();
  List<Map<String, dynamic>> _resultadosBarrio = [];

  static const _franjas = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
  static const _tipos = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];
  static const _ruralColor = Color(0xFF16A34A);

  static IconData _iconoTipo(String tipo) => switch (tipo) {
    'atraco' => Icons.warning_rounded,
    'raponazo' => Icons.directions_run,
    'fleteo' => Icons.motorcycle,
    'cosquilleo' => Icons.back_hand_outlined,
    _ => Icons.location_on,
  };

  @override
  void initState() {
    super.initState();
    _localDesde = widget.fechaDesde;
    _localHasta = widget.fechaHasta;
    _esRural = widget.modoRural;
    if (_esRural) _cargarCorregimientos();
  }

  @override
  void dispose() {
    _busquedaRuralCtrl.dispose();
    _busquedaBarrioCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> get _headers async {
    final token = await AuthStorage.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<void> _cargarCorregimientos() async {
    if (_corregimientos.isNotEmpty) return;
    setState(() => _cargandoCorregimientos = true);
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final res = await http.get(Uri.parse('$base/api/reportes/corregimientos'), headers: await _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _corregimientos = List<Map<String, dynamic>>.from(body['data'] ?? []);
          _cargandoCorregimientos = false;
        });
      }
    } catch (_) {
      setState(() => _cargandoCorregimientos = false);
    }
  }

  Future<void> _buscarRural(String texto) async {
    if (texto.trim().length < 2) {
      setState(() => _resultadosBusqueda = []);
      return;
    }
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final res = await http.get(
        Uri.parse('$base/api/reportes/buscar-rural?q=${Uri.encodeComponent(texto)}'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() => _resultadosBusqueda = List<Map<String, dynamic>>.from(body['data'] ?? []));
      }
    } catch (_) {}
  }

  Future<void> _buscarBarrio(String texto) async {
    if (texto.trim().length < 2) {
      setState(() => _resultadosBarrio = []);
      return;
    }
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final res = await http.get(
        Uri.parse('$base/api/reportes/barrios?q=${Uri.encodeComponent(texto)}'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() => _resultadosBarrio = List<Map<String, dynamic>>.from(body['data'] ?? []));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionText = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final accentColor = _esRural ? _ruralColor : AppColors.primary;

    return Drawer(
      width: 300,
      child: Column(
        children: [
          // Cabecera — cambia color según modo
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 12, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _esRural
                    ? [const Color(0xFF166534), const Color(0xFF16A34A)]
                    : [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Row(children: [
              const Icon(Icons.filter_alt_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Text('Filtros', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              if (widget.hayFiltros) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.conteoFiltros}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ]),
          ),

          // Toggle Urbano / Rural
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () { setState(() => _esRural = false); widget.onModoRuralChanged(false); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_esRural ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.location_city, size: 16, color: !_esRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
                      const SizedBox(width: 6),
                      Text('Urbano', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: !_esRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub))),
                    ]),
                  ),
                )),
                Expanded(child: GestureDetector(
                  onTap: () { setState(() => _esRural = true); widget.onModoRuralChanged(true); _cargarCorregimientos(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _esRural ? _ruralColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.park_outlined, size: 16, color: _esRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
                      const SizedBox(width: 6),
                      Text('Rural', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _esRural ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub))),
                    ]),
                  ),
                )),
              ]),
            ),
          ),

          // Contenido scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(25), // ← PADDING: general del contenido (toggle → primer título)
              children: [
                // ── Sección zona (urbano o rural) ──
                if (!_esRural) ...[
                  _sectionTitle('Buscar barrio', Icons.search, sectionText, accentColor),
                  const SizedBox(height: 15), // ← ESPACIO: título buscar barrio → campo buscador
                  TextField(
                    controller: _busquedaBarrioCtrl,
                    onChanged: _buscarBarrio,
                    style: GoogleFonts.inter(fontSize: 13, color: sectionText),
                    decoration: InputDecoration(
                      hintText: 'Ej: Miraflores...',
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (_resultadosBarrio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(children: _resultadosBarrio.map((b) {
                        final comuna = b['comuna'] as int?;
                        return InkWell(
                          onTap: () {
                            if (comuna != null) {
                              setState(() {
                                if (!widget.comunasSeleccionadas.contains(comuna)) {
                                  widget.comunasSeleccionadas.add(comuna);
                                }
                                _resultadosBarrio = [];
                                _busquedaBarrioCtrl.clear();
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                            child: Row(children: [
                              Expanded(child: Text(b['barrio'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: sectionText))),
                              if (comuna != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: Text('C·$comuna', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ),
                            ]),
                          ),
                        );
                      }).toList()),
                    ),
                  ],
                  const SizedBox(height: 28), // ← ESPACIO: buscador barrio → título comuna
                  _sectionTitle('Comuna', Icons.map_outlined, sectionText, accentColor),
                  const SizedBox(height: 8), // ← ESPACIO: título comuna → texto ayuda
                  Text('Buscar activa la comuna automáticamente', style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF64748B) : AppColors.textSub, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12), // ← ESPACIO: texto ayuda → chips comuna
                  FilterChipGroup<int>(
                    items: List.generate(12, (i) => i + 1),
                    selected: widget.comunasSeleccionadas,
                    onToggle: (n) => setState(() => widget.comunasSeleccionadas.contains(n) ? widget.comunasSeleccionadas.remove(n) : widget.comunasSeleccionadas.add(n)),
                    labelBuilder: (n) => '$n',
                    useGrid: true, gridColumns: 4, gridAspectRatio: 1.8,
                  ),
                ] else ...[
                  _sectionTitle('Buscar vereda', Icons.search, sectionText, accentColor),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _busquedaRuralCtrl,
                    onChanged: _buscarRural,
                    style: GoogleFonts.inter(fontSize: 13, color: sectionText),
                    decoration: InputDecoration(
                      hintText: 'Ej: Morasurco...',
                      prefixIcon: Icon(Icons.search, size: 18, color: _ruralColor),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _ruralColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _ruralColor.withOpacity(0.5))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _ruralColor, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (_resultadosBusqueda.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _ruralColor.withOpacity(0.3)),
                      ),
                      child: Column(children: _resultadosBusqueda.map((r) {
                        final esCorreg = r['tipo'] == 'corregimiento';
                        return InkWell(
                          onTap: () {
                            if (esCorreg) {
                              final id = r['id'] as int;
                              setState(() {
                                widget.corregimientosSeleccionados.contains(id)
                                    ? widget.corregimientosSeleccionados.remove(id)
                                    : widget.corregimientosSeleccionados.add(id);
                                _resultadosBusqueda = [];
                                _busquedaRuralCtrl.clear();
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(children: [
                              Expanded(child: Text(r['nombre'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: sectionText))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: esCorreg ? _ruralColor.withOpacity(0.15) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: esCorreg ? _ruralColor : const Color(0xFFFCD34D)),
                                ),
                                child: Text(esCorreg ? 'Corregimiento' : 'Vereda', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: esCorreg ? _ruralColor : const Color(0xFFD97706))),
                              ),
                            ]),
                          ),
                        );
                      }).toList()),
                    ),
                  ],
                  const SizedBox(height: 28), // ← ESPACIO: buscador vereda → título corregimiento
                  _sectionTitle('Corregimiento', Icons.park_outlined, sectionText, accentColor),
                  const SizedBox(height: 20), // ← ESPACIO: título corregimiento → chips corregimiento
                  _cargandoCorregimientos
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                      : FilterChipGroup<int>(
                          items: _corregimientos.map((c) => c['id'] as int).toList(),
                          selected: widget.corregimientosSeleccionados,
                          onToggle: (id) => setState(() => widget.corregimientosSeleccionados.contains(id) ? widget.corregimientosSeleccionados.remove(id) : widget.corregimientosSeleccionados.add(id)),
                          labelBuilder: (id) => _corregimientos.firstWhere((c) => c['id'] == id, orElse: () => {'nombre': '?'})['nombre'] ?? '?',
                          useGrid: true, gridColumns: 2, gridAspectRatio: 3.5,
                        ),
                ],
                const SizedBox(height: 20), // ← ESPACIO: chips zona → divider
                Divider(color: dividerColor, height: 5),
                const SizedBox(height: 20), // ← ESPACIO: divider → título rango horario

                // ── Rango horario ──
                _sectionTitle('Rango horario', Icons.access_time_rounded, sectionText, accentColor),
                const SizedBox(height: 20), // ← ESPACIO: título → chips rango horario
                FilterChipGroup<String>(
                  items: _franjas,
                  selected: widget.franjasSeleccionadas,
                  onToggle: (f) => setState(() => widget.franjasSeleccionadas.contains(f) ? widget.franjasSeleccionadas.remove(f) : widget.franjasSeleccionadas.add(f)),
                  labelBuilder: (f) => f,
                  iconBuilder: (_) => Icons.schedule_rounded,
                  useGrid: true, gridColumns: 2, gridAspectRatio: 4.5,
                ),
                const SizedBox(height: 25), // ← ESPACIO: chips rango → divider
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 25), // ← ESPACIO: divider → título tipo hurto

                // ── Tipo de hurto ──
                _sectionTitle('Tipo de hurto', Icons.local_police_rounded, sectionText, accentColor),
                const SizedBox(height: 20), // ← ESPACIO: título → chips tipo hurto
                FilterChipGroup<String>(
                  items: _tipos,
                  selected: widget.tiposSeleccionados,
                  onToggle: (t) => setState(() => widget.tiposSeleccionados.contains(t) ? widget.tiposSeleccionados.remove(t) : widget.tiposSeleccionados.add(t)),
                  labelBuilder: (t) => t[0].toUpperCase() + t.substring(1),
                  iconBuilder: (t) => _iconoTipo(t),
                  useGrid: true, gridColumns: 2, gridAspectRatio: 4.5,
                ),
                const SizedBox(height: 25), // ← ESPACIO: chips tipo hurto → divider
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 25), // ← ESPACIO: divider → título fecha

                // ── Fecha ──
                _sectionTitle('Fecha del incidente', Icons.calendar_today_rounded, sectionText, accentColor),
                const SizedBox(height: 20), // ← ESPACIO: título → campos fecha
                FilterDateField(label: 'Desde', value: _localDesde, lastDate: _localHasta ?? DateTime.now(), onPicked: (d) { setState(() => _localDesde = d); widget.onFechaDesdeChanged?.call(d); }),
                const SizedBox(height: 12),
                FilterDateField(label: 'Hasta', value: _localHasta, firstDate: _localDesde, onPicked: (d) { setState(() => _localHasta = d); widget.onFechaHastaChanged?.call(d); }),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Botones fijos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { widget.onAplicar(); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Aplicar filtros', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
              )),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () { setState(() { _localDesde = null; _localHasta = null; _esRural = false; _busquedaRuralCtrl.clear(); _busquedaBarrioCtrl.clear(); _resultadosBusqueda = []; _resultadosBarrio = []; }); widget.onRestablecer(); },
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: BorderSide(color: isDark ? const Color(0xFF475569) : AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Restablecer filtros', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
              )),
            ]),
          ),

          // Navegación
          Divider(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), height: 1, thickness: 0.5),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
            child: Column(children: [
              _navItem(icon: Icons.person_outline, label: 'Mi perfil', enabled: true, isDark: isDark, onTap: widget.onPerfil),
              _navItem(icon: Icons.bar_chart_rounded, label: 'Estadísticas', enabled: true, isDark: isDark, onTap: widget.onEstadisticas),
              _navItem(icon: Icons.description_outlined, label: 'Mis reportes', enabled: widget.onMisReportes != null, isDark: isDark, onTap: widget.onMisReportes),
              const SizedBox(height: 4),
              _navItem(icon: Icons.logout_rounded, label: 'Cerrar sesión', enabled: true, isDark: isDark, isDestructive: true, onTap: widget.onCerrarSesion),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon, Color color, Color accent) {
    return Row(children: [
      Icon(icon, size: 16, color: accent),
      const SizedBox(width: 6),
      Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
    ]);
  }

  Widget _navItem({required IconData icon, required String label, required bool isDark, bool enabled = true, bool isDestructive = false, VoidCallback? onTap}) {
    final activeColor = isDestructive ? AppColors.error : (isDark ? const Color(0xFFE2E8F0) : AppColors.textMain);
    final disabledColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final color = enabled ? activeColor : disabledColor;
    return Material(color: Colors.transparent, child: InkWell(
      onTap: enabled ? onTap : null, borderRadius: BorderRadius.circular(10),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Row(children: [
        Icon(icon, size: 20, color: color), const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: color))),
        if (!enabled) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6)), child: Text('Pronto', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: disabledColor))),
      ])),
    ));
  }
}
