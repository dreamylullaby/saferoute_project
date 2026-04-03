import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_app/features/user/presentation/pages/login_Page.dart';

void main() {

  group('HU-02: Login - Pruebas UI', () {

    /// 🔹 CP-HU02-01: Campo obligatorio (correo vacío)
    testWidgets('CP-HU02-01: Campo obligatorio correo', (WidgetTester tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      print('\n--- CP-HU02-01 ---');
      print('Entrada: correo vacío');
      print('Resultado esperado: "Campo obligatorio"');

      expect(find.text('Campo obligatorio'), findsWidgets);
    });

    /// 🔹 CP-HU02-02: Correo inválido
    testWidgets('CP-HU02-02: Correo inválido', (WidgetTester tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      // Escribir correo inválido
      await tester.enterText(find.byType(TextFormField).at(0), 'usuarioinvalido');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      print('\n--- CP-HU02-02 ---');
      print('Entrada: usuarioinvalido');
      print('Resultado esperado: "Correo inválido"');

      expect(find.text('Correo inválido'), findsOneWidget);
    });

    /// 🔹 CP-HU02-03: Contraseña obligatoria
    testWidgets('CP-HU02-03: Contraseña obligatoria', (WidgetTester tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      // Solo llenar correo
      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      print('\n--- CP-HU02-03 ---');
      print('Entrada: contraseña vacía');
      print('Resultado esperado: "Campo obligatorio"');

      expect(find.text('Campo obligatorio'), findsWidgets);
    });

  });
}