import '../entities/user_Entity.dart';

abstract class UserRepository {

  Future<UserEntity> login({
    required String correo,
    required String password
  });

  Future<UserEntity> register({
    required String username,
    required String correo,
    required String password
  });

}