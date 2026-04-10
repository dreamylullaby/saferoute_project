import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saferoute_app/features/user/presentation/pages/report_incidente_Page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake-token',
      'user_id': 'user-123',
    });
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReportIncidentePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seleccionarDropdown(
    WidgetTester tester, {
    required String label,
    required String optionText,
  }) async {
    final dropdownFinder = find.widgetWithText(
      DropdownButtonFormField<String>,
      label,
    );

    await tester.ensureVisible(dropdownFinder);
    await tester.pumpAndSettle();

    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text(optionText).last);
    await tester.pumpAndSettle();
  }

  Future<void> llenarCamposObligatorios(WidgetTester tester) async {
    await seleccionarDropdown(
      tester,
      label: '¿Eres víctima o testigo?',
      optionText: 'Victima',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fecha del incidente'),
      '2026-04-05',
    );

    await seleccionarDropdown(
      tester,
      label: 'Franja horaria',
      optionText: '12:00-17:59',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Latitud'),
      '1.213610',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Longitud'),
      '-77.281110',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Barrio donde ocurrió'),
      'Centro',
    );

    await seleccionarDropdown(
      tester,
      label: 'Tipo de hurto',
      optionText: 'Atraco',
    );

    await tester.pumpAndSettle();
  }

  testWidgets('CP-HU06-01: mostrar campos opcionales', (
    WidgetTester tester,
  ) async {
    print('==============================');
    print('INICIANDO CP-HU06-01 - mostrar campos opcionales');
    print('==============================');

    await pumpPage(tester);

    expect(find.text('Objeto hurtado (opcional)'), findsOneWidget);
    expect(find.text('Número de agresores (opcional)'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Descripción (opcional)'),
      findsOneWidget,
    );

    print('✅ CP-HU06-01 PASÓ');
  });

  testWidgets('CP-HU06-02: permitir campos vacíos', (
    WidgetTester tester,
  ) async {
    print('==============================');
    print('INICIANDO CP-HU06-02 - permitir campos vacíos');
    print('==============================');

    await pumpPage(tester);

    await llenarCamposObligatorios(tester);

    final botonEnviar = find.text('Enviar reporte');
    await tester.ensureVisible(botonEnviar);
    await tester.pumpAndSettle();
    await tester.tap(botonEnviar);
    await tester.pumpAndSettle();

    expect(find.text('Objeto hurtado (opcional)'), findsOneWidget);
    expect(find.text('Número de agresores (opcional)'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Descripción (opcional)'),
      findsOneWidget,
    );

    print('✅ CP-HU06-02 PASÓ');
  });

  testWidgets('CP-HU06-03: validar descripción longitud máxima', (
    WidgetTester tester,
  ) async {
    print('==============================');
    print('INICIANDO CP-HU06-03 - validar descripción longitud máxima');
    print('==============================');

    await pumpPage(tester);

    final descripcionFinder = find.widgetWithText(
      TextFormField,
      'Descripción (opcional)',
    );

    await tester.enterText(descripcionFinder, 'a' * 301);
    await tester.pumpAndSettle();

    final editableText = tester.widget<EditableText>(
      find.descendant(
        of: descripcionFinder,
        matching: find.byType(EditableText),
      ),
    );

    expect(editableText.controller.text.length <= 300, true);

    print('✅ CP-HU06-03 PASÓ');
  });

  testWidgets('CP-HU06-04: validar número de agresores válido', (
    WidgetTester tester,
  ) async {
    print('==============================');
    print('INICIANDO CP-HU06-04 - validar número de agresores válido');
    print('==============================');

    await pumpPage(tester);

    await seleccionarDropdown(
      tester,
      label: 'Número de agresores (opcional)',
      optionText: '2',
    );

    expect(find.text('2'), findsAtLeastNWidgets(1));

    print('✅ CP-HU06-04 PASÓ');
  });
}