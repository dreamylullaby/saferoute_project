import '../entities/user_entity.dart';

abstract class UserRepository {

  Future<UserEntity> login({

    required String correo,
    required String password

  });

}