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
}
