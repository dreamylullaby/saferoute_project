import '../entities/user_Entity.dart';
import '../repositories/user_Repository.dart';

class RegisterUser {

  final UserRepository repository;

  RegisterUser(this.repository);

  Future<UserEntity> call({
    required String username,
    required String correo,
    required String password
  }) {
    return repository.register(
      username: username,
      correo: correo,
      password: password
    );
  }

}
