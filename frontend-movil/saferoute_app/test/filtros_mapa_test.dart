import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saferoute_app/features/user/presentation/pages/mapa_page.dart';

void main() {
  Future<void> pumpMapaPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MapaPage(),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Finder findDrawerMenuButton() {
    return find.byIcon(Icons.menu);
  }

  Future<void> openFiltersDrawer(WidgetTester tester) async {
    final menuButton = findDrawerMenuButton();
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.text('Filtros'), findsOneWidget);
  }

  group('HU-09 Frontend - filtros en mapa', () {
    testWidgets('CP-HU09-FE-01: muestra drawer de filtros', (tester) async {
      await pumpMapaPage(tester);
      await openFiltersDrawer(tester);

      expect(find.text('Comuna'), findsOneWidget);
      expect(find.text('Rango horario'), findsOneWidget);
      expect(find.text('Tipo de hurto'), findsOneWidget);
      expect(find.text('Fecha del incidente'), findsOneWidget);

      print('CP-HU09-FE-01 OK');
    });

    testWidgets('CP-HU09-FE-02: permite seleccionar una comuna', (tester) async {
      await pumpMapaPage(tester);
      await openFiltersDrawer(tester);

      final comuna3 = find.text('3');
      expect(comuna3, findsWidgets);

      await tester.tap(comuna3.first);
      await tester.pumpAndSettle();

      expect(find.text('Aplicar'), findsOneWidget);
      print('CP-HU09-FE-02 OK');
    });

    testWidgets('CP-HU09-FE-03: permite seleccionar una franja horaria', (tester) async {
      await pumpMapaPage(tester);
      await openFiltersDrawer(tester);

      expect(find.text('06:00-11:59'), findsOneWidget);

      await tester.tap(find.text('06:00-11:59'));
      await tester.pumpAndSettle();

      expect(find.text('Aplicar'), findsOneWidget);
      print('CP-HU09-FE-03 OK');
    });

    testWidgets('CP-HU09-FE-04: permite seleccionar tipo de hurto', (tester) async {
      await pumpMapaPage(tester);
      await openFiltersDrawer(tester);

      expect(find.text('Atraco'), findsOneWidget);

      await tester.tap(find.text('Atraco'));
      await tester.pumpAndSettle();

      expect(find.text('Aplicar'), findsOneWidget);
      print('CP-HU09-FE-04 OK');
    });

    testWidgets('CP-HU09-FE-05: permite limpiar filtros desde el drawer', (tester) async {
      await pumpMapaPage(tester);
      await openFiltersDrawer(tester);

      await tester.tap(find.text('3').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('06:00-11:59'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atraco'));
      await tester.pumpAndSettle();

      expect(find.text('Limpiar'), findsOneWidget);
      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();

      expect(find.text('Aplicar'), findsOneWidget);
      print('CP-HU09-FE-05 OK');
    });

    testWidgets('CP-HU09-FE-06: permite aplicar filtros combinados desde UI', (tester) async {
      await pumpMapaPage(tester);
      await openFiltersDrawer(tester);

      await tester.tap(find.text('2').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('12:00-17:59'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Raponazo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Filtros'), findsNothing);
      print('CP-HU09-FE-06 OK');
    });
  });
}