import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../services/auth_storage.dart';

/// Datasource remoto para el perfil de usuario.
class PerfilDatasource {
  static const _baseUrl = 'http://localhost:3000/api/perfil';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene los datos del perfil del usuario autenticado.
  Future<Map<String, dynamic>> getPerfil() async {
    final res = await http.get(Uri.parse(_baseUrl), headers: await _headers());
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Error al obtener perfil');
  }

  /// Actualiza username y/o foto_url.
  Future<Map<String, dynamic>> updatePerfil({String? username, String? fotoUrl}) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (fotoUrl != null) body['foto_url'] = fotoUrl;

    final res = await http.patch(
      Uri.parse(_baseUrl),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data['data'];
    throw Exception(data['message'] ?? 'Error al actualizar perfil');
  }

  /// Activa o desactiva las notificaciones.
  Future<void> toggleNotificaciones(bool activo) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/notificaciones'),
      headers: await _headers(),
      body: jsonEncode({'activo': activo}),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Error al actualizar notificaciones');
    }
  }
}
