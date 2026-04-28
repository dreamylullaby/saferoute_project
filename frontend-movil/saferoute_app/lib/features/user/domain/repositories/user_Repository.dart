import '../entities/user_Entity.dart';

/// Contrato del repositorio de usuarios.
/// Define las operaciones de autenticación que debe implementar
/// cualquier fuente de datos (remota, local, mock).
abstract class UserRepository {

  /// Autentica un usuario con correo y contraseña.
  /// Retorna la entidad [UserEntity] si las credenciales son válidas.
  Future<UserEntity> login({
    required String correo,
    required String password
  });

  /// Registra un nuevo usuario local.
  /// Retorna la entidad [UserEntity] del usuario creado.
  Future<UserEntity> register({
    required String username,
    required String correo,
    required String password
  });

}