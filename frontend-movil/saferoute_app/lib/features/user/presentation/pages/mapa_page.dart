import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/app_theme.dart';
import '../../data/datasources/reporte_mapa_datasource.dart';
import '../../data/models/reporte_mapa_model.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../widgets/heatmap_layer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});
  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final _scaffoldKey   = GlobalKey<ScaffoldState>();
  final _datasource    = ReporteMapaDatasource();
  final _mapController = MapController();

  List<ReporteMapaModel> _todos     = [];
  List<ReporteMapaModel> _filtrados = [];
  bool _cargando = true;
  bool _modoCalor = false;
  bool _modoOscuro = false;
  String _ultimaActualizacion = DateTime.now().toUtc().toIso8601String();
  Timer? _timer;

  // Filtros activos
  final Set<int>    _comunasSeleccionadas  = {};
  final Set<String> _franjasSeleccionadas  = {};
  final Set<String> _tiposSeleccionados    = {};
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  static const _franjas = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
  static const _tipos   = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _cargarTodos();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _actualizarNuevos());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Datos ──────────────────────────────────────────────────────────────────

  Future<void> _cargarTodos() async {
    try {
      final data = await _datasource.getReportesParaMapa();
      if (!mounted) return;
      setState(() {
        _todos    = data;
        _cargando = false;
        _ultimaActualizacion = DateTime.now().toUtc().toIso8601String();
        _aplicarFiltros();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _actualizarNuevos() async {
    try {
      final nuevos = await _datasource.getReportesNuevos(_ultimaActualizacion);
      if (!mounted || nuevos.isEmpty) return;
      final ids = _todos.map((r) => r.id).toSet();
      setState(() {
        _todos.addAll(nuevos.where((r) => !ids.contains(r.id)));
        _ultimaActualizacion = DateTime.now().toUtc().toIso8601String();
        _aplicarFiltros();
      });
    } catch (_) {}
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } catch (_) {}
  }

  // ── Filtros ────────────────────────────────────────────────────────────────

  void _aplicarFiltros() {
    // Si no hay filtros activos, mostrar todos los reportes en memoria
    if (!_hayFiltros) {
      setState(() => _filtrados = List.from(_todos));
      return;
    }
    // Con filtros activos, delegar al backend para mejor rendimiento
    _aplicarFiltrosBackend();
  }

  Future<void> _aplicarFiltrosBackend() async {
    setState(() => _cargando = true);
    try {
      final resultado = await _datasource.getReportesFiltrados(
        comunas:    _comunasSeleccionadas.isNotEmpty
            ? _comunasSeleccionadas.toList() : null,
        franjas:    _franjasSeleccionadas.isNotEmpty
            ? _franjasSeleccionadas.toList() : null,
        tipos:      _tiposSeleccionados.isNotEmpty
            ? _tiposSeleccionados.toList() : null,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );
      if (!mounted) return;
      setState(() {
        _filtrados = resultado;
        _cargando  = false;
      });
    } catch (_) {
      // Si falla el backend, caer en filtrado local como fallback
      if (!mounted) return;
      setState(() {
        _filtrados = _todos.where((r) {
          if (_comunasSeleccionadas.isNotEmpty &&
              !_comunasSeleccionadas.contains(r.comuna)) return false;
          if (_franjasSeleccionadas.isNotEmpty &&
              !_franjasSeleccionadas.contains(r.franjaHoraria)) return false;
          if (_tiposSeleccionados.isNotEmpty &&
              !_tiposSeleccionados.contains(r.tipoHurto)) return false;
          if (_fechaDesde != null) {
            final f = DateTime.tryParse(r.fechaIncidente);
            if (f != null && f.isBefore(_fechaDesde!)) return false;
          }
          if (_fechaHasta != null) {
            final f = DateTime.tryParse(r.fechaIncidente);
            if (f != null && f.isAfter(_fechaHasta!)) return false;
          }
          return true;
        }).toList();
        _cargando = false;
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _comunasSeleccionadas.clear();
      _franjasSeleccionadas.clear();
      _tiposSeleccionados.clear();
      _fechaDesde = null;
      _fechaHasta = null;
      _filtrados  = List.from(_todos);
    });
  }

  bool get _hayFiltros =>
      _comunasSeleccionadas.isNotEmpty ||
      _franjasSeleccionadas.isNotEmpty  ||
      _tiposSeleccionados.isNotEmpty    ||
      _fechaDesde != null               ||
      _fechaHasta != null;

  // ── Colores / íconos ───────────────────────────────────────────────────────

  Color _colorTipo(String tipo) => switch (tipo) {
    'atraco'     => AppColors.hurtoAtraco,
    'raponazo'   => AppColors.hurtoRaponazo,
    'fleteo'     => AppColors.hurtoFleteo,
    'cosquilleo' => AppColors.hurtoCosquilleo,
    _            => AppColors.primary,
  };

  IconData _iconoTipo(String tipo) => switch (tipo) {
    'atraco'     => Icons.warning_rounded,
    'raponazo'   => Icons.directions_run,
    'fleteo'     => Icons.motorcycle,
    'cosquilleo' => Icons.back_hand_outlined,
    _            => Icons.location_on,
  };

  /// Genera los puntos del heatmap con intensidad basada en la densidad
  /// de reportes cercanos. Reportes en zonas con más incidentes tendrán
  /// mayor intensidad, lo que produce manchas más cálidas (rojas).
  List<HeatmapPoint> _buildHeatmapPoints() {
    if (_filtrados.isEmpty) return [];
    const radio = 0.005; // ~500m en grados
    return _filtrados.map((r) {
      final cercanos = _filtrados.where((o) =>
          (o.latitud - r.latitud).abs() < radio &&
          (o.longitud - r.longitud).abs() < radio).length;
      // Normalizar: 1 reporte = 0.15, 10+ reportes = 1.0
      final intensity = (cercanos / 10).clamp(0.15, 1.0);
      return HeatmapPoint(LatLng(r.latitud, r.longitud), intensity);
    }).toList();
  }

  // ── Detalle reporte ────────────────────────────────────────────────────────

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    await UserRemoteDatasource().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _verDetalle(ReporteMapaModel r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(_iconoTipo(r.tipoHurto), color: _colorTipo(r.tipoHurto), size: 28),
              const SizedBox(width: 10),
              Text(r.tipoHurto[0].toUpperCase() + r.tipoHurto.substring(1),
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            _fila(Icons.location_on_outlined,   r.barrioIngresado),
            _fila(Icons.calendar_today_outlined, r.fechaIncidente),
            _fila(Icons.access_time_outlined,    r.franjaHoraria),
            if (r.comuna != null) _fila(Icons.map_outlined, 'Comuna ${r.comuna}'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _fila(IconData ic, String txt) {
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

  // ── Panel de filtros (Drawer izquierdo) ───────────────────────────────────

  void _abrirFiltros() => _scaffoldKey.currentState?.openDrawer();

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF334155) : Colors.white;
    final chipText = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final chipBorder = isDark ? const Color(0xFF475569) : AppColors.border;

    return Drawer(
      width: 300,
      child: SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setDrawer) => Column(children: [
            // Cabecera
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(children: [
                const Icon(Icons.filter_alt_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text('Filtros', style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
            ),

            // Contenido scrollable
            Expanded(
              child: ListView(padding: const EdgeInsets.all(20), children: [

                // ── Comunas ──
                Text('Comuna', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: chipText)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 4, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8, crossAxisSpacing: 8,
                  childAspectRatio: 1.3,
                  children: List.generate(12, (i) {
                    final n = i + 1;
                    final sel = _comunasSeleccionadas.contains(n);
                    return GestureDetector(
                      onTap: () => setDrawer(() => sel
                          ? _comunasSeleccionadas.remove(n)
                          : _comunasSeleccionadas.add(n)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : chipBg,
                          border: Border.all(
                              color: sel ? AppColors.primary : chipBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text('$n', style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : chipText)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // ── Franja horaria ──
                Text('Rango horario', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: chipText)),
                const SizedBox(height: 10),
                ..._franjas.map((f) {
                  final sel = _franjasSeleccionadas.contains(f);
                  return GestureDetector(
                    onTap: () => setDrawer(() => sel
                        ? _franjasSeleccionadas.remove(f)
                        : _franjasSeleccionadas.add(f)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary.withOpacity(0.15)
                            : chipBg,
                        border: Border.all(
                            color: sel ? AppColors.primary : chipBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(f, style: GoogleFonts.inter(
                          color: sel ? AppColors.primary : chipText,
                          fontWeight: sel
                              ? FontWeight.w600
                              : FontWeight.normal)),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // ── Tipo de hurto ──
                Text('Tipo de hurto', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: chipText)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8,
                  children: _tipos.map((t) {
                    final sel = _tiposSeleccionados.contains(t);
                    final color = _colorTipo(t);
                    return GestureDetector(
                      onTap: () => setDrawer(() => sel
                          ? _tiposSeleccionados.remove(t)
                          : _tiposSeleccionados.add(t)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? color : chipBg,
                          border: Border.all(
                              color: sel ? color : chipBorder),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t[0].toUpperCase() + t.substring(1),
                          style: GoogleFonts.inter(
                              color: sel ? Colors.white : chipText,
                              fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Fecha ──
                Text('Fecha del incidente', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: chipText)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campoFecha(ctx, 'Desde', _fechaDesde,
                      (d) => setDrawer(() => _fechaDesde = d))),
                  const SizedBox(width: 10),
                  Expanded(child: _campoFecha(ctx, 'Hasta', _fechaHasta,
                      (d) => setDrawer(() => _fechaHasta = d))),
                ]),
              ]),
            ),

            // Botones fijos al fondo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setDrawer(() {
                        _comunasSeleccionadas.clear();
                        _franjasSeleccionadas.clear();
                        _tiposSeleccionados.clear();
                        _fechaDesde = null;
                        _fechaHasta = null;
                      });
                      _aplicarFiltros();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      _aplicarFiltros();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ]),
            ),
            // Cerrar sesión
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
                  label: Text('Cerrar sesión',
                      style: GoogleFonts.inter(
                          color: AppColors.error, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _campoFecha(BuildContext ctx, String label, DateTime? valor,
      void Function(DateTime) onPick) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: valor ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF475569) : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(
              fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
          const SizedBox(height: 2),
          Text(
            valor != null
                ? '${valor.day.toString().padLeft(2, '0')}/'
                  '${valor.month.toString().padLeft(2, '0')}/'
                  '${valor.year}'
                : 'dd/mm/aaaa',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: valor != null
                    ? (isDark ? const Color(0xFFE2E8F0) : AppColors.textMain)
                    : (isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
          ),
        ]),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final barText = isDark ? Colors.white : AppColors.textMain;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              // ── Mapa ──
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(1.2136, -77.2811),
                  initialZoom: 14,
                  minZoom: 10,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _modoOscuro
                        ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11'
                          '/tiles/{z}/{x}/{y}?access_token=$token'
                        : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12'
                          '/tiles/{z}/{x}/{y}?access_token=$token',
                    userAgentPackageName: 'com.saferoute.app',
                  ),

                  // Capa heatmap real con gradiente de densidad
                  if (_modoCalor)
                    HeatmapLayer(
                      points: _buildHeatmapPoints(),
                      radius: 35,
                      maxOpacity: 0.55,
                      blur: 20,
                    ),

                  // Capa marcadores con íconos
                  if (!_modoCalor)
                    MarkerLayer(
                      markers: _filtrados.map((r) => Marker(
                        point: LatLng(r.latitud, r.longitud),
                        width: 36, height: 36,
                        child: GestureDetector(
                          onTap: () => _verDetalle(r),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _colorTipo(r.tipoHurto),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))],
                            ),
                            child: Icon(_iconoTipo(r.tipoHurto),
                                color: Colors.white, size: 20),
                          ),
                        ),
                      )).toList(),
                    ),
                ],
              ),

              // ── AppBar flotante ──
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(children: [
                      // Título
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: barBg,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(
                                color: Colors.black12, blurRadius: 6)],
                          ),
                          child: Row(children: [
                            // Botón hamburguesa
                            GestureDetector(
                              onTap: _abrirFiltros,
                              child: Stack(children: [
                                Container(
                                  width: 32, height: 32,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _hayFiltros
                                        ? AppColors.primary
                                        : (isDark ? const Color(0xFF334155) : AppColors.background),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.menu,
                                      color: _hayFiltros
                                          ? Colors.white
                                          : barText,
                                      size: 20),
                                ),
                                if (_hayFiltros)
                                  Positioned(
                                    top: 2, right: 6,
                                    child: Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle),
                                    ),
                                  ),
                              ]),
                            ),
                            Icon(Icons.location_on,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text('SafeRoute',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : AppColors.primaryDark)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_filtrados.length} reportes',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ]),
                  ),
                ),
              ),

              // ── Leyenda ──
              Positioned(
                bottom: 90, left: 16,
                child: _modoCalor ? _leyendaCalor() : _leyendaMarcadores(),
              ),

              // ── FAB registrar hurto ──
              Positioned(
                bottom: 24, right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/reportar'),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add_location_alt_outlined,
                      color: Colors.white),
                  label: Text('Registrar hurto',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),

              // ── Botones laterales derechos ──
              Positioned(
                bottom: 90, right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle mapa de calor / marcadores
                    _botonFlotante(
                      icon: _modoCalor
                          ? Icons.location_on
                          : Icons.whatshot_rounded,
                      color: _modoCalor
                          ? AppColors.altoRiesgo
                          : Colors.white,
                      iconColor: _modoCalor
                          ? Colors.white
                          : AppColors.textMain,
                      onTap: () => setState(() => _modoCalor = !_modoCalor),
                      tooltip: _modoCalor
                          ? 'Ver marcadores'
                          : 'Ver mapa de calor',
                    ),
                    const SizedBox(height: 10),
                    _botonFlotante(
                      icon: darkModeNotifier.value
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: darkModeNotifier.value
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      iconColor: darkModeNotifier.value
                          ? Colors.amber
                          : AppColors.textMain,
                      onTap: () => setState(() {
                        _modoOscuro = !(_modoOscuro == true);
                        darkModeNotifier.value = _modoOscuro;
                      }),
                      tooltip: darkModeNotifier.value
                          ? 'Modo claro'
                          : 'Modo oscuro',
                    ),
                    const SizedBox(height: 10),
                    _botonFlotante(
                      icon: Icons.my_location,
                      color: Colors.white,
                      iconColor: AppColors.primary,
                      onTap: _obtenerUbicacion,
                      tooltip: 'Mi ubicación',
                    ),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _botonFlotante({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    String? tooltip,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Stack(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(
                  color: Colors.black26, blurRadius: 6,
                  offset: Offset(0, 2))],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          if (badge)
            Positioned(
              top: 0, right: 0,
              child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _leyendaMarcadores() {
    const items = [
      ('Atraco',     AppColors.hurtoAtraco),
      ('Raponazo',   AppColors.hurtoRaponazo),
      ('Fleteo',     AppColors.hurtoFleteo),
      ('Cosquilleo', AppColors.hurtoCosquilleo),
    ];
    return _contenedorLeyenda(
      children: items.map((e) => _filaLeyenda(e.$2, e.$1)).toList(),
    );
  }

  Widget _leyendaCalor() {
    return _contenedorLeyenda(
      children: [
        _filaLeyenda(const Color(0xFF22C55E), 'Zona segura'),
        _filaLeyenda(const Color(0xFFFACC15), 'Bajo riesgo'),
        _filaLeyenda(const Color(0xFFF97316), 'Riesgo medio'),
        _filaLeyenda(const Color(0xFFBE185D), 'Alto riesgo'),
      ],
    );
  }

  Widget _contenedorLeyenda({required List<Widget> children}) {
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

  Widget _filaLeyenda(Color color, String label) {
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
