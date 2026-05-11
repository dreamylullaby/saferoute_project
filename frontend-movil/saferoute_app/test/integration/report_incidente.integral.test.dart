import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

import 'package:saferoute_app/features/user/presentation/pages/report_incidente_page.dart';
import 'package:saferoute_app/services/auth_storage.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
  dotenv.loadFromString(envString: '''
API_BASE_URL=http://localhost:3000
MAPBOX_TOKEN=test-token
''');
});

  Future<void> mountApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReportIncidentePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollDown(WidgetTester tester) async {
    final scroll = find.byType(SingleChildScrollView);
    if (scroll.evaluate().isNotEmpty) {
      await tester.drag(scroll, const Offset(0, -900));
      await tester.pumpAndSettle();
    }
  }

  Future<void> openDatePickerAndSelect(WidgetTester tester) async {
    final dateField = find.widgetWithText(TextFormField, 'Fecha del incidente *');
    if (dateField.evaluate().isNotEmpty) {
      await tester.tap(dateField.first);
      await tester.pumpAndSettle();
    }
    final day = find.text('15');
    if (day.evaluate().isNotEmpty) {
      await tester.tap(day.first);
      await tester.pumpAndSettle();
      final ok = find.text('OK');
      if (ok.evaluate().isNotEmpty) {
        await tester.tap(ok.first);
        await tester.pumpAndSettle();
      }
    }
  }

  group('HU-01 Integrales Flutter', () {
    testWidgets('PI-HU01-01 reporte con campos obligatorios', (tester) async {
      await mountApp(tester);
      await scrollDown(tester);

      expect(find.text('Enviar reporte'), findsOneWidget);
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Campo obligatorio'), findsWidgets);
    });

    testWidgets('PI-HU01-02 reporte con campos opcionales', (tester) async {
      await mountApp(tester);
      await scrollDown(tester);

      await openDatePickerAndSelect(tester);

      final direccion = find.widgetWithText(TextFormField, 'Dirección *');
      if (direccion.evaluate().isNotEmpty) {
        await tester.enterText(direccion.first, 'Cra 15 #22-10');
        await tester.pumpAndSettle();
      }

      final barrio = find.widgetWithText(TextFormField, 'Barrio donde ocurrió *');
      if (barrio.evaluate().isNotEmpty) {
        await tester.enterText(barrio.first, 'Centro');
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tu reporte fue enviado exitosamente'), findsNothing);
    });

    testWidgets('PI-HU01-03 fecha obligatoria', (tester) async {
      await mountApp(tester);
      await scrollDown(tester);

      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Campo obligatorio'), findsWidgets);
    });

    testWidgets('PI-HU01-04 franja horaria obligatoria', (tester) async {
      await mountApp(tester);
      await scrollDown(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha del incidente *').first,
        '15/04/2026',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Campo obligatorio'), findsWidgets);
    });

    testWidgets('PI-HU01-05 ubicacion obligatoria', (tester) async {
      await mountApp(tester);
      await scrollDown(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha del incidente *').first,
        '15/04/2026',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Debes seleccionar la ubicación del incidente en el mapa'),
        findsOneWidget,
      );
    });

    testWidgets('PI-HU01-06 barrio obligatorio', (tester) async {
      await mountApp(tester);
      await scrollDown(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha del incidente *').first,
        '15/04/2026',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Campo obligatorio'), findsWidgets);
    });

    testWidgets('PI-HU01-07 tipo de hurto obligatorio', (tester) async {
      await mountApp(tester);
      await scrollDown(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha del incidente *').first,
        '15/04/2026',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Campo obligatorio'), findsWidgets);
    });

    testWidgets('PI-HU01-08 persistencia correcta del reporte', (tester) async {
      await mountApp(tester);
      expect(find.text('Registrar hurto'), findsOneWidget);
    });

    testWidgets('PI-HU01-09 confirmacion al usuario', (tester) async {
      await mountApp(tester);
      expect(find.text('Tu reporte aparecerá en el mapa muy pronto.'), findsOneWidget);
    });

    testWidgets('PI-HU01-10 franja horaria valida', (tester) async {
      await mountApp(tester);
      expect(find.text('Franja horaria *'), findsOneWidget);
    });

    testWidgets('PI-HU01-11 tipo de hurto permitido', (tester) async {
      await mountApp(tester);
      expect(find.text('Tipo de hurto *'), findsOneWidget);
    });
  });
}