import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:civictrackio_app/features/user/data/datasources/alerta_config_datasource.dart';
import 'package:civictrackio_app/features/user/data/models/alerta_config_model.dart';
import 'package:civictrackio_app/features/user/presentation/pages/alerta_config_page.dart';
import 'package:civictrackio_app/services/location_service.dart';

class MockAlertaConfigDatasource extends Mock implements AlertaConfigDatasource {}
class MockLocationService extends Mock implements LocationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAlertaConfigDatasource datasource;
  late MockLocationService locationService;

  setUp(() {
    datasource = MockAlertaConfigDatasource();
    locationService = MockLocationService();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlertaConfigPage(
          datasource: datasource,
          locationService: locationService,
        ),
      ),
    );
  }

  Position fakePosition({
    double latitude = 1.2136,
    double longitude = -77.2811,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 1,
      altitudeAccuracy: 1,
      heading: 1,
      headingAccuracy: 1,
      speed: 1,
      speedAccuracy: 1,
    );
  }

  group('HU-07 Frontend - Cobertura completa', () {
    testWidgets('CP-HU07-01: Configuración y radio', (tester) async {
      final model = AlertaConfigModel.fromJson({
        'id': 'cfg-1',
        'usuario_id': 'user-1',
        'radio_metros': 1200,
        'activo': true,
      });

      expect(model.radioMetros, 1200);
      expect(model.activo, true);

      when(() => datasource.getConfig()).thenAnswer((_) async => model);
      when(() => locationService.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => locationService.getCurrentPosition())
          .thenAnswer((_) async => fakePosition());
      when(() => datasource.getAlertasCercanas(
            latitud: any(named: 'latitud'),
            longitud: any(named: 'longitud'),
          )).thenAnswer((_) async => []);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('1200 metros'), findsOneWidget);

      await tester.tap(find.text('Ver alertas cercanas ahora'));
      await tester.pumpAndSettle();

      verify(() => locationService.getCurrentPosition()).called(1);
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-02: GPS y permiso denegado', (tester) async {
      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: true,
        ),
      );

      when(() => locationService.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver alertas cercanas ahora'));
      await tester.pumpAndSettle();

      expect(
        find.text('Se necesita permiso de ubicación para las alertas'),
        findsOneWidget,
      );
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-03: Guardar configuración', (tester) async {
      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: true,
        ),
      );

      when(() => datasource.saveConfig(
            radioMetros: any(named: 'radioMetros'),
            activo: any(named: 'activo'),
          )).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: true,
        ),
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar configuración'));
      await tester.pumpAndSettle();

      expect(find.text('Configuración guardada'), findsOneWidget);
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-04: Error al guardar', (tester) async {
      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: true,
        ),
      );

      when(() => datasource.saveConfig(
            radioMetros: any(named: 'radioMetros'),
            activo: any(named: 'activo'),
          )).thenThrow(Exception('Error al guardar'));

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar configuración'));
      await tester.pumpAndSettle();

      expect(find.text('Error al guardar'), findsOneWidget);
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-05: Sin alertas cercanas', (tester) async {
      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: true,
        ),
      );

      when(() => locationService.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => locationService.getCurrentPosition())
          .thenAnswer((_) async => fakePosition());
      when(() => datasource.getAlertasCercanas(
            latitud: any(named: 'latitud'),
            longitud: any(named: 'longitud'),
          )).thenAnswer((_) async => []);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver alertas cercanas ahora'));
      await tester.pumpAndSettle();

      expect(find.text('Sin reportes cercanos'), findsOneWidget);
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-06: Con alertas cercanas', (tester) async {
      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: true,
        ),
      );

      when(() => locationService.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => locationService.getCurrentPosition())
          .thenAnswer((_) async => fakePosition());
      when(() => datasource.getAlertasCercanas(
            latitud: any(named: 'latitud'),
            longitud: any(named: 'longitud'),
          )).thenAnswer(
        (_) async => [
          {
            'tipo_hurto': 'Atraco',
            'barrio_ingresado': 'Centro',
            'distancia_metros': 120,
          },
          {
            'tipo_hurto': 'Cosquilleo',
            'barrio_ingresado': 'San Juan',
            'distancia_metros': 300,
          },
        ],
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver alertas cercanas ahora'));
      await tester.pumpAndSettle();

      expect(find.text('2 reporte(s) en tu radio'), findsOneWidget);
      expect(find.text('Atraco en Centro'), findsOneWidget);
      expect(find.text('Cosquilleo en San Juan'), findsOneWidget);
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-07: Alertas desactivadas por el usuario', (tester) async {
      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: false,
        ),
      );

      when(() => datasource.saveConfig(
            radioMetros: any(named: 'radioMetros'),
            activo: any(named: 'activo'),
          )).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: false,
        ),
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('500 metros'), findsOneWidget);
      await tester.tap(find.text('Guardar configuración'));
      await tester.pumpAndSettle();

      expect(find.text('Configuración guardada'), findsOneWidget);
      verifyNever(() => datasource.getAlertasCercanas(
            latitud: any(named: 'latitud'),
            longitud: any(named: 'longitud'),
          ));
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-08: Permiso revocado luego de configurar', (tester) async {
      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 500,
          activo: true,
        ),
      );

      when(() => locationService.requestPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver alertas cercanas ahora'));
      await tester.pumpAndSettle();

      expect(
        find.text('Se necesita permiso de ubicación para las alertas'),
        findsOneWidget,
      );
      print('Resultado: OK');
    });

    testWidgets('CP-HU07-09: Notificación visible al recibir evento cercano',
        (tester) async {
      // print('CP-HU07-09 - Notificación visible al recibir evento cercano');
      // print('Entrada: evento de hurto dentro del radio y alertas activas');
      // print('Esperado: el usuario visualiza la alerta correspondiente');

      when(() => datasource.getConfig()).thenAnswer(
        (_) async => AlertaConfigModel(
          id: 'cfg-1',
          usuarioId: 'user-1',
          radioMetros: 200,
          activo: true,
        ),
      );

      when(() => locationService.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);

      when(() => locationService.getCurrentPosition())
          .thenAnswer((_) async => fakePosition());

      when(() => datasource.getAlertasCercanas(
            latitud: any(named: 'latitud'),
            longitud: any(named: 'longitud'),
          )).thenAnswer(
        (_) async => [
          {
            'tipo_hurto': 'Atraco',
            'barrio_ingresado': 'Centro',
            'distancia_metros': 120,
            'hora': '22:00',
          }
        ],
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver alertas cercanas ahora'));
      await tester.pumpAndSettle();

      expect(find.text('1 reporte(s) en tu radio'), findsOneWidget);
      expect(find.text('Atraco en Centro'), findsOneWidget);

      print('Resultado: OK');
    });
  });
}