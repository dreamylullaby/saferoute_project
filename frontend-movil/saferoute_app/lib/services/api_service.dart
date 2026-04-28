import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio base de API con Dio.
/// Configura la URL base del backend para todas las peticiones HTTP.
class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
    ),
  );
}
