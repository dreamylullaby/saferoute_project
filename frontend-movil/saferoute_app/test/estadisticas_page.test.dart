import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saferoute_app/features/user/presentation/pages/estadisticas_page.dart';
import 'package:saferoute_app/features/user/data/datasources/estadisticas_datasource.dart';

class FakeEstadisticasDatasource extends EstadisticasDatasource {
  FakeEstadisticasDatasource({
    this.onGetResumenUsuario,
    this.onGetResumenFiltrado,
    this.onGetComparacion,
    this.onGetTopZonas,
  });

  final Future<Map<String, dynamic>> Function()? onGetResumenUsuario;
  final Future<Map<String, dynamic>> Function({
    List<int>? comunas,
    List<String>? franjas,
    List<String>? tipos,
    String? fechaDesde,
    String? fechaHasta,
  })? onGetResumenFiltrado;
  final Future<Map<String, dynamic>> Function({
    required String p1Desde,
    required String p1Hasta,
    required String p2Desde,
    required String p2Hasta,
  })? onGetComparacion;
  final Future<List<Map<String, dynamic>>> Function({
    int top,
    String? fechaDesde,
    String? fechaHasta,
  })? onGetTopZonas;

  int llamadasResumenUsuario = 0;
  int llamadasResumenFiltrado = 0;
  int llamadasComparacion = 0;
  int llamadasTopZonas = 0;

  List<int>? ultimaComunas;
  List<String>? ultimasFranjas;
  List<String>? ultimosTipos;
  String? ultimaFechaDesde;
  String? ultimaFechaHasta;

  String? ultimoP1Desde;
  String? ultimoP1Hasta;
  String? ultimoP2Desde;
  String? ultimoP2Hasta;

  int? ultimoTop;

  @override
  Future<Map<String, dynamic>> getResumenUsuario() async {
    llamadasResumenUsuario++;
    if (onGetResumenUsuario != null) return await onGetResumenUsuario!();
    return {
      'total': 0,
      'porTipo': <String, int>{},
      'porComuna': <String, int>{},
      'porFranja': <String, int>{},
      'porFecha': <String, int>{},
      'porEstado': {'activo': 0},
    };
  }

  @override
  Future<Map<String, dynamic>> getResumenFiltrado({
    List<int>? comunas,
    List<String>? franjas,
    List<String>? tipos,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    llamadasResumenFiltrado++;
    ultimaComunas = comunas;
    ultimasFranjas = franjas;
    ultimosTipos = tipos;
    ultimaFechaDesde = fechaDesde;
    ultimaFechaHasta = fechaHasta;

    if (onGetResumenFiltrado != null) {
      return await onGetResumenFiltrado!(
        comunas: comunas,
        franjas: franjas,
        tipos: tipos,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
    }

    return {
      'total': 0,
      'porTipo': <String, int>{},
      'porComuna': <String, int>{},
      'porFranja': <String, int>{},
      'porFecha': <String, int>{},
      'porEstado': {'activo': 0},
    };
  }

  @override
  Future<Map<String, dynamic>> getComparacion({
    required String p1Desde,
    required String p1Hasta,
    required String p2Desde,
    required String p2Hasta,
  }) async {
    llamadasComparacion++;
    ultimoP1Desde = p1Desde;
    ultimoP1Hasta = p1Hasta;
    ultimoP2Desde = p2Desde;
    ultimoP2Hasta = p2Hasta;

    if (onGetComparacion != null) {
      return await onGetComparacion!(
        p1Desde: p1Desde,
        p1Hasta: p1Hasta,
        p2Desde: p2Desde,
        p2Hasta: p2Hasta,
      );
    }

    return {
      'periodo1': {'desde': p1Desde, 'hasta': p1Hasta, 'total': 0, 'porTipo': {}},
      'periodo2': {'desde': p2Desde, 'hasta': p2Hasta, 'total': 0, 'porTipo': {}},
      'diferencia': 0,
      'porcentaje': '0.0',
      'tendencia': 'estable',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTopZonas({
    int top = 10,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    llamadasTopZonas++;
    ultimoTop = top;
    ultimaFechaDesde = fechaDesde;
    ultimaFechaHasta = fechaHasta;

    if (onGetTopZonas != null) {
      return await onGetTopZonas!(
        top: top,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
    }

    return [];
  }
}

Widget buildTestable(Widget child) {
  return MaterialApp(home: child);
}

Finder exactText(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && widget.data == value,
    description: 'Text("$value")',
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

  group('HU-11 EstadisticasPage', () {
    testWidgets(
      'CP-HU11-01 visualiza estadisticas semanales adaptadas por rango de fechas',
      (tester) async {
        final fake = FakeEstadisticasDatasource(
          onGetResumenUsuario: () async => {
            'total': 6,
            'porTipo': {'atraco': 2, 'raponazo': 1, 'fleteo': 2, 'cosquilleo': 1},
            'porComuna': {'1': 4, '2': 2},
            'porFranja': {'18:00-23:59': 3, '06:00-11:59': 1},
            'porFecha': {'2026-04-26': 1, '2026-04-27': 2, '2026-04-28': 3},
            'porEstado': {'activo': 6},
          },
          onGetComparacion: ({
            required String p1Desde,
            required String p1Hasta,
            required String p2Desde,
            required String p2Hasta,
          }) async => {
            'periodo1': {'desde': p1Desde, 'hasta': p1Hasta, 'total': 4, 'porTipo': {}},
            'periodo2': {'desde': p2Desde, 'hasta': p2Hasta, 'total': 6, 'porTipo': {}},
            'diferencia': 2,
            'porcentaje': '50.0',
            'tendencia': 'incremento',
          },
          onGetTopZonas: ({int top = 5, String? fechaDesde, String? fechaHasta}) async => [
            {'barrio': 'Centro', 'comuna': 1, 'total': 4},
            {'barrio': 'San Juan', 'comuna': 2, 'total': 2},
          ],
        );

        await tester.pumpWidget(buildTestable(EstadisticasPage(datasource: fake)));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle();

        expect(fake.llamadasResumenUsuario, 1);
        expect(fake.llamadasComparacion, 1);
        expect(fake.llamadasTopZonas, 1);
        expect(fake.ultimoTop, 5);

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Estadísticas'), findsOneWidget);
        expect(find.text('Filtros'), findsOneWidget);
        expect(find.text('Total de incidentes'), findsOneWidget);
        expect(exactText('6'), findsOneWidget);
        expect(find.text('Zona más peligrosa'), findsOneWidget);
        expect(find.text('Horario más peligroso'), findsOneWidget);
        expect(find.text('Comuna 1'), findsOneWidget);
        expect(find.text('Noche (18:00-23:59)'), findsOneWidget);
      },
    );

    testWidgets(
      'CP-HU11-02 visualiza estadisticas mensuales adaptadas por rango mensual',
      (tester) async {
        final fake = FakeEstadisticasDatasource(
          onGetResumenUsuario: () async => {
            'total': 18,
            'porTipo': {'atraco': 8, 'raponazo': 4, 'fleteo': 3, 'cosquilleo': 3},
            'porComuna': {'3': 10, '4': 8},
            'porFranja': {'12:00-17:59': 9, '18:00-23:59': 6},
            'porFecha': {'2026-04-01': 2, '2026-04-10': 7, '2026-04-20': 9},
            'porEstado': {'activo': 18},
          },
          onGetComparacion: ({
            required String p1Desde,
            required String p1Hasta,
            required String p2Desde,
            required String p2Hasta,
          }) async => {
            'periodo1': {'desde': p1Desde, 'hasta': p1Hasta, 'total': 12, 'porTipo': {}},
            'periodo2': {'desde': p2Desde, 'hasta': p2Hasta, 'total': 18, 'porTipo': {}},
            'diferencia': 6,
            'porcentaje': '50.0',
            'tendencia': 'incremento',
          },
          onGetTopZonas: ({int top = 5, String? fechaDesde, String? fechaHasta}) async => [
            {'barrio': 'Bombona', 'comuna': 3, 'total': 10},
            {'barrio': 'Mercedario', 'comuna': 4, 'total': 8},
          ],
        );

        await tester.pumpWidget(buildTestable(EstadisticasPage(datasource: fake)));
        await tester.pumpAndSettle();

        expect(fake.llamadasResumenUsuario, 1);
        expect(fake.llamadasComparacion, 1);
        expect(fake.llamadasTopZonas, 1);

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Total de incidentes'), findsOneWidget);
        expect(exactText('18'), findsOneWidget);
        expect(find.text('Zona más peligrosa'), findsOneWidget);
        expect(find.text('Comuna 3'), findsOneWidget);
        expect(find.text('Horario más peligroso'), findsOneWidget);
        expect(find.text('Tarde (12:00-17:59)'), findsOneWidget);
      },
    );

    testWidgets(
      'CP-HU11-07 compara dos periodos consecutivos y muestra variacion correcta',
      (tester) async {
        final fake = FakeEstadisticasDatasource(
          onGetResumenUsuario: () async => {
            'total': 15,
            'porTipo': {'atraco': 7, 'raponazo': 3, 'fleteo': 3, 'cosquilleo': 2},
            'porComuna': {'2': 9, '5': 6},
            'porFranja': {'18:00-23:59': 8},
            'porFecha': {'2026-04-01': 5, '2026-05-01': 10},
            'porEstado': {'activo': 15},
          },
          onGetComparacion: ({
            required String p1Desde,
            required String p1Hasta,
            required String p2Desde,
            required String p2Hasta,
          }) async => {
            'periodo1': {'desde': p1Desde, 'hasta': p1Hasta, 'total': 10, 'porTipo': {'atraco': 4}},
            'periodo2': {'desde': p2Desde, 'hasta': p2Hasta, 'total': 15, 'porTipo': {'atraco': 7}},
            'diferencia': 5,
            'porcentaje': '50.0',
            'tendencia': 'incremento',
          },
          onGetTopZonas: ({int top = 5, String? fechaDesde, String? fechaHasta}) async => [
            {'barrio': 'Centro', 'comuna': 2, 'total': 9},
          ],
        );

        await tester.pumpWidget(buildTestable(EstadisticasPage(datasource: fake)));
        await tester.pumpAndSettle();

        expect(fake.llamadasResumenUsuario, 1);
        expect(fake.llamadasComparacion, 1);
        expect(fake.llamadasTopZonas, 1);

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Total de incidentes'), findsOneWidget);
        expect(exactText('15'), findsOneWidget);

        expect(fake.ultimoP1Desde, isNotNull);
        expect(fake.ultimoP1Hasta, isNotNull);
        expect(fake.ultimoP2Desde, isNotNull);
        expect(fake.ultimoP2Hasta, isNotNull);
      },
    );

    testWidgets(
      'CP-HU11-08 periodo sin reportes muestra total 0 y estado consistente',
      (tester) async {
        final fake = FakeEstadisticasDatasource(
          onGetResumenUsuario: () async => {
            'total': 0,
            'porTipo': <String, int>{},
            'porComuna': <String, int>{},
            'porFranja': <String, int>{},
            'porFecha': <String, int>{},
            'porEstado': {'activo': 0},
          },
          onGetComparacion: ({
            required String p1Desde,
            required String p1Hasta,
            required String p2Desde,
            required String p2Hasta,
          }) async => {
            'periodo1': {'desde': p1Desde, 'hasta': p1Hasta, 'total': 0, 'porTipo': {}},
            'periodo2': {'desde': p2Desde, 'hasta': p2Hasta, 'total': 0, 'porTipo': {}},
            'diferencia': 0,
            'porcentaje': null,
            'tendencia': 'estable',
          },
          onGetTopZonas: ({int top = 5, String? fechaDesde, String? fechaHasta}) async => [],
        );

        await tester.pumpWidget(buildTestable(EstadisticasPage(datasource: fake)));
        await tester.pumpAndSettle();

        expect(fake.llamadasResumenUsuario, 1);
        expect(fake.llamadasComparacion, 1);
        expect(fake.llamadasTopZonas, 1);

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Total de incidentes'), findsOneWidget);
        expect(exactText('0'), findsWidgets);
      },
    );

    testWidgets(
      'CP-HU11-10 error al consultar estadisticas muestra estado controlado',
      (tester) async {
        final fake = FakeEstadisticasDatasource(
          onGetResumenUsuario: () async {
            throw Exception('fallo controlado');
          },
          onGetComparacion: ({
            required String p1Desde,
            required String p1Hasta,
            required String p2Desde,
            required String p2Hasta,
          }) async => {
            'periodo1': {'desde': p1Desde, 'hasta': p1Hasta, 'total': 0, 'porTipo': {}},
            'periodo2': {'desde': p2Desde, 'hasta': p2Hasta, 'total': 0, 'porTipo': {}},
            'diferencia': 0,
            'porcentaje': null,
            'tendencia': 'estable',
          },
          onGetTopZonas: ({int top = 5, String? fechaDesde, String? fechaHasta}) async => [],
        );

        await tester.pumpWidget(buildTestable(EstadisticasPage(datasource: fake)));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Filtros'), findsOneWidget);
        expect(find.text('Total de incidentes'), findsOneWidget);
      },
    );
  });
}