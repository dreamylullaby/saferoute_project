import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {

  UserModel({

    required super.id,
    required super.username,
    required super.correo,
    required super.rol

  });

  factory UserModel.fromJson(Map<String,dynamic> json){

    return UserModel(

      id: json["id"].toString(),
      username: json["username"],
      correo: json["correo"],
      rol: json["rol"]

    );

  }

}