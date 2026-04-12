import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento del token JWT usando SharedPreferences.
class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _tokenTimestampKey = 'token_timestamp';

  /// Tiempo máximo de inactividad antes de invalidar el token (en minutos).
  static const int inactivityTimeoutMinutes = 30;

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_tokenTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Devuelve el token solo si no ha expirado por inactividad.
  /// Si expiró, limpia el storage y retorna null.
  static Future<String?> getValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;

    final timestamp = prefs.getInt(_tokenTimestampKey);
    if (timestamp == null) {
      await clear();
      return null;
    }

    final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (elapsed > inactivityTimeoutMinutes * 60 * 1000) {
      await clear();
      return null;
    }

    return token;
  }

  /// Actualiza el timestamp de actividad (llamar en cada interacción).
  static Future<void> refreshActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      await prefs.setInt(_tokenTimestampKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  static Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, id);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_tokenTimestampKey);
  }
}
