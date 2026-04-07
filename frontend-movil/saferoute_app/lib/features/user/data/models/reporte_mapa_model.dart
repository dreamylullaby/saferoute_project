/// Modelo liviano de reporte para pintar marcadores en el mapa.
/// Solo contiene los campos necesarios para la visualización.
class ReporteMapaModel {
  final String id;
  final double latitud;
  final double longitud;
  final String tipoHurto;
  final String franjaHoraria;
  final String fechaIncidente;
  final String barrioIngresado;
  final int? comuna;

  const ReporteMapaModel({
    required this.id,
    required this.latitud,
    required this.longitud,
    required this.tipoHurto,
    required this.franjaHoraria,
    required this.fechaIncidente,
    required this.barrioIngresado,
    this.comuna,
  });

  factory ReporteMapaModel.fromJson(Map<String, dynamic> json) {
    return ReporteMapaModel(
      id:              json['id'] as String,
      latitud:         (json['latitud'] as num).toDouble(),
      longitud:        (json['longitud'] as num).toDouble(),
      tipoHurto:       json['tipo_hurto'] as String,
      franjaHoraria:   json['franja_horaria'] as String,
      fechaIncidente:  json['fecha_incidente'] as String,
      barrioIngresado: json['barrio_ingresado'] as String,
      comuna:          json['comuna'] as int?,
    );
  }
}
