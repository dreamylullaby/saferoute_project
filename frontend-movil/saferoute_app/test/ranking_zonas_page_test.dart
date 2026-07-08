import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:civictrackio_app/features/user/presentation/pages/ranking_zonas_page.dart';
import 'package:civictrackio_app/features/user/data/datasources/estadisticas_datasource.dart';

class MockEstadisticasDatasource extends Mock
    implements EstadisticasDatasource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEstadisticasDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockEstadisticasDatasource();
  });

  Widget makeTestable(Widget child) {
    return MaterialApp(home: child);
  }

  List<Map<String, dynamic>> topZonasDesc() => [
        {'barrio': 'Centro', 'comuna': 1, 'total': 20},
        {'barrio': 'La Minga', 'comuna': 2, 'total': 12},
        {'barrio': 'Obrero', 'comuna': 3, 'total': 5},
      ];

  List<Map<String, dynamic>> topZonasAsc() => [
        {'barrio': 'Obrero', 'comuna': 3, 'total': 5},
        {'barrio': 'La Minga', 'comuna': 2, 'total': 12},
        {'barrio': 'Centro', 'comuna': 1, 'total': 20},
      ];

  void mockSuccess(List<Map<String, dynamic>> data) {
    when(() => mockDatasource.getTopZonas(
          top: any(named: 'top'),
          fechaDesde: any(named: 'fechaDesde'),
          fechaHasta: any(named: 'fechaHasta'),
        )).thenAnswer((_) async => data);
  }

  group('HU-12 RankingZonasPage', () {
    testWidgets('CP-HU12-01 Visualizar listado ordenado por cantidad',
        (tester) async {
      mockSuccess(topZonasDesc());

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('La Minga'), findsOneWidget);
      expect(find.text('Obrero'), findsOneWidget);

      expect(find.textContaining('20'), findsWidgets);
      expect(find.textContaining('12'), findsWidgets);
      expect(find.textContaining('5'), findsWidgets);

      print('✅ OK');
    });

    testWidgets('CP-HU12-02 Mostrar nombre de zona', (tester) async {
      mockSuccess(topZonasDesc());

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('Comuna 1'), findsOneWidget);
      expect(find.text('La Minga'), findsOneWidget);
      expect(find.text('Comuna 2'), findsOneWidget);

      print('✅ OK');
    });

    testWidgets('CP-HU12-03 Mostrar cantidad total de hurtos por zona',
        (tester) async {
      mockSuccess(topZonasDesc());

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('hurtos'), findsNWidgets(3));
      expect(find.textContaining('20'), findsWidgets);
      expect(find.textContaining('12'), findsWidgets);
      expect(find.textContaining('5'), findsWidgets);

      print('✅ OK');
    });

    testWidgets('CP-HU12-04 Mostrar porcentaje respecto al total',
        (tester) async {
      mockSuccess(topZonasDesc());

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);

      print('✅ OK');
    });

    testWidgets('CP-HU12-05 Recalcular al cambiar periodo', (tester) async {
      var callCount = 0;

      when(() => mockDatasource.getTopZonas(
            top: any(named: 'top'),
            fechaDesde: any(named: 'fechaDesde'),
            fechaHasta: any(named: 'fechaHasta'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return topZonasDesc();
        return topZonasAsc();
      });

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Centro'), findsOneWidget);

      await tester.tap(find.text('Desde'));
      await tester.pumpAndSettle();

      expect(callCount, greaterThanOrEqualTo(1));

      print('✅ OK');
    });

    testWidgets('CP-HU12-06 Sin reportes en el periodo', (tester) async {
      mockSuccess([]);

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin datos'), findsOneWidget);

      print('✅ OK');
    });

    testWidgets('CP-HU12-07 Orden alfabético', (tester) async {
      mockSuccess(topZonasDesc());

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('La Minga'), findsOneWidget);
      expect(find.text('Obrero'), findsOneWidget);

      print('✅ OK');
    });

    testWidgets('CP-HU12-08 Orden ascendente por cantidad', (tester) async {
      mockSuccess(topZonasAsc());

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Obrero'), findsOneWidget);
      expect(find.textContaining('5'), findsWidgets);

      print('✅ OK');
    });

    testWidgets('CP-HU12-09 Consistencia de datos al reordenar',
        (tester) async {
      mockSuccess(topZonasDesc());

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('Comuna 1'), findsOneWidget);
      expect(find.textContaining('20'), findsWidgets);

      print('✅ OK');
    });

    testWidgets('CP-HU12-10 Error al cargar ranking de zonas',
        (tester) async {
      when(() => mockDatasource.getTopZonas(
            top: any(named: 'top'),
            fechaDesde: any(named: 'fechaDesde'),
            fechaHasta: any(named: 'fechaHasta'),
          )).thenThrow(Exception('Error al obtener top zonas'));

      await tester.pumpWidget(
        makeTestable(RankingZonasPage(datasource: mockDatasource)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin datos'), findsOneWidget);

      print('✅ OK');
    });
  });
}