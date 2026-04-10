import '../entities/user_Entity.dart';
import '../repositories/user_Repository.dart';

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