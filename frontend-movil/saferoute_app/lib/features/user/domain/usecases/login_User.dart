import '../entities/user_Entity.dart';
import '../repositories/user_Repository.dart';

/// Caso de uso para autenticación de usuario.
/// Delega al repositorio la verificación de credenciales.
class LoginUser {

  final UserRepository repository;

  LoginUser(this.repository);

  /// Ejecuta el login con correo y contraseña.
  /// Retorna [UserEntity] si la autenticación es exitosa.
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