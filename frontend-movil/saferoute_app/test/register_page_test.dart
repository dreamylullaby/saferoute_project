import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_app/features/user/presentation/pages/register_page.dart';

void logInicio(String codigo, String nombre) {
  print('==============================');
  print('INICIANDO $codigo - $nombre');
  print('==============================');
}

void logOk(String codigo) {
  print('✅ $codigo PASÓ');
}

void main() {
  group('HU-04 RegisterPage UI', () {
    testWidgets('CP-HU04-01: correo obligatorio', (tester) async {
      logInicio('CP-HU04-01', 'correo obligatorio');

      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Campo obligatorio'), findsWidgets);

      logOk('CP-HU04-01');
    });

    testWidgets('CP-HU04-02: formato correo inválido', (tester) async {
      logInicio('CP-HU04-02', 'formato correo inválido');

      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'usuario sin arroba');
      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Correo inválido'), findsWidgets);

      logOk('CP-HU04-02');
    });

    testWidgets('CP-HU04-03: apodo obligatorio', (tester) async {
      logInicio('CP-HU04-03', 'apodo obligatorio');

      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Campo obligatorio'), findsWidgets);

      logOk('CP-HU04-03');
    });

    testWidgets('CP-HU04-04: apodo muy corto', (tester) async {
      logInicio('CP-HU04-04', 'apodo muy corto');

      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'ab');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'pass12!');
      await tester.enterText(find.byType(TextFormField).at(3), 'pass12!');
      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Apodo debe tener mínimo 3 caracteres'), findsOneWidget);

      logOk('CP-HU04-04');
    });

    testWidgets('CP-HU04-05: contraseña obligatoria', (tester) async {
      logInicio('CP-HU04-05', 'contraseña obligatoria');

      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'JuanP');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@gmail.com');
      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Campo obligatorio'), findsWidgets);

      logOk('CP-HU04-05');
    });

    testWidgets('CP-HU04-06: contraseña mínima', (tester) async {
      logInicio('CP-HU04-06', 'contraseña mínima');

      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'JuanP');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.enterText(find.byType(TextFormField).at(3), '123');
      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.textContaining('5 caracteres'), findsWidgets);

      logOk('CP-HU04-06');
    });

    testWidgets('CP-HU04-07: confirmar contraseña no coincide', (tester) async {
      logInicio('CP-HU04-07', 'confirmar contraseña no coincide');

      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'JuanP');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'pass12!');
      await tester.enterText(find.byType(TextFormField).at(3), 'pass99!');
      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden'), findsWidgets);

      logOk('CP-HU04-07');
    });
  });
}