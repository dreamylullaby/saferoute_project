import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:civictrackio_app/features/user/presentation/pages/ranking_zonas_page.dart';
import 'package:civictrackio_app/features/user/data/datasources/estadisticas_datasource.dart';

class FakeEstadisticasDatasource extends EstadisticasDatasource {
  FakeEstadisticasDatasource({this.onGetTopZonas});

  final Future<List<Map<String, dynamic>>> Function({
    int top,
    String? fechaDesde,
    String? fechaHasta,
  })? onGetTopZonas;

  List<Map<String, dynamic>> ultimaRespuesta = [];
  int llamadas = 0;
  int? ultimoTop;
  String? ultimaFechaDesde;
  String? ultimaFechaHasta;

  @override
  Future<List<Map<String, dynamic>>> getTopZonas({
    int top = 10,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    llamadas++;
    ultimoTop = top;
    ultimaFechaDesde = fechaDesde;
    ultimaFechaHasta = fechaHasta;

    final result =
        await onGetTopZonas?.call(
              top: top,
              fechaDesde: fechaDesde,
              fechaHasta: fechaHasta,
            ) ??
            <Map<String, dynamic>>[];

    ultimaRespuesta = result;
    return result;
  }
}

Widget buildTestable(Widget child) {
  return MaterialApp(home: child);
}

Finder findExactTextData(String value, {String? description}) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && widget.data == value,
    description: description ?? 'Text("$value")',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(
      fileName: '.env',
      isOptional: true,
      mergeWith: {
        'MAPBOX_TOKEN':
            'pk.eyJ1Ijoic2FyYWhjYWxkZXJvbiIsImEiOiJjbW5tcGp6NW8xbnRtMnJxNDUwODJibnJtIn0.AVoo31Ev683L4GnZFj3qgQ',
        'API_BASE_URL': 'http://localhost:3000',
      },
    );
  });

  group('HU-12 RankingZonasPage', () {
    testWidgets('PI-HU12-01 consulta inicial de zonas con mas hurtos', (
      tester,
    ) async {
      final fake = FakeEstadisticasDatasource(
        onGetTopZonas:
            ({int top = 10, String? fechaDesde, String? fechaHasta}) async {
              return [
                {'barrio': 'Centro', 'comuna': 1, 'total': 12},
                {'barrio': 'San Vicente', 'comuna': 2, 'total': 8},
                {'barrio': 'La Rosa', 'comuna': 3, 'total': 5},
              ];
            },
      );

      await tester.pumpWidget(
        buildTestable(RankingZonasPage(datasource: fake)),
      );

      expect(find.byType(RankingZonasPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      expect(fake.llamadas, 1);
      expect(fake.ultimoTop, 10);
      expect(fake.ultimaFechaDesde, isNull);
      expect(fake.ultimaFechaHasta, isNull);
      expect(fake.ultimaRespuesta.length, 3);

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('San Vicente'), findsOneWidget);
      expect(find.text('La Rosa'), findsOneWidget);

      expect(find.text('Comuna 1'), findsOneWidget);
      expect(find.text('Comuna 2'), findsOneWidget);
      expect(find.text('Comuna 3'), findsOneWidget);

      expect(findExactTextData('12', description: 'total 12'), findsOneWidget);
      expect(findExactTextData('8', description: 'total 8'), findsOneWidget);
      expect(findExactTextData('5', description: 'total 5'), findsWidgets);

      expect(find.text('Sin datos'), findsNothing);
    });

    testWidgets('PI-HU12-02 visualizacion completa de datos por zona', (
      tester,
    ) async {
      final fake = FakeEstadisticasDatasource(
        onGetTopZonas:
            ({int top = 10, String? fechaDesde, String? fechaHasta}) async {
              return [
                {'barrio': 'Centro', 'comuna': 1, 'total': 12},
                {'barrio': 'San Juan', 'comuna': 4, 'total': 7},
              ];
            },
      );

      await tester.pumpWidget(
        buildTestable(RankingZonasPage(datasource: fake)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      expect(fake.llamadas, 1);
      expect(fake.ultimoTop, 10);
      expect(fake.ultimaRespuesta.length, 2);

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('Comuna 1'), findsOneWidget);
      expect(findExactTextData('12', description: 'total 12'), findsOneWidget);

      expect(find.text('San Juan'), findsOneWidget);
      expect(find.text('Comuna 4'), findsOneWidget);
      expect(findExactTextData('7', description: 'total 7'), findsOneWidget);

      expect(find.text('hurtos'), findsNWidgets(2));
      expect(find.text('Sin datos'), findsNothing);
    });

    testWidgets('PI-HU12-03 cambio de top recalcula lista', (tester) async {
      final fake = FakeEstadisticasDatasource(
        onGetTopZonas:
            ({int top = 10, String? fechaDesde, String? fechaHasta}) async {
              if (top == 5) {
                return [
                  {'barrio': 'Centro', 'comuna': 1, 'total': 20},
                  {'barrio': 'San Vicente', 'comuna': 2, 'total': 18},
                ];
              }

              return [
                {'barrio': 'Centro', 'comuna': 1, 'total': 20},
                {'barrio': 'San Vicente', 'comuna': 2, 'total': 18},
                {'barrio': 'La Rosa', 'comuna': 3, 'total': 10},
              ];
            },
      );

      await tester.pumpWidget(
        buildTestable(RankingZonasPage(datasource: fake)),
      );
      await tester.pumpAndSettle();

      expect(fake.llamadas, 1);
      expect(fake.ultimoTop, 10);
      expect(fake.ultimaRespuesta.length, 3);

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('San Vicente'), findsOneWidget);
      expect(find.text('La Rosa'), findsOneWidget);

      expect(findExactTextData('20', description: 'total 20'), findsWidgets);
      expect(findExactTextData('18', description: 'total 18'), findsOneWidget);
      expect(findExactTextData('10', description: 'total 10'), findsWidgets);

      final topFiveFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '5',
        description: 'opcion top 5',
      );

      expect(topFiveFinder, findsWidgets);

      await tester.tap(topFiveFinder.first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fake.ultimoTop, 5);
      expect(fake.llamadas, 2);
      expect(fake.ultimaRespuesta.length, 2);

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('San Vicente'), findsOneWidget);
      expect(find.text('La Rosa'), findsNothing);

      expect(findExactTextData('20', description: 'total 20'), findsWidgets);
      expect(findExactTextData('18', description: 'total 18'), findsOneWidget);
    });

    testWidgets('PI-HU12-04 periodo sin reportes muestra estado vacio', (
      tester,
    ) async {
      final fake = FakeEstadisticasDatasource(
        onGetTopZonas:
            ({int top = 10, String? fechaDesde, String? fechaHasta}) async {
              return [];
            },
      );

      await tester.pumpWidget(
        buildTestable(RankingZonasPage(datasource: fake)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      expect(fake.llamadas, 1);
      expect(fake.ultimoTop, 10);
      expect(fake.ultimaRespuesta, isEmpty);

      expect(find.text('Sin datos'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('Centro'), findsNothing);
      expect(find.text('San Vicente'), findsNothing);
      expect(find.text('La Rosa'), findsNothing);
    });

    testWidgets('PI-HU12-05 muestra top por defecto y opciones de cambio', (
      tester,
    ) async {
      final fake = FakeEstadisticasDatasource(
        onGetTopZonas:
            ({int top = 10, String? fechaDesde, String? fechaHasta}) async {
              return [
                {'barrio': 'Centro', 'comuna': 1, 'total': 12},
              ];
            },
      );

      await tester.pumpWidget(
        buildTestable(RankingZonasPage(datasource: fake)),
      );
      await tester.pumpAndSettle();

      expect(fake.llamadas, 1);
      expect(fake.ultimoTop, 10);
      expect(fake.ultimaRespuesta.length, 1);

      expect(find.text('Mostrar top:'), findsOneWidget);
      expect(findExactTextData('5', description: 'opcion 5'), findsWidgets);
      expect(findExactTextData('10', description: 'opcion 10'), findsWidgets);
      expect(findExactTextData('20', description: 'opcion 20'), findsWidgets);

      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('Hasta'), findsOneWidget);

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('Comuna 1'), findsOneWidget);
      expect(findExactTextData('12', description: 'total 12'), findsOneWidget);
    });
  });
}