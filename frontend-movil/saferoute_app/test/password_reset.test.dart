import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saferoute_app/features/user/presentation/pages/forgot_password_page.dart';
import 'package:saferoute_app/features/user/presentation/pages/reset_password_page.dart';
import 'package:saferoute_app/features/user/presentation/providers/forgot_password_provider.dart';

Widget buildTestable(Widget child) {
  return MaterialApp(
    routes: {
      '/login': (_) => const Scaffold(body: Text('Login Page')),
    },
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(
      fileName: '.env',
      isOptional: true,
      mergeWith: {
        'API_BASE_URL': 'http://localhost:3000',
      },
    );
  });

  group('HU-13 Provider - ForgotPasswordProvider', () {
    test('estado inicial correcto', () {
      final provider = ForgotPasswordProvider();

      expect(provider.loading, false);
      expect(provider.enviado, false);
      expect(provider.error, isNull);
      expect(provider.restablecido, false);
    });

    test('reset limpia el estado', () {
      final provider = ForgotPasswordProvider();

      provider.reset();

      expect(provider.loading, false);
      expect(provider.enviado, false);
      expect(provider.error, isNull);
      expect(provider.restablecido, false);
    });
  });

  group('HU-13 Widget - ForgotPasswordPage', () {
    testWidgets('CP-HU13-FE-M-02 muestra error si el correo está vacío', (tester) async {
      await tester.pumpWidget(buildTestable(const ForgotPasswordPage()));

      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();

      expect(find.text('El correo es obligatorio'), findsOneWidget);
    });

    testWidgets('CP-HU13-FE-M-02 muestra error si el formato es inválido', (tester) async {
      await tester.pumpWidget(buildTestable(const ForgotPasswordPage()));

      final correoField = find.byType(TextFormField);
      expect(correoField, findsOneWidget);

      await tester.enterText(correoField, 'correo-invalido');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();

      expect(find.text('Formato de correo inválido'), findsOneWidget);
    });

    testWidgets('CP-HU13-FE-M-02A muestra error si el dominio no está permitido', (tester) async {
      await tester.pumpWidget(buildTestable(const ForgotPasswordPage()));

      final correoField = find.byType(TextFormField);
      expect(correoField, findsOneWidget);

      await tester.enterText(correoField, 'usuario@yahoo.com');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();

      expect(
        find.text('Solo se permiten: gmail.com, outlook.com, hotmail.com, umariana.edu.co'),
        findsOneWidget,
      );
    });

    testWidgets('CP-HU13-FE-M-01 acepta correo válido sin errores locales', (tester) async {
      await tester.pumpWidget(buildTestable(const ForgotPasswordPage()));

      final correoField = find.byType(TextFormField);
      expect(correoField, findsOneWidget);

      await tester.enterText(correoField, 'usuario@gmail.com');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pump();

      expect(find.text('El correo es obligatorio'), findsNothing);
      expect(find.text('Formato de correo inválido'), findsNothing);
      expect(
        find.text('Solo se permiten: gmail.com, outlook.com, hotmail.com, umariana.edu.co'),
        findsNothing,
      );
    });

    testWidgets('renderiza textos principales correctamente en forgot password', (tester) async {
      await tester.pumpWidget(buildTestable(const ForgotPasswordPage()));

      expect(find.text('Recuperar contraseña'), findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(
        find.text('Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.'),
        findsOneWidget,
      );
      expect(find.text('Enviar enlace'), findsOneWidget);
    });
  });

  group('HU-13 Widget - ResetPasswordPage', () {
    testWidgets('renderiza la pantalla de reset con token válido', (tester) async {
      await tester.pumpWidget(buildTestable(const ResetPasswordPage(token: 'token-valido')));
      await tester.pumpAndSettle();

      expect(find.text('Nueva contraseña'), findsWidgets);
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}