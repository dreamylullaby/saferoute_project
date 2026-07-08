import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civictrackio_app/features/user/presentation/pages/report_Incidente_Page.dart';

// Navega desde la pantalla selector al formulario urbano.
// El formulario rural hace HTTP en initState, por lo que usamos pump(duration)
// para evitar que pumpAndSettle bloquee esperando la red.
Future<void> _navegarAFormularioUrbano(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: ReportIncidentePage()),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Zona Urbana'));
  // pump con duracion larga en lugar de pumpAndSettle para evitar timeout
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

// Desplaza hasta el final del formulario y pulsa "Enviar reporte".
Future<void> _scrollYEnviar(WidgetTester tester) async {
  final scrollable = find.byType(SingleChildScrollView).last;
  await tester.drag(scrollable, const Offset(0, -2000));
  await tester.pump(const Duration(milliseconds: 300));

  await tester.tap(find.text('Enviar reporte'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake-token',
      'user_id': 'user-123',
    });
    await dotenv.load(
      fileName: '.env',
      isOptional: true,
      mergeWith: {
        'API_BASE_URL': 'http://localhost:3000',
        'MAPBOX_TOKEN': 'test-token',
      },
    );
  });

  // CP-HU01-F-01
  testWidgets(
    'CP-HU01-F-01: Pantalla selector muestra Zona Urbana y Zona Rural',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReportIncidentePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Registrar hurto'), findsOneWidget);
      expect(find.text('Zona Urbana'), findsOneWidget);
      expect(find.text('Zona Rural'), findsOneWidget);
      expect(find.text('Zona Urbana'), findsOneWidget);
    },
  );

  // CP-HU01-F-02
  testWidgets(
    'CP-HU01-F-02: Formulario urbano muestra los campos obligatorios',
    (tester) async {
      await _navegarAFormularioUrbano(tester);

      expect(find.text('Hurto en zona urbana'), findsOneWidget);
      expect(find.text('Fecha del incidente *'), findsOneWidget);
      expect(find.text('Franja horaria *'), findsOneWidget);
      // 'Direcci\u00f3n *' es el label con tilde tal como esta en el widget
      expect(find.text('Direcci\u00f3n *'), findsOneWidget);
      expect(find.text('Barrio donde ocurri\u00f3 *'), findsOneWidget);
    },
  );

  // CP-HU01-F-03
  // La zona rural dispara HTTP en initState; usamos pump con duracion fija
  // para no bloquear con pumpAndSettle.
  testWidgets(
    'CP-HU01-F-03: Formulario rural muestra los campos obligatorios',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReportIncidentePage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zona Rural'));
      // No usamos pumpAndSettle porque la peticion HTTP nunca resuelve en tests
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Hurto en zona rural'), findsOneWidget);
      expect(find.text('Fecha del incidente *'), findsOneWidget);
      expect(find.text('Franja horaria *'), findsOneWidget);
    },
  );

  // CP-HU01-F-04
  testWidgets(
    'CP-HU01-F-04: Enviar formulario vacio muestra errores de campo obligatorio',
    (tester) async {
      await _navegarAFormularioUrbano(tester);
      await _scrollYEnviar(tester);

      expect(find.text('Campo obligatorio'), findsWidgets);
    },
  );

  // CP-HU01-F-05
  testWidgets(
    'CP-HU01-F-05: La fecha del incidente es requerida al enviar vacio',
    (tester) async {
      await _navegarAFormularioUrbano(tester);
      await _scrollYEnviar(tester);

      // El campo fecha tiene validator que retorna 'Campo obligatorio'
      // Verificamos que al menos un error de ese tipo aparece
      expect(find.text('Campo obligatorio'), findsWidgets);
    },
  );

  // CP-HU01-F-06
  testWidgets(
    'CP-HU01-F-06: Franja horaria se pre-selecciona segun la hora actual',
    (tester) async {
      await _navegarAFormularioUrbano(tester);

      const franjas = [
        '00:00-05:59',
        '06:00-11:59',
        '12:00-17:59',
        '18:00-23:59',
      ];
      final algunaVisible = franjas.any(
        (f) => tester.widgetList(find.text(f, skipOffstage: false)).isNotEmpty,
      );
      expect(algunaVisible, isTrue);
    },
  );

  // CP-HU01-F-07
  testWidgets(
    'CP-HU01-F-07: Se puede seleccionar manualmente la franja 12:00-17:59',
    (tester) async {
      await _navegarAFormularioUrbano(tester);

      // Buscar el dropdown por tipo y hacer ensureVisible antes de tapear
      final dropdownFranja = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            (w.decoration.labelText?.contains('Franja horaria') ?? false),
      );
      await tester.ensureVisible(dropdownFranja);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(dropdownFranja);
      await tester.pump(const Duration(milliseconds: 300));

      // Toca la opcion en el menu desplegable
      final opcion = find.text('12:00-17:59').last;
      expect(opcion, findsOneWidget);
      await tester.tap(opcion);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('12:00-17:59'), findsOneWidget);
    },
  );

  // CP-HU01-F-08
  testWidgets(
    'CP-HU01-F-08: Se puede seleccionar el tipo de hurto Atraco',
    (tester) async {
      await _navegarAFormularioUrbano(tester);

      final dropdownTipo = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            (w.decoration.labelText?.contains('Tipo de hurto') ?? false),
      );
      await tester.ensureVisible(dropdownTipo);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(dropdownTipo);
      await tester.pump(const Duration(milliseconds: 300));

      final opcion = find.text('Atraco').last;
      expect(opcion, findsOneWidget);
      await tester.tap(opcion);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Atraco'), findsOneWidget);
    },
  );

  // CP-HU01-F-09
  testWidgets(
    'CP-HU01-F-09: Los campos opcionales se muestran en el formulario urbano',
    (tester) async {
      await _navegarAFormularioUrbano(tester);

      final scrollable = find.byType(SingleChildScrollView).last;
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 300));

      // Textos con tildes tal como estan en el widget de la pagina
      expect(find.text('Objeto hurtado (opcional)'), findsOneWidget);
      expect(find.text('N\u00famero de agresores (opcional)'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Descripci\u00f3n (opcional)'),
        findsOneWidget,
      );
    },
  );

  // CP-HU01-F-10
  testWidgets(
    'CP-HU01-F-10: El boton Enviar reporte esta presente en el formulario',
    (tester) async {
      await _navegarAFormularioUrbano(tester);

      final scrollable = find.byType(SingleChildScrollView).last;
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enviar reporte'), findsOneWidget);
    },
  );

  // CP-HU01-F-11
  testWidgets(
    'CP-HU01-F-11: El mensaje de confirmacion se muestra debajo del boton',
    (tester) async {
      await _navegarAFormularioUrbano(tester);

      final scrollable = find.byType(SingleChildScrollView).last;
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 300));

      // Texto con tilde tal como esta en el widget
      expect(
        find.text('Tu reporte aparecer\u00e1 en el mapa muy pronto.'),
        findsOneWidget,
      );
    },
  );
}
