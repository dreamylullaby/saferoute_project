import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saferoute_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HU-01 integral móvil: registro exitoso', (tester) async {
    final unique = DateTime.now().millisecondsSinceEpoch;

    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿No tienes cuenta? Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Nombre de usuario'),
      'luna_$unique',
    );
    await tester.enterText(
      find.bySemanticsLabel('Correo'),
      'luna_$unique@mail.com',
    );
    await tester.enterText(
      find.bySemanticsLabel('Contraseña'),
      'pass123',
    );
    await tester.enterText(
      find.bySemanticsLabel('Confirmar contraseña'),
      'pass123',
    );

    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.textContaining('Bienvenido'), findsWidgets);
  });
}