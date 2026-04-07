import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reporte_mapa_model.dart';
import '../../../../services/auth_storage.dart';

class ReporteMapaDatasource {
  final String baseUrl = 'http://localhost:3000/api/reportes';

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene todos los reportes activos para el mapa.
  Future<List<ReporteMapaModel>> getReportesParaMapa() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mapa'),
      headers: await _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((e) => ReporteMapaModel.fromJson(e))
          .toList();
    }
    throw Exception('Error al cargar reportes del mapa');
  }

  /// Obtiene reportes nuevos desde [desde] (ISO 8601).
  /// Usado para actualización automática cada minuto.
  Future<List<ReporteMapaModel>> getReportesNuevos(String desde) async {
    final uri = Uri.parse('$baseUrl/mapa/nuevos').replace(
      queryParameters: {'desde': desde},
    );
    final response = await http.get(uri, headers: await _authHeaders);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((e) => ReporteMapaModel.fromJson(e))
          .toList();
    }
    throw Exception('Error al cargar reportes nuevos');
  }
}
