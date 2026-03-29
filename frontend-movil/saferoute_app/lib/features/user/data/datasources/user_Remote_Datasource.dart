import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class UserRemoteDatasource {

  final String baseUrl = "http://localhost:3000/api/auth";

  Future<UserModel> login({

    required String correo,
    required String password

  }) async {

    final response = await http.post(

      Uri.parse("$baseUrl/login"),

      headers: {
        "Content-Type": "application/json"
      },

      body: jsonEncode({

        "correo": correo,
        "password": password

      }),

    );

    if(response.statusCode == 200){

      final data = jsonDecode(response.body);

      return UserModel.fromJson(data["user"]);

    }else{

      throw Exception("Error login");

    }

  }

  Future<UserModel> loginWithGoogle({required String idToken}) async {

    final response = await http.post(

      Uri.parse("$baseUrl/google"),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode({"idToken": idToken}),

    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return UserModel.fromJson(data["user"]);

    } else {

      throw Exception("Error login Google");

    }

  }

}