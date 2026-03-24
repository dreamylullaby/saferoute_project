import 'package:dio/dio.dart';

class ApiService {
 final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:3000"
    )
  );
}