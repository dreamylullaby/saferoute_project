// src/domain/entities/User.js
class User {

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

    // opcionales dependiendo del tipo de login
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