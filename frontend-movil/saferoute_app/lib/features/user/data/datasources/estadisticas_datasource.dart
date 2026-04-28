import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../services/auth_storage.dart';

/// Datasource para estadísticas de hurtos por período.
class EstadisticasDatasource {
  final String _base = '${dotenv.env['API_BASE_URL']}/api/reportes';

  Future<Map<String, String>> get _headers async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/reportes/estadisticas
  /// Retorna conteos agrupados por período.
  /// [agruparPor]: 'dia' | 'semana' | 'mes'
  Future<List<Map<String, dynamic>>> getEstadisticasPorPeriodo({
    String? fechaDesde,
    String? fechaHasta,
    String  agruparPor = 'mes',
  }) async {
    final params = <String, String>{'agruparPor': agruparPor};
    if (fechaDesde != null) params['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) params['fechaHasta'] = fechaHasta;

    final uri = Uri.parse('$_base/estadisticas').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception('Error al obtener estadísticas');
  }

  /// GET /api/reportes/estadisticas/comparacion
  /// Compara dos períodos y retorna tendencia.
  Future<Map<String, dynamic>> getComparacion({
    required String p1Desde,
    required String p1Hasta,
    required String p2Desde,
    required String p2Hasta,
  }) async {
    final uri = Uri.parse('$_base/estadisticas/comparacion').replace(
      queryParameters: {
        'p1Desde': p1Desde, 'p1Hasta': p1Hasta,
        'p2Desde': p2Desde, 'p2Hasta': p2Hasta,
      },
    );
    final response = await http.get(uri, headers: await _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data['data']);
    }
    throw Exception('Error al obtener comparación');
  }

  /// GET /api/reportes/zonas/top?top=N&fechaDesde=&fechaHasta=
  /// Retorna el top N de zonas con más hurtos.
  Future<List<Map<String, dynamic>>> getTopZonas({
    int     top        = 10,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final params = <String, String>{'top': top.toString()};
    if (fechaDesde != null) params['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) params['fechaHasta'] = fechaHasta;

    final uri = Uri.parse('$_base/zonas/top').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception('Error al obtener top zonas');
  }

  /// Construye un resumen a partir de los datos del mapa (disponible para usuarios normales).
  /// Usa GET /api/reportes/mapa que retorna: id, latitud, longitud, tipo_hurto, franja_horaria, fecha_incidente, barrio_ingresado, comuna
  Future<Map<String, dynamic>> getResumenUsuario() async {
    final uri = Uri.parse('$_base/mapa');
    final response = await http.get(uri, headers: await _headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final reportes = List<Map<String, dynamic>>.from(body['data']);
      final total = reportes.length;
      final porTipo = <String, int>{};
      final porComuna = <String, int>{};
      final porFranja = <String, int>{};
      final porFecha = <String, int>{};
      final porEstado = <String, int>{'activo': total};
      for (final r in reportes) {
        final tipo = r['tipo_hurto'] as String?;
        final comuna = r['comuna']?.toString();
        final franja = r['franja_horaria'] as String?;
        final fecha = r['fecha_incidente'] as String?;
        if (tipo != null) porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;
        if (comuna != null) porComuna[comuna] = (porComuna[comuna] ?? 0) + 1;
        if (franja != null) porFranja[franja] = (porFranja[franja] ?? 0) + 1;
        if (fecha != null) porFecha[fecha] = (porFecha[fecha] ?? 0) + 1;
      }
      return { 'total': total, 'porTipo': porTipo, 'porComuna': porComuna, 'porFranja': porFranja, 'porFecha': porFecha, 'porEstado': porEstado };
    }
    throw Exception('Error al obtener datos del mapa');
  }

  /// Resumen filtrado usando GET /api/reportes/mapa/filtros
  Future<Map<String, dynamic>> getResumenFiltrado({
    List<int>? comunas,
    List<String>? franjas,
    List<String>? tipos,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final params = <String, String>{};
    if (comunas != null && comunas.isNotEmpty) params['comunas'] = comunas.join(',');
    if (franjas != null && franjas.isNotEmpty) params['franjas'] = franjas.join(',');
    if (tipos != null && tipos.isNotEmpty) params['tipos'] = tipos.join(',');
    if (fechaDesde != null) params['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) params['fechaHasta'] = fechaHasta;

    final uri = Uri.parse('$_base/mapa/filtros').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final reportes = List<Map<String, dynamic>>.from(body['data']);
      final total = reportes.length;
      final porTipo = <String, int>{};
      final porComuna = <String, int>{};
      final porFranja = <String, int>{};
      final porFecha = <String, int>{};
      for (final r in reportes) {
        final tipo = r['tipo_hurto'] as String?;
        final comuna = r['comuna']?.toString();
        final franja = r['franja_horaria'] as String?;
        final fecha = r['fecha_incidente'] as String?;
        if (tipo != null) porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;
        if (comuna != null) porComuna[comuna] = (porComuna[comuna] ?? 0) + 1;
        if (franja != null) porFranja[franja] = (porFranja[franja] ?? 0) + 1;
        if (fecha != null) porFecha[fecha] = (porFecha[fecha] ?? 0) + 1;
      }
      return { 'total': total, 'porTipo': porTipo, 'porComuna': porComuna, 'porFranja': porFranja, 'porFecha': porFecha, 'porEstado': {'activo': total} };
    }
    throw Exception('Error al obtener datos filtrados');
  }
}
