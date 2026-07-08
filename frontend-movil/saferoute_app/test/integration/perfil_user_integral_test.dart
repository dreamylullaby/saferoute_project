import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import 'package:civictrackio_app/features/user/presentation/pages/perfil_page.dart';
import 'package:civictrackio_app/features/user/data/datasources/perfil_datasource.dart';

class FakePerfilDatasource extends PerfilDatasource {
  Map<String, dynamic> perfil = {
    'username': 'Luna',
    'correo': 'luna@test.com',
    'rol': 'user',
    'fecha_creacion': '2026-05-01T10:00:00.000Z',
    'notificaciones_activas': true,
    'auth_provider': 'local',
  };

  bool failGet = false;
  bool failUpdate = false;
  bool failPassword = false;
  bool failDelete = false;

  bool updateCalled = false;
  bool passwordCalled = false;
  bool deleteCalled = false;

  String? updatedUsername;
  String? currentPassword;
  String? newPassword;
  String? deletePassword;

  @override
  Future<Map<String, dynamic>> getPerfil() async {
    if (failGet) throw Exception('No se pudo cargar el perfil');
    return perfil;
  }

  @override
  Future<Map<String, dynamic>> updatePerfil({
    String? username,
    String? fotoUrl,
  }) async {
    updateCalled = true;
    if (failUpdate) throw Exception('No se pudo actualizar');
    updatedUsername = username;
    if (username != null) perfil['username'] = username;
    return perfil;
  }

  @override
  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    passwordCalled = true;
    if (failPassword) throw Exception('Error al cambiar contraseña');
    currentPassword = passwordActual;
    newPassword = nuevaPassword;
  }

  @override
  Future<void> eliminarCuenta({String? password}) async {
    deleteCalled = true;
    if (failDelete) throw Exception('Error al eliminar cuenta');
    deletePassword = password;
  }
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  LocationPermission permission;

  bool openSettingsCalled = false;
  bool requestPermissionCalled = false;

  FakeGeolocatorPlatform({this.permission = LocationPermission.whileInUse});

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalled = true;
    permission = LocationPermission.whileInUse;
    return permission;
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalled = true;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePerfilDatasource fakeDatasource;
  late FakeGeolocatorPlatform fakeGeo;
  bool logoutCalled = false;

  Future<void> pumpPage(WidgetTester tester) async {
    logoutCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/login': (_) =>
              const Scaffold(body: Center(child: Text('Pantalla Login'))),
        },
        home: PerfilPage(
          datasource: fakeDatasource,
          onLogout: () async {
            logoutCalled = true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> scrollToText(WidgetTester tester, String text) async {
    final finder = find.text(text, skipOffstage: false);
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisibleText(WidgetTester tester, String text) async {
    final finder = find.text(text, skipOffstage: false);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() {
    fakeDatasource = FakePerfilDatasource();
    fakeGeo = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fakeGeo;
  });

  group('HU-19 Integrales Flutter - PerfilPage', () {
    testWidgets('CP-HU19-I-01 carga datos del perfil', (tester) async {
      await pumpPage(tester);

      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Luna'), findsWidgets);
      expect(find.text('luna@test.com'), findsOneWidget);
      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Información de cuenta'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('CP-HU19-I-02 entra a edición y guarda nuevo apodo', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip('Editar perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar'), findsOneWidget);

      final field = find.byType(TextFormField);
      expect(field, findsOneWidget);

      await tester.enterText(field, 'LunaSegura');
      await tester.pumpAndSettle();

      await tapVisibleText(tester, 'Guardar');

      expect(fakeDatasource.updateCalled, true);
      expect(fakeDatasource.updatedUsername, 'LunaSegura');
    });

    testWidgets('CP-HU19-I-03 muestra error si falla carga del perfil', (
      tester,
    ) async {
      fakeDatasource.failGet = true;

      await pumpPage(tester);

      expect(find.text('Error al cargar perfil'), findsOneWidget);
    });

    testWidgets('CP-HU19-I-04 abre diálogo de cambiar contraseña', (
      tester,
    ) async {
      await pumpPage(tester);

      await scrollToText(tester, 'Cambiar contraseña');
      await tapVisibleText(tester, 'Cambiar contraseña');

      expect(find.text('Cambiar contraseña'), findsWidgets);
      expect(find.text('Contraseña actual'), findsOneWidget);
      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
    });

    testWidgets(
      'CP-HU19-I-05 valida campos obligatorios al cambiar contraseña',
      (tester) async {
        await pumpPage(tester);

        await scrollToText(tester, 'Cambiar contraseña');
        await tapVisibleText(tester, 'Cambiar contraseña');

        final buttons = find.text('Cambiar');
        expect(buttons, findsOneWidget);

        await tester.tap(buttons);
        await tester.pumpAndSettle();

        expect(find.text('Todos los campos son obligatorios'), findsOneWidget);
        expect(fakeDatasource.passwordCalled, false);
      },
    );

    testWidgets('CP-HU19-I-06 valida longitud mínima de nueva contraseña', (
      tester,
    ) async {
      await pumpPage(tester);

      await scrollToText(tester, 'Cambiar contraseña');
      await tapVisibleText(tester, 'Cambiar contraseña');

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3));

      await tester.enterText(textFields.at(0), 'Actual123');
      await tester.enterText(textFields.at(1), '123');
      await tester.enterText(textFields.at(2), '123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();

      expect(
        find.text('La nueva contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
      expect(fakeDatasource.passwordCalled, false);
    });

    testWidgets('CP-HU19-I-07 valida confirmación de contraseña', (
      tester,
    ) async {
      await pumpPage(tester);

      await scrollToText(tester, 'Cambiar contraseña');
      await tapVisibleText(tester, 'Cambiar contraseña');

      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(0), 'Actual123');
      await tester.enterText(textFields.at(1), 'Nueva123');
      await tester.enterText(textFields.at(2), 'Otra123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(fakeDatasource.passwordCalled, false);
    });

    testWidgets('CP-HU19-I-08 cambia contraseña exitosamente', (tester) async {
      await pumpPage(tester);

      await scrollToText(tester, 'Cambiar contraseña');
      await tapVisibleText(tester, 'Cambiar contraseña');

      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(0), 'Actual123');
      await tester.enterText(textFields.at(1), 'Nueva123');
      await tester.enterText(textFields.at(2), 'Nueva123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();

      expect(fakeDatasource.passwordCalled, true);
      expect(fakeDatasource.currentPassword, 'Actual123');
      expect(fakeDatasource.newPassword, 'Nueva123');
    });

    testWidgets('CP-HU19-I-09 desactivar ubicación abre advertencia', (
      tester,
    ) async {
      await pumpPage(tester);

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Desactivar ubicación'), findsOneWidget);
    });

    testWidgets(
      'CP-HU19-I-10 confirmar desactivar ubicación abre configuración',
      (tester) async {
        await pumpPage(tester);

        final switches = find.byType(Switch);
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abrir configuración'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(fakeGeo.openSettingsCalled, true);
      },
    );

    testWidgets('CP-HU19-I-11 desactivar notificaciones abre advertencia', (
      tester,
    ) async {
      await pumpPage(tester);

      final switches = find.byType(Switch);
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();

      expect(find.text('Desactivar notificaciones'), findsOneWidget);
    });

    testWidgets('CP-HU19-I-12 eliminar cuenta solicita confirmación', (
      tester,
    ) async {
      await pumpPage(tester);

      await scrollToText(tester, 'Eliminar cuenta');
      await tapVisibleText(tester, 'Eliminar cuenta');

      expect(find.text('Eliminar cuenta'), findsWidgets);
      expect(
        find.textContaining('Esta acción es irreversible'),
        findsOneWidget,
      );
      expect(find.text('Eliminar mi cuenta'), findsOneWidget);
    });

    testWidgets('CP-HU19-I-13 cerrar sesión redirige a login', (tester) async {
      await pumpPage(tester);

      await scrollToText(tester, 'Cerrar sesión');
      await tapVisibleText(tester, 'Cerrar sesión');
      await tester.pumpAndSettle();

      expect(logoutCalled, true);
      expect(find.text('Pantalla Login'), findsOneWidget);
    });
  });
}
