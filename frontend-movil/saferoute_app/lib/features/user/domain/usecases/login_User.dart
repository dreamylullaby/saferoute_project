import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class LoginUser {

  final UserRepository repository;

  LoginUser(this.repository);

  Future<UserEntity> call({

    required String correo,
    required String password

  }){

    return repository.login(
      correo: correo,
      password: password
    );

  }

}