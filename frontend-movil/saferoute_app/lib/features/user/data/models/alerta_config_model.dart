/// Modelo de configuración de alertas del usuario.
class AlertaConfigModel {
  final String? id;
  final String usuarioId;
  final int radioMetros;
  final bool activo;

  const AlertaConfigModel({
    this.id,
    required this.usuarioId,
    required this.radioMetros,
    required this.activo,
  });

  factory AlertaConfigModel.fromJson(Map<String, dynamic> json) {
    return AlertaConfigModel(
      id:          json['id'],
      usuarioId:   json['usuario_id'] ?? '',
      radioMetros: json['radio_metros'] ?? 500,
      activo:      json['activo'] ?? true,
    );
  }

  /// Valores por defecto cuando el usuario aún no tiene configuración.
  factory AlertaConfigModel.defaults(String usuarioId) {
    return AlertaConfigModel(
      usuarioId:   usuarioId,
      radioMetros: 500,
      activo:      true,
    );
  }
}
