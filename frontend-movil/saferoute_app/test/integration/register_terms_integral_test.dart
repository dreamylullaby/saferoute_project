import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civictrackio_app/features/user/presentation/pages/register_page.dart';

class FakeUser {
  FakeUser({required this.username});
  final String username;
}

Widget buildTestable({
  required Future<dynamic> Function({
    required String username,
    required String correo,
    required String password,
  }) onRegister,
}) {
  return MaterialApp(
    routes: {
      '/login': (_) => const Scaffold(
            body: Center(child: Text('Login Page')),
          ),
    },
    home: RegisterPage(onRegister: onRegister),
  );
}

Future<void> llenarFormularioValido(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Luna');
  await tester.enterText(find.byType(TextFormField).at(1), 'luna@test.com');
  await tester.enterText(find.byType(TextFormField).at(2), 'ClaveSegura123');
  await tester.enterText(find.byType(TextFormField).at(3), 'ClaveSegura123');
  await tester.pumpAndSettle();
}

Future<void> scrollHastaBoton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('btn_registrarse')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HU-04 Integrales Flutter - Términos y Condiciones', () {
    testWidgets('CP-HU04-I-01 no registra si no acepta términos', (tester) async {
      bool ejecutado = false;

      await tester.pumpWidget(
        buildTestable(
          onRegister: ({
            required String username,
            required String correo,
            required String password,
          }) async {
            ejecutado = true;
            return FakeUser(username: username);
          },
        ),
      );

      await tester.pumpAndSettle();
      await llenarFormularioValido(tester);
      await scrollHastaBoton(tester);

      await tester.tap(find.byKey(const Key('btn_registrarse')));
      await tester.pumpAndSettle();

      expect(ejecutado, false);
    });

    testWidgets('CP-HU04-I-02 visualiza términos y condiciones', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          onRegister: ({
            required String username,
            required String correo,
            required String password,
          }) async {
            return FakeUser(username: username);
          },
        ),
      );

      await tester.pumpAndSettle();
      await scrollHastaBoton(tester);

      await tester.tap(find.byKey(const Key('link_terminos')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Términos y Condiciones'), findsWidgets);
    });
  });
}