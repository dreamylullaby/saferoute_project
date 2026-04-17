import '../../domain/entities/user_Entity.dart';

/// Modelo de datos del usuario que extiende la entidad de dominio.
/// Maneja la serialización desde JSON (respuesta del backend).
class UserModel extends UserEntity {

  UserModel({

    required super.id,
    required super.username,
    required super.correo,
    required super.rol

  });

  /// Crea una instancia de [UserModel] a partir del JSON del backend.
  /// Espera las claves: id, username, correo, rol.
  factory UserModel.fromJson(Map<String,dynamic> json){

    return UserModel(

      id: json["id"].toString(),
      username: json["username"],
      correo: json["correo"],
      rol: json["rol"]

    );

  }

}