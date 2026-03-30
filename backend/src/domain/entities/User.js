/**
 * Entidad de dominio que representa un usuario del sistema.
 * @class User
 */
class User {

  /**
   * Constructor de la entidad User.
   * @param {Object} data - Datos del usuario
   * @param {string} data.id - Identificador único UUID del usuario
   * @param {string} data.username - Nombre de usuario único
   * @param {string} data.correo - Correo electrónico único
   * @param {string|null} data.password_hash - Hash bcrypt de la contraseña (null si es Google)
   * @param {string|null} data.foto_url - URL de la foto de perfil (opcional)
   * @param {string} data.rol - Rol del usuario ('usuario' | 'admin')
   * @param {string} data.auth_provider - Proveedor de autenticación ('local' | 'google')
   * @param {string|null} data.google_id - UID de Google (null si es local)
   * @param {string} data.estado - Estado de la cuenta ('activo' | 'bloqueado')
   * @param {Date} data.fecha_creacion - Fecha de creación del registro
   */
  constructor({
    id,
    username,
    correo,
    password_hash,
    foto_url,
    rol,
    auth_provider,
    google_id,
    estado,
    fecha_creacion
  }) {
    this.id = id;
    this.username = username;
    this.correo = correo;
    this.password_hash = password_hash;
    this.foto_url = foto_url;
    this.google_id = google_id;
    this.rol = rol;
    this.auth_provider = auth_provider;
    this.estado = estado;
    this.fecha_creacion = fecha_creacion;
  }

}

export default User;
