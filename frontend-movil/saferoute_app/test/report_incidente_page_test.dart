import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_app/features/user/presentation/pages/report_incidente_page.dart';

void main() {
  Future<void> loadAndSubmit(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportIncidentePage()));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar reporte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('CP-HU01-01: validar fecha obligatoria', (tester) async {
    //print('CP-HU01-01 - validar fecha obligatoria');
    //print('Entrada: formulario vacío');
    //print('Esperado: mostrar "Campo obligatorio"');

    await loadAndSubmit(tester);

    expect(find.text('Campo obligatorio'), findsNWidgets(5));

    print('Resultado: OK');
  });

  testWidgets('CP-HU01-02: validar franja horaria obligatoria', (tester) async {
    //print('CP-HU01-02 - validar franja horaria obligatoria');
    //print('Entrada: formulario vacío');
    //print('Esperado: mostrar "Campo obligatorio"');

    await loadAndSubmit(tester);

    expect(find.text('Campo obligatorio'), findsNWidgets(5));

    print('Resultado: OK');
  });

  testWidgets('CP-HU01-04: validar barrio obligatorio', (tester) async {
    //print('CP-HU01-04 - validar barrio obligatorio');
    //print('Entrada: formulario vacío');
    //print('Esperado: mostrar "Campo obligatorio"');

    await loadAndSubmit(tester);

    expect(find.text('Campo obligatorio'), findsNWidgets(5));

    print('Resultado: OK');
  });

  testWidgets('CP-HU01-05: validar tipo de hurto obligatorio', (tester) async {
    //print('CP-HU01-05 - validar tipo de hurto obligatorio');
    //print('Entrada: formulario vacío');
    //print('Esperado: mostrar "Campo obligatorio"');

    await loadAndSubmit(tester);

    expect(find.text('Campo obligatorio'), findsNWidgets(5));

    print('Resultado: OK');
  });

  testWidgets('CP-HU01-10: validar franja horaria válida', (tester) async {
    //print('CP-HU01-10 - validar franja horaria válida');
    //print('Entrada: seleccionar 12:00-17:59');
    //print('Esperado: mostrar la franja seleccionada');

    await tester.pumpWidget(const MaterialApp(home: ReportIncidentePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Franja horaria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12:00-17:59').last);
    await tester.pumpAndSettle();

    expect(find.text('12:00-17:59'), findsOneWidget);

    print('Resultado: OK');
  });

  testWidgets('CP-HU01-11: validar tipo de hurto permitido', (tester) async {
    //print('CP-HU01-11 - validar tipo de hurto permitido');
    //print('Entrada: seleccionar Atraco');
    //print('Esperado: mostrar el tipo de hurto seleccionado');

    await tester.pumpWidget(const MaterialApp(home: ReportIncidentePage()));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tipo de hurto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atraco').last);
    await tester.pumpAndSettle();

    expect(find.text('Atraco'), findsOneWidget);

    print('Resultado: OK');
  });
}