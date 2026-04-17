import '../entities/user_Entity.dart';
import '../repositories/user_Repository.dart';

/// Caso de uso para registro de nuevo usuario.
/// Delega al repositorio la creación de la cuenta.
class RegisterUser {

  final UserRepository repository;

  RegisterUser(this.repository);

  /// Ejecuta el registro con username, correo y contraseña.
  /// Retorna [UserEntity] del usuario creado.
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
