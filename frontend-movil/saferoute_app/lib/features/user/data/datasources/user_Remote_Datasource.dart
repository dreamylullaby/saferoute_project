import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../../../../services/auth_storage.dart';

class UserRemoteDatasource {
  final String baseUrl = "${dotenv.env['API_BASE_URL']}/api/auth";

  Future<UserModel> login({required String correo, required String password}) async {
    final response = await http.post(Uri.parse("$baseUrl/login"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"correo": correo, "password": password}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await AuthStorage.saveToken(data["token"]);
      await AuthStorage.saveUserId(data["user"]["id"].toString());
      return UserModel.fromJson(data["user"]);
    } else { throw Exception("Error login"); }
  }

  Future<UserModel> loginWithGoogle({required String idToken}) async {
    final response = await http.post(Uri.parse("$baseUrl/google"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"idToken": idToken}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await AuthStorage.saveToken(data["token"]);
      await AuthStorage.saveUserId(data["user"]["id"].toString());
      return UserModel.fromJson(data["user"]);
    } else {
      print("Google login error - Status: ${response.statusCode}, Body: ${response.body}");
      throw Exception("Error login Google: ${response.statusCode} - ${response.body}");
    }
  }

  Future<UserModel> register({required String username, required String correo, required String password}) async {
    final response = await http.post(Uri.parse("$baseUrl/register"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"username": username, "correo": correo, "password": password}));
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

  Future<void> logout() async {
    final token = await AuthStorage.getToken();
    if (token != null) {
      try { await http.patch(Uri.parse("$baseUrl/fcm-token"), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"fcm_token": ""})); } catch (_) {}
      await http.post(Uri.parse("$baseUrl/logout"), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});
    }
    await AuthStorage.clear();
  }

  Future<void> registrarFcmToken() async {
    try {
      final jwtToken = await AuthStorage.getToken();
      if (jwtToken == null) return;
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await http.patch(Uri.parse("$baseUrl/fcm-token"), headers: {"Content-Type": "application/json", "Authorization": "Bearer $jwtToken"}, body: jsonEncode({"fcm_token": fcmToken}));
    } catch (_) {}
  }

  /// POST /auth/forgot-password — usa plataforma: "app" para deep link
  Future<void> forgotPassword(String correo) async {
    final response = await http.post(Uri.parse("$baseUrl/forgot-password"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"correo": correo, "plataforma": "web"}));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data["message"] ?? "Error al procesar la solicitud");
    }
  }

  /// POST /auth/reset-password — usa nuevaPassword como nombre del campo
  Future<void> resetPassword(String token, String nuevaPassword) async {
    final response = await http.post(Uri.parse("$baseUrl/reset-password"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"token": token, "nuevaPassword": nuevaPassword}));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data["message"] ?? "Error al restablecer la contraseña");
    }
  }
}
