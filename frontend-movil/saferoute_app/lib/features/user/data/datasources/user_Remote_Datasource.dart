import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../../../../services/auth_storage.dart';

/// Datasource remoto para autenticación de usuarios.
/// Consume los endpoints de /api/auth del backend.
class UserRemoteDatasource {

  final String baseUrl = "${dotenv.env['API_BASE_URL']}/api/auth";

  /// Autentica un usuario local con correo y contraseña.
  /// Guarda el token JWT y el userId en almacenamiento local.
  /// Retorna [UserModel] con los datos del usuario autenticado.
  Future<UserModel> login({
    required String correo,
    required String password
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await AuthStorage.saveToken(data["token"]);
      await AuthStorage.saveUserId(data["user"]["id"].toString());
      return UserModel.fromJson(data["user"]);
    } else {
      throw Exception("Error login");
    }
  }

  /// Autentica un usuario mediante Google Sign-In.
  /// Recibe el idToken de Firebase Auth y lo envía al backend.
  /// Guarda el token JWT y el userId en almacenamiento local.
  Future<UserModel> loginWithGoogle({required String idToken}) async {

    final response = await http.post(
      Uri.parse("$baseUrl/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idToken": idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await AuthStorage.saveToken(data["token"]);
      await AuthStorage.saveUserId(data["user"]["id"].toString());
      return UserModel.fromJson(data["user"]);
    } else {
      throw Exception("Error login Google");
    }
  }

  /// Registra un nuevo usuario local con username, correo y contraseña.
  /// Guarda el token JWT y el userId en almacenamiento local.
  /// Lanza excepción con el mensaje del backend si falla.
  Future<UserModel> register({
    required String username,
    required String correo,
    required String password
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "correo": correo, "password": password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await AuthStorage.saveToken(data["token"]);
      await AuthStorage.saveUserId(data["user"]["id"].toString());
      return UserModel.fromJson(data["user"]);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data["message"] ?? "Error al registrar");
    }
  }

  /// Cierra sesión del usuario.
  /// Limpia el FCM token en el backend para dejar de recibir push,
  /// llama al endpoint de logout y limpia el almacenamiento local.
  Future<void> logout() async {
    final token = await AuthStorage.getToken();
    if (token != null) {
      // Limpiar FCM token en la BD antes de cerrar sesión
      try {
        await http.patch(
          Uri.parse("$baseUrl/fcm-token"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"fcm_token": ""}),
        );
      } catch (_) {}

      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
    }
    await AuthStorage.clear();
  }

  /// Obtiene el FCM token del dispositivo y lo registra en el backend.
  /// Se llama después de cada login exitoso.
  Future<void> registrarFcmToken() async {
    try {
      final jwtToken = await AuthStorage.getToken();
      if (jwtToken == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      await http.patch(
        Uri.parse("$baseUrl/fcm-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({"fcm_token": fcmToken}),
      );
    } catch (_) {
      // Silencioso — no interrumpe el flujo de login
    }
  }

  /// Solicita recuperación de contraseña enviando correo con enlace.
  Future<void> forgotPassword(String correo) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo, "plataforma": "app"}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data["message"] ?? "Error al procesar la solicitud");
    }
  }

  /// Restablece la contraseña usando el token recibido por correo.
  Future<void> resetPassword(String token, String nuevaPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token, "nuevaPassword": nuevaPassword}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data["message"] ?? "Error al restablecer la contraseña");
    }
  }
}