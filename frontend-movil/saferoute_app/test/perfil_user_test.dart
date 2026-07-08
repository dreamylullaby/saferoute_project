import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:civictrackio_app/features/user/presentation/pages/perfil_page.dart';
import 'package:civictrackio_app/features/user/data/datasources/perfil_datasource.dart';

class MockPerfilDatasource extends Mock implements PerfilDatasource {}

void main() {
  late MockPerfilDatasource datasource;

  setUp(() {
    datasource = MockPerfilDatasource();
  });

  Widget buildTestable(Widget child) {
    return MaterialApp(
      routes: {'/login': (_) => const Scaffold(body: Text('Login'))},
      home: child,
    );
  }

  testWidgets('CP-HU19-F-01 muestra datos del perfil', (tester) async {
    when(() => datasource.getPerfil()).thenAnswer(
      (_) async => {
        'id': 'u1',
        'username': 'Luna',
        'correo': 'luna@test.com',
        'rol': 'usuario',
        'auth_provider': 'local',
        'fecha_creacion': '2026-05-01T10:00:00.000Z',
        'notificaciones_activas': true,
      },
    );

    await tester.pumpWidget(buildTestable(PerfilPage(datasource: datasource)));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Luna'), findsWidgets);
    expect(find.text('luna@test.com'), findsOneWidget);
    expect(find.text('Información de cuenta'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('CP-HU19-F-02 carga el perfil sin romper el render', (
    tester,
  ) async {
    when(() => datasource.getPerfil()).thenAnswer(
      (_) async => {
        'id': 'u1',
        'username': 'Luna',
        'correo': 'luna@test.com',
        'rol': 'usuario',
        'auth_provider': 'local',
        'fecha_creacion': '2026-05-01T10:00:00.000Z',
        'notificaciones_activas': true,
      },
    );

    await tester.pumpWidget(buildTestable(PerfilPage(datasource: datasource)));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Luna'), findsWidgets);
    verify(() => datasource.getPerfil()).called(1);
  });
  testWidgets('CP-HU19-F-03 permite editar username y guardar', (tester) async {
    when(() => datasource.getPerfil()).thenAnswer(
      (_) async => {
        'id': 'u1',
        'username': 'Luna',
        'correo': 'luna@test.com',
        'rol': 'usuario',
        'auth_provider': 'local',
        'fecha_creacion': '2026-05-01T10:00:00.000Z',
        'notificaciones_activas': true,
      },
    );

    when(
      () => datasource.updatePerfil(username: any(named: 'username')),
    ).thenAnswer(
      (_) async => {'success': true, 'message': 'Perfil actualizado'},
    );

    await tester.pumpWidget(buildTestable(PerfilPage(datasource: datasource)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'LunaBeltran');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    verify(() => datasource.updatePerfil(username: 'LunaBeltran')).called(1);
    verify(() => datasource.getPerfil()).called(greaterThan(1));
  });

  testWidgets('CP-HU19-F-04 muestra diálogo al desactivar notificaciones', (
    tester,
  ) async {
    when(() => datasource.getPerfil()).thenAnswer(
      (_) async => {
        'id': 'u1',
        'username': 'Luna',
        'correo': 'luna@test.com',
        'rol': 'usuario',
        'auth_provider': 'local',
        'fecha_creacion': '2026-05-01T10:00:00.000Z',
        'notificaciones_activas': true,
      },
    );

    await tester.pumpWidget(buildTestable(PerfilPage(datasource: datasource)));
    await tester.pumpAndSettle();

    final switches = find.byType(Switch);
    await tester.tap(switches.at(0));
    await tester.pumpAndSettle();

    expect(find.text('Desactivar notificaciones'), findsOneWidget);
    expect(
      find.textContaining('Se recomienda mantener las notificaciones activas'),
      findsOneWidget,
    );
  });

  testWidgets('CP-HU19-F-05 muestra advertencia al desactivar ubicación', (
    tester,
  ) async {
    when(() => datasource.getPerfil()).thenAnswer(
      (_) async => {
        'id': 'u1',
        'username': 'Luna',
        'correo': 'luna@test.com',
        'rol': 'usuario',
        'auth_provider': 'local',
        'fecha_creacion': '2026-05-01T10:00:00.000Z',
        'notificaciones_activas': true,
      },
    );

    await tester.pumpWidget(buildTestable(PerfilPage(datasource: datasource)));
    await tester.pumpAndSettle();

    final switches = find.byType(Switch);
    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();

    expect(find.text('Desactivar ubicación'), findsOneWidget);
    expect(
      find.textContaining(
        'mapa y las alertas de proximidad quedarán limitados',
      ),
      findsOneWidget,
    );
  });

  testWidgets('CP-HU19-F-06 abre modal de cambio de contraseña', (
    tester,
  ) async {
    when(() => datasource.getPerfil()).thenAnswer(
      (_) async => {
        'id': 'u1',
        'username': 'Luna',
        'correo': 'luna@test.com',
        'rol': 'usuario',
        'auth_provider': 'local',
        'fecha_creacion': '2026-05-01T10:00:00.000Z',
        'notificaciones_activas': true,
      },
    );

    await tester.pumpWidget(buildTestable(PerfilPage(datasource: datasource)));
    await tester.pumpAndSettle();

    final cambiarPasswordBtn = find.text('Cambiar contraseña');
    await tester.ensureVisible(cambiarPasswordBtn);
    await tester.pumpAndSettle();

    await tester.tap(cambiarPasswordBtn);
    await tester.pumpAndSettle();

    expect(find.text('Contraseña actual'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
  });
}
