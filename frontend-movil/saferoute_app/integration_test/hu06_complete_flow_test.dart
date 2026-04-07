import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saferoute_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HU-06 Integration: Formulario → Backend real', () {
    testWidgets('HU-06-05: crear reporte con datos opcionales', (
      WidgetTester tester,
    ) async {
      print('🧪 INICIANDO INTEGRAL HU-06-05');
      
      app.main();
      await tester.pumpAndSettle();

      // Navega a ReportIncidentePage
      await tester.tap(find.text('Reportar incidente'));
      await tester.pumpAndSettle();

      // Llena campos OBLIGATORIOS
      await _seleccionarTipoReportante(tester, 'Victima');
      await _ingresarFecha(tester, '2026-04-06');
      await _seleccionarFranja(tester, '12:00-17:59');
      await _ingresarLatitud(tester, '1.213610');
      await _ingresarLongitud(tester, '-77.281110');
      await _ingresarBarrio(tester, 'Centro');
      await _seleccionarTipoHurto(tester, 'Atraco');

      // Deja OPCIONALES VACÍOS (CP-HU06-02)
      expect(find.text('Objeto hurtado (opcional)'), findsOneWidget);

      // Envía al backend REAL
      await _enviarReporte(tester);

      // Verifica respuesta del backend real
      expect(find.textContaining('Reporte registrado'), findsOneWidget);
      expect(find.textContaining('ID del reporte'), findsOneWidget);

      print('✅ HU-06-05 INTEGRAL PASÓ');
    });

    testWidgets('HU-06-06: crear reporte sin opcionales', (
      WidgetTester tester,
    ) async {
      print('🧪 INICIANDO INTEGRAL HU-06-06');
      
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportar incidente'));
      await tester.pumpAndSettle();

      // Solo obligatorios, opcionales vacíos
      await _seleccionarTipoReportante(tester, 'Victima');
      await _ingresarFecha(tester, '2026-04-06');
      await _seleccionarFranja(tester, '12:00-17:59');
      await _ingresarLatitud(tester, '1.213610');
      await _ingresarLongitud(tester, '-77.281110');
      await _ingresarBarrio(tester, 'Centro');
      await _seleccionarTipoHurto(tester, 'Atraco');

      await _enviarReporte(tester);

      expect(find.textContaining('Reporte registrado'), findsOneWidget);
      print('✅ HU-06-06 INTEGRAL PASÓ');
    });
  });
}

// Helpers reutilizables
Future<void> _seleccionarTipoReportante(WidgetTester tester, String valor) async {
  final dropdown = find.widgetWithText(DropdownButtonFormField<String>, '¿Eres víctima o testigo?');
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(valor).last);
  await tester.pumpAndSettle();
}

Future<void> _ingresarFecha(WidgetTester tester, String fecha) async {
  final campo = find.widgetWithText(TextFormField, 'Fecha del incidente');
  await tester.enterText(campo, fecha);
  await tester.pumpAndSettle();
}

Future<void> _seleccionarFranja(WidgetTester tester, String franja) async {
  final dropdown = find.widgetWithText(DropdownButtonFormField<String>, 'Franja horaria');
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(franja).last);
  await tester.pumpAndSettle();
}

Future<void> _ingresarLatitud(WidgetTester tester, String lat) async {
  final campo = find.widgetWithText(TextFormField, 'Latitud');
  await tester.enterText(campo, lat);
  await tester.pumpAndSettle();
}

Future<void> _ingresarLongitud(WidgetTester tester, String lon) async {
  final campo = find.widgetWithText(TextFormField, 'Longitud');
  await tester.enterText(campo, lon);
  await tester.pumpAndSettle();
}

Future<void> _ingresarBarrio(WidgetTester tester, String barrio) async {
  final campo = find.widgetWithText(TextFormField, 'Barrio donde ocurrió');
  await tester.enterText(campo, barrio);
  await tester.pumpAndSettle();
}

Future<void> _seleccionarTipoHurto(WidgetTester tester, String tipo) async {
  final dropdown = find.widgetWithText(DropdownButtonFormField<String>, 'Tipo de hurto');
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(tipo).last);
  await tester.pumpAndSettle();
}

Future<void> _enviarReporte(WidgetTester tester) async {
  final boton = find.text('Enviar reporte');
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}