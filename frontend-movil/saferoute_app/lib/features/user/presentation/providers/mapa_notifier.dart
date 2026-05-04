import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/reporte_mapa_datasource.dart';
import '../../data/models/reporte_mapa_model.dart';
import '../widgets/heatmap_layer.dart';

/// ChangeNotifier que gestiona el estado del mapa interactivo.
class MapaNotifier extends ChangeNotifier {
  MapaNotifier(this._datasource) {
    _cargarTodos();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _actualizarNuevos());
  }

  final ReporteMapaDatasource _datasource;
  Timer? _timer;

  List<ReporteMapaModel> _todos = [];
  List<ReporteMapaModel> _filtrados = [];
  bool _cargando = true;
  bool _modoCalor = false;
  String _ultimaActualizacion = DateTime.now().toUtc().toIso8601String();

  final Set<int>    comunasSeleccionadas       = {};
  final Set<int>    corregimientosSeleccionados = {};
  final Set<String> franjasSeleccionadas        = {};
  final Set<String> tiposSeleccionados          = {};
  DateTime? fechaDesde;
  DateTime? fechaHasta;
  bool _modoRural = false;

  bool get modoRural => _modoRural;
  void setModoRural(bool valor) {
    _modoRural = valor;
    notifyListeners();
  }

  // Stream para navegación del mapa (el widget escucha y ejecuta mapController.move)
  final _navegacionController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get navegacionStream => _navegacionController.stream;

  // Stream para notificar nuevos reportes cargados
  final _nuevosReportesController = StreamController<int>.broadcast();
  Stream<int> get nuevosReportesStream => _nuevosReportesController.stream;

  List<ReporteMapaModel> get filtrados => _filtrados;
  bool get cargando => _cargando;
  bool get modoCalor => _modoCalor;

  bool get hayFiltros =>
      comunasSeleccionadas.isNotEmpty || corregimientosSeleccionados.isNotEmpty ||
      franjasSeleccionadas.isNotEmpty || tiposSeleccionados.isNotEmpty ||
      fechaDesde != null || fechaHasta != null;

  int get conteoFiltros =>
      comunasSeleccionadas.length + corregimientosSeleccionados.length +
      franjasSeleccionadas.length + tiposSeleccionados.length +
      (fechaDesde != null ? 1 : 0) + (fechaHasta != null ? 1 : 0);

  void toggleModoCalor() { _modoCalor = !_modoCalor; notifyListeners(); }

  void navegarA(LatLng punto) => _navegacionController.add(punto);

  Future<void> _cargarTodos() async {
    try {
      final data = await _datasource.getReportesParaMapa();
      _todos = data;
      _cargando = false;
      _ultimaActualizacion = DateTime.now().toUtc().toIso8601String();
      aplicarFiltros();
    } catch (_) {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _actualizarNuevos() async {
    try {
      final nuevos = await _datasource.getReportesNuevos(_ultimaActualizacion);
      if (nuevos.isEmpty) return;
      final ids = _todos.map((r) => r.id).toSet();
      final realmente = nuevos.where((r) => !ids.contains(r.id)).toList();
      if (realmente.isEmpty) return;
      _todos.addAll(realmente);
      _ultimaActualizacion = DateTime.now().toUtc().toIso8601String();
      _nuevosReportesController.add(realmente.length);
      aplicarFiltros();
    } catch (_) {}
  }

  void aplicarFiltros() {
    if (!hayFiltros) {
      _filtrados = List.from(_todos);
      notifyListeners();
      return;
    }
    _aplicarFiltrosBackend();
  }

  Future<void> _aplicarFiltrosBackend() async {
    _cargando = true;
    notifyListeners();
    try {
      final resultado = await _datasource.getReportesFiltrados(
        comunas: comunasSeleccionadas.isNotEmpty ? comunasSeleccionadas.toList() : null,
        corregimientos: corregimientosSeleccionados.isNotEmpty ? corregimientosSeleccionados.toList() : null,
        franjas: franjasSeleccionadas.isNotEmpty ? franjasSeleccionadas.toList() : null,
        tipos: tiposSeleccionados.isNotEmpty ? tiposSeleccionados.toList() : null,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        zonaTipo: _modoRural ? 'rural' : (comunasSeleccionadas.isNotEmpty ? 'urbana' : null),
      );
      _filtrados = resultado;
      _cargando = false;
      notifyListeners();
    } catch (_) {
      _filtrados = _todos.where((r) {
        if (comunasSeleccionadas.isNotEmpty && !comunasSeleccionadas.contains(r.comuna)) return false;
        if (franjasSeleccionadas.isNotEmpty && !franjasSeleccionadas.contains(r.franjaHoraria)) return false;
        if (tiposSeleccionados.isNotEmpty && !tiposSeleccionados.contains(r.tipoHurto)) return false;
        if (fechaDesde != null) {
          final f = DateTime.tryParse(r.fechaIncidente);
          if (f != null && f.isBefore(fechaDesde!)) return false;
        }
        if (fechaHasta != null) {
          final f = DateTime.tryParse(r.fechaIncidente);
          if (f != null && f.isAfter(fechaHasta!)) return false;
        }
        return true;
      }).toList();
      _cargando = false;
      notifyListeners();
    }
  }

  void limpiarFiltros() {
    comunasSeleccionadas.clear();
    corregimientosSeleccionados.clear();
    franjasSeleccionadas.clear();
    tiposSeleccionados.clear();
    fechaDesde = null;
    fechaHasta = null;
    _modoRural = false;
    _filtrados = List.from(_todos);
    notifyListeners();
  }

  List<HeatmapPoint> buildHeatmapPoints() {
    if (_filtrados.isEmpty) return [];
    // Radio de ~180m en grados (aprox)
    const radio = 0.0016;
    return _filtrados.map((r) {
      // Contar reportes cercanos (excluyéndose a sí mismo)
      final cercanos = _filtrados.where((o) =>
          o.id != r.id &&
          (o.latitud - r.latitud).abs() < radio &&
          (o.longitud - r.longitud).abs() < radio).length;
      // Escala absoluta: 0-2 seguro, 3-6 bajo, 7-10 medio, >10 alto
      final double intensity;
      if (cercanos <= 2) {
        intensity = 0.15; // seguro
      } else if (cercanos <= 6) {
        intensity = 0.35; // bajo riesgo
      } else if (cercanos <= 10) {
        intensity = 0.65; // riesgo medio
      } else {
        intensity = 1.0;  // alto riesgo
      }
      return HeatmapPoint(LatLng(r.latitud, r.longitud), intensity);
    }).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _navegacionController.close();
    _nuevosReportesController.close();
    super.dispose();
  }
}
