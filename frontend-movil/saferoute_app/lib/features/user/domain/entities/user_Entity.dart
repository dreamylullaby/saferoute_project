/// Entidad de dominio que representa un usuario del sistema.
/// Contiene los datos básicos de identidad y rol.
class UserEntity {

  /// UUID único del usuario
  final String id;

  /// Nombre de usuario (apodo)
  final String username;

  /// Correo electrónico registrado
  final String correo;

  /// Rol del usuario: 'usuario' o 'admin'
  final String rol;

  UserEntity({

    required this.id,
    required this.username,
    required this.correo,
    required this.rol

  });

}