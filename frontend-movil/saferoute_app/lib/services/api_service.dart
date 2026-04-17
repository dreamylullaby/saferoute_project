import 'package:dio/dio.dart';

/// Servicio base de API con Dio.
/// Configura la URL base del backend para todas las peticiones HTTP.
class ApiService {
 final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:3000"
    )
  );
}