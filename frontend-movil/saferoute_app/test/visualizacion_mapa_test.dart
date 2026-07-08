import 'package:flutter_test/flutter_test.dart';
import 'package:civictrackio_app/features/user/data/models/reporte_mapa_model.dart';

void main() {
  group('HU-08 Modelo - ReporteMapaModel', () {
    test('CP-HU08-01: Obtener reportes para mapa', () {
      final json = {
        'id': 'r1',
        'latitud': 1.2136,
        'longitud': -77.2811,
        'tipo_hurto': 'atraco',
        'franja_horaria': '18:00-23:59',
        'fecha_incidente': '2026-04-14',
        'barrio_ingresado': 'Centro',
        'comuna': 5,
      };

      final model = ReporteMapaModel.fromJson(json);

      expect(model.id, 'r1');
      expect(model.latitud, 1.2136);
      expect(model.longitud, -77.2811);
      expect(model.tipoHurto, 'atraco');
      expect(model.franjaHoraria, '18:00-23:59');
      expect(model.fechaIncidente, '2026-04-14');
      expect(model.barrioIngresado, 'Centro');
      expect(model.comuna, 5);

      print('Resultado: OK');
    });

    test('CP-HU08-02: Obtener reportes filtrados', () {
      final json = {
        'id': 'r2',
        'latitud': 1.2140,
        'longitud': -77.2820,
        'tipo_hurto': 'cosquilleo',
        'franja_horaria': '06:00-11:59',
        'fecha_incidente': '2026-04-10',
        'barrio_ingresado': 'Palermo',
        'comuna': 2,
      };

      final model = ReporteMapaModel.fromJson(json);

      expect(model.tipoHurto, 'cosquilleo');
      expect(model.comuna, 2);
      expect(model.barrioIngresado, 'Palermo');

      print('Resultado: OK');
    });

    test('CP-HU08-03: Obtener reportes nuevos', () {
      final json = {
        'id': 'r3',
        'latitud': 1.2150,
        'longitud': -77.2830,
        'tipo_hurto': 'fleteo',
        'franja_horaria': '12:00-17:59',
        'fecha_incidente': '2026-04-14',
        'barrio_ingresado': 'Santiago',
        'comuna': 4,
      };

      final model = ReporteMapaModel.fromJson(json);

      expect(model.id, 'r3');
      expect(model.tipoHurto, 'fleteo');
      expect(model.fechaIncidente, '2026-04-14');

      print('Resultado: OK');
    });
  });
}