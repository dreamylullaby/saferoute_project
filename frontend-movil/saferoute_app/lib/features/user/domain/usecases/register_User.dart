import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

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
