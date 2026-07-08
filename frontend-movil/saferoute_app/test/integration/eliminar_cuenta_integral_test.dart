import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civictrackio_app/features/user/presentation/pages/perfil_page.dart';
import 'package:civictrackio_app/features/user/data/datasources/perfil_datasource.dart';

class FakePerfilDatasource extends PerfilDatasource {
  FakePerfilDatasource({
    this.perfil,
    this.onEliminar,
  });

  final Map<String, dynamic>? perfil;
  final Future<void> Function({String? password})? onEliminar;

  @override
  Future<Map<String, dynamic>> getPerfil() async {
    return perfil ??
        {
          'username': 'Luna',
          'correo': 'luna@test.com',
          'rol': 'usuario',
          'fecha_creacion': DateTime(2025, 1, 10).toIso8601String(),
          'notificaciones_activas': true,
          'auth_provider': 'local',
        };
  }

  @override
  Future<Map<String, dynamic>> updatePerfil({
    String? username,
    String? fotoUrl,
  }) async {
    return {
      'id': 1,
      'username': username ?? 'Luna',
      'correo': 'luna@test.com',
      'foto_url': fotoUrl,
      'rol': 'usuario',
    };
  }

  @override
  Future<void> toggleNotificaciones(bool activo) async {}

  @override
  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {}

  @override
  Future<void> eliminarCuenta({String? password}) async {
    if (onEliminar != null) {
      await onEliminar!(password: password);
    }
  }
}

Widget buildTestable({
  required PerfilDatasource datasource,
  Future<void> Function()? onLogout,
}) {
  return MaterialApp(
    routes: {
      '/': (_) => PerfilPage(datasource: datasource, onLogout: onLogout),
      '/login': (_) => const Scaffold(
            body: Center(child: Text('Login Page')),
          ),
    },
  );
}

Future<void> abrirDialogoEliminar(WidgetTester tester) async {
  final eliminarFinder = find.text('Eliminar cuenta');

  await tester.ensureVisible(eliminarFinder);
  await tester.pumpAndSettle();

  await tester.tap(eliminarFinder);
  await tester.pumpAndSettle();
}

void main() {
  group('HU-21 Tests - PerfilPage', () {
    testWidgets(
      'CP-HU21-I-01 muestra modal al tocar eliminar cuenta',
      (tester) async {
        final ds = FakePerfilDatasource();

        await tester.pumpWidget(buildTestable(datasource: ds));
        await tester.pumpAndSettle();

        await abrirDialogoEliminar(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Eliminar cuenta'), findsWidgets);
        expect(find.textContaining('irreversible'), findsOneWidget);
        expect(find.textContaining('forma anónima'), findsOneWidget);
      },
    );

    testWidgets(
      'CP-HU21-I-02 muestra campo de contraseña si provider es local',
      (tester) async {
        final ds = FakePerfilDatasource(
          perfil: {
            'username': 'Luna',
            'correo': 'luna@test.com',
            'rol': 'usuario',
            'fecha_creacion': DateTime(2025, 1, 10).toIso8601String(),
            'notificaciones_activas': true,
            'auth_provider': 'local',
          },
        );

        await tester.pumpWidget(buildTestable(datasource: ds));
        await tester.pumpAndSettle();

        await abrirDialogoEliminar(tester);

        expect(find.text('Confirma tu contraseña:'), findsOneWidget);
        expect(find.text('Contraseña actual'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'CP-HU21-I-03 no muestra contraseña si provider es google',
      (tester) async {
        final ds = FakePerfilDatasource(
          perfil: {
            'username': 'Luna',
            'correo': 'luna@test.com',
            'rol': 'usuario',
            'fecha_creacion': DateTime(2025, 1, 10).toIso8601String(),
            'notificaciones_activas': true,
            'auth_provider': 'google',
          },
        );

        await tester.pumpWidget(buildTestable(datasource: ds));
        await tester.pumpAndSettle();

        await abrirDialogoEliminar(tester);

        expect(find.text('Confirma tu contraseña:'), findsNothing);
        expect(find.text('Contraseña actual'), findsNothing);
      },
    );

    testWidgets(
      'CP-HU21-I-04 cancelar eliminación no llama al datasource',
      (tester) async {
        bool eliminado = false;

        final ds = FakePerfilDatasource(
          onEliminar: ({String? password}) async {
            eliminado = true;
          },
        );

        await tester.pumpWidget(buildTestable(datasource: ds));
        await tester.pumpAndSettle();

        await abrirDialogoEliminar(tester);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(eliminado, false);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'CP-HU21-I-05 confirma eliminación y muestra diálogo final',
      (tester) async {
        bool eliminado = false;
        bool logoutEjecutado = false;

        final ds = FakePerfilDatasource(
          onEliminar: ({String? password}) async {
            eliminado = true;
            expect(password, 'ClaveValida123');
          },
        );

        await tester.pumpWidget(
          buildTestable(
            datasource: ds,
            onLogout: () async {
              logoutEjecutado = true;
            },
          ),
        );
        await tester.pumpAndSettle();

        await abrirDialogoEliminar(tester);

        await tester.enterText(find.byType(TextField), 'ClaveValida123');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Eliminar mi cuenta'));
        await tester.pumpAndSettle();

        expect(eliminado, true);
        expect(logoutEjecutado, true);
        expect(find.text('Cuenta eliminada'), findsOneWidget);
        expect(find.textContaining('redirigido al inicio'), findsOneWidget);
      },
    );

    testWidgets(
      'CP-HU21-I-06 redirige a login tras aceptar diálogo final',
      (tester) async {
        final ds = FakePerfilDatasource(
          onEliminar: ({String? password}) async {},
        );

        await tester.pumpWidget(
          buildTestable(
            datasource: ds,
            onLogout: () async {},
          ),
        );
        await tester.pumpAndSettle();

        await abrirDialogoEliminar(tester);

        await tester.enterText(find.byType(TextField), 'ClaveValida123');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Eliminar mi cuenta'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();

        expect(find.text('Login Page'), findsOneWidget);
      },
    );

    testWidgets(
      'CP-HU21-I-07 muestra error si backend falla',
      (tester) async {
        final ds = FakePerfilDatasource(
          onEliminar: ({String? password}) async {
            throw Exception('Contraseña incorrecta');
          },
        );

        await tester.pumpWidget(
          buildTestable(
            datasource: ds,
            onLogout: () async {},
          ),
        );
        await tester.pumpAndSettle();

        await abrirDialogoEliminar(tester);

        await tester.enterText(find.byType(TextField), 'mala');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Eliminar mi cuenta'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Contraseña incorrecta'), findsOneWidget);
      },
    );

    testWidgets(
      'CP-HU21-I-08 la opción eliminar cuenta está visible',
      (tester) async {
        final ds = FakePerfilDatasource();

        await tester.pumpWidget(buildTestable(datasource: ds));
        await tester.pumpAndSettle();

        final eliminarFinder = find.text('Eliminar cuenta');
        await tester.ensureVisible(eliminarFinder);
        await tester.pumpAndSettle();

        expect(find.text('Zona peligrosa'), findsOneWidget);
        expect(eliminarFinder, findsOneWidget);
        expect(
          find.text('Elimina tu cuenta y anonimiza tus datos'),
          findsOneWidget,
        );
      },
    );
  });
}