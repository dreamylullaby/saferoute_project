import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alerta_config_model.dart';
import '../../../../services/auth_storage.dart';

/// Datasource para el módulo de alertas por proximidad.
/// Consume los endpoints de /api/alertas
class AlertaConfigDatasource {
  final String _base = 'http://localhost:3000/api/alertas';

  Future<Map<String, String>> get _headers async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/alertas/configuracion
  /// Retorna la configuración actual o los valores por defecto.
  Future<AlertaConfigModel> getConfig() async {
    final response = await http.get(
      Uri.parse('$_base/configuracion'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AlertaConfigModel.fromJson(data['data']);
    }
    throw Exception('Error al obtener configuración de alertas');
  }

  /// PUT /api/alertas/configuracion
  /// Guarda o actualiza el radio y estado de alertas.
  Future<AlertaConfigModel> saveConfig({
    required int radioMetros,
    required bool activo,
  }) async {
    final response = await http.put(
      Uri.parse('$_base/configuracion'),
      headers: await _headers,
      body: jsonEncode({'radio_metros': radioMetros, 'activo': activo}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AlertaConfigModel.fromJson(data['data']);
    }
    final msg = jsonDecode(response.body)['message'] ?? 'Error al guardar';
    throw Exception(msg);
  }

  /// GET /api/alertas?lat=&lng=
  /// Retorna reportes cercanos según la ubicación actual del usuario.
  Future<List<Map<String, dynamic>>> getAlertasCercanas({
    required double latitud,
    required double longitud,
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'lat': latitud.toString(),
      'lng': longitud.toString(),
    });
    final response = await http.get(uri, headers: await _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']['alertas']);
    }
    throw Exception('Error al obtener alertas cercanas');
  }
}
