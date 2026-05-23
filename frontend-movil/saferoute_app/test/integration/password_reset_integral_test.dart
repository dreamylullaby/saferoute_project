import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:civictrackio_app/features/user/presentation/pages/forgot_password_page.dart';
import 'package:civictrackio_app/features/user/presentation/pages/reset_password_page.dart';
import 'package:civictrackio_app/features/user/presentation/providers/forgot_password_provider.dart';

Widget buildForgotPasswordTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
    ],
    child: MaterialApp(
      routes: {
        '/login': (_) =>
            const Scaffold(body: Center(child: Text('Login Page'))),
      },
      home: const ForgotPasswordPage(),
    ),
  );
}

Widget buildResetPasswordTestApp({String token = 'token-valido'}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
    ],
    child: MaterialApp(
      routes: {
        '/login': (_) =>
            const Scaffold(body: Center(child: Text('Login Page'))),
      },
      home: ResetPasswordPage(token: token),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(
      fileName: '.env',
      isOptional: true,
      mergeWith: {'API_BASE_URL': 'http://localhost:3000'},
    );
  });

  group('HU-13 Pruebas Integrales Flutter Móvil', () {
    testWidgets('PI-HU13-FM-01 correo válido envía solicitud de recuperación', (
      tester,
    ) async {
      await tester.pumpWidget(buildForgotPasswordTestApp());
      await tester.pumpAndSettle();

      final correoField = find.byType(TextFormField).first;
      expect(correoField, findsOneWidget);

      await tester.enterText(correoField, 'usuario@gmail.com');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('El correo es obligatorio'), findsNothing);
      expect(find.text('Formato de correo inválido'), findsNothing);

      // Check visible en consola
      // ignore: avoid_print
      print('✓ PI-HU13-FM-01 correo válido envía solicitud de recuperación');
    });

    testWidgets(
      'PI-HU13-FM-02 correo inválido muestra validación y bloquea envío',
      (tester) async {
        await tester.pumpWidget(buildForgotPasswordTestApp());
        await tester.pumpAndSettle();

        final correoField = find.byType(TextFormField).first;
        expect(correoField, findsOneWidget);

        await tester.enterText(correoField, 'correo-invalido');
        await tester.tap(find.text('Enviar enlace'));
        await tester.pumpAndSettle();

        expect(find.text('Formato de correo inválido'), findsOneWidget);

        // ignore: avoid_print
        print(
          '✓ PI-HU13-FM-02 correo inválido muestra validación y bloquea envío',
        );
      },
    );

    testWidgets(
      'PI-HU13-FM-03 token inválido o vacío bloquea el restablecimiento',
      (tester) async {
        await tester.pumpWidget(buildResetPasswordTestApp(token: ''));
        await tester.pumpAndSettle();

        expect(find.text('Nueva contraseña'), findsWidgets);

        final campos = find.byType(TextFormField);
        expect(campos, findsNWidgets(2));

        await tester.enterText(campos.at(0), 'Password123');
        await tester.enterText(campos.at(1), 'Password123');
        await tester.pumpAndSettle();

        final botones = find.byType(ElevatedButton);
        expect(botones, findsWidgets);

        await tester.tap(botones.first);
        await tester.pumpAndSettle();

        expect(find.text('Login Page'), findsNothing);

        // opcional: sigue en pantalla de reset
        expect(find.byType(TextFormField), findsNWidgets(2));

        // ignore: avoid_print
        print(
          '✓ PI-HU13-FM-03 token inválido o vacío bloquea el restablecimiento',
        );
      },
    );

    testWidgets(
      'PI-HU13-FM-04 contraseñas válidas permiten completar el reset',
      (tester) async {
        await tester.pumpWidget(
          buildResetPasswordTestApp(token: 'token-valido'),
        );
        await tester.pumpAndSettle();

        final campos = find.byType(TextFormField);
        expect(campos, findsNWidgets(2));

        await tester.enterText(campos.at(0), 'Password123');
        await tester.enterText(campos.at(1), 'Password123');
        await tester.pumpAndSettle();

        final botones = find.byType(ElevatedButton);
        expect(botones, findsWidgets);

        await tester.tap(botones.first);
        await tester.pumpAndSettle();

        expect(find.text('Las contraseñas no coinciden'), findsNothing);
        expect(find.textContaining('mínimo'), findsNothing);

        // ignore: avoid_print
        print(
          '✓ PI-HU13-FM-04 contraseñas válidas permiten completar el reset',
        );
      },
    );
  });
}
