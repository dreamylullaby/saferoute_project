import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saferoute_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HU-02 integral móvil: login exitoso', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Correo'),
      'usuario_prueba@mail.com',
    );
    await tester.enterText(
      find.bySemanticsLabel('Contraseña'),
      'pass123',
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.textContaining('Inicio'), findsWidgets);
  });
}