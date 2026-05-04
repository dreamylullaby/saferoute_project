import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../services/auth_storage.dart';

/// Datasource remoto para el perfil de usuario.
class PerfilDatasource {
  static final _baseUrl = '${dotenv.env['API_BASE_URL']}/api/perfil';

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
    final res = await http.put(
      Uri.parse('$_baseUrl/notificaciones'),
      headers: await _headers(),
      body: jsonEncode({'activo': activo}),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Error al actualizar notificaciones');
    }
  }

  /// Cambia la contraseña del usuario autenticado (solo auth_provider = 'local').
  Future<void> cambiarPassword({required String passwordActual, required String nuevaPassword}) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/password'),
      headers: await _headers(),
      body: jsonEncode({'passwordActual': passwordActual, 'nuevaPassword': nuevaPassword}),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Error al cambiar contraseña');
    }
  }

  /// Elimina la cuenta del usuario autenticado.
  /// Para usuarios locales requiere [password].
  Future<void> eliminarCuenta({String? password}) async {
    final body = <String, dynamic>{};
    if (password != null && password.isNotEmpty) body['password'] = password;

    final res = await http.delete(
      Uri.parse(_baseUrl),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Error al eliminar cuenta');
    }
  }
}
