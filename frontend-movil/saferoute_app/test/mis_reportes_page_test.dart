import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civictrackio_app/features/user/presentation/pages/mis_reportes_page.dart';

class FakeMisReportesDatasource implements MisReportesDatasource {
  FakeMisReportesDatasource({
    this.reportes = const [],
    this.errorEnCarga = false,
    this.errorEnEliminar = false,
    this.errorEnActualizar = false,
  });

  final List<Map<String, dynamic>> reportes;
  final bool errorEnCarga;
  final bool errorEnEliminar;
  final bool errorEnActualizar;

  int obtenerCalls = 0;
  int eliminarCalls = 0;
  int actualizarCalls = 0;

  int? ultimoReporteIdEliminar;
  String? ultimoMotivoEliminar;

  int? ultimoReporteIdActualizar;
  Map<String, dynamic>? ultimoBodyActualizar;

  @override
  Future<List<Map<String, dynamic>>> obtenerMisReportes() async {
    obtenerCalls++;
    if (errorEnCarga) {
      throw Exception('Error al cargar mis reportes');
    }
    return reportes;
  }

  @override
  Future<void> solicitarEliminacionReporte(
    int reporteId, {
    String? motivo,
  }) async {
    eliminarCalls++;
    ultimoReporteIdEliminar = reporteId;
    ultimoMotivoEliminar = motivo;
    if (errorEnEliminar) {
      throw Exception('Ya existe una solicitud pendiente');
    }
  }

  @override
  Future<void> actualizarReporte({
    required int reporteId,
    required Map<String, dynamic> body,
  }) async {
    actualizarCalls++;
    ultimoReporteIdActualizar = reporteId;
    ultimoBodyActualizar = body;
    if (errorEnActualizar) {
      throw Exception('Error al actualizar');
    }
  }
}

Future<void> pumpMisReportes(
  WidgetTester tester, {
  required MisReportesDatasource datasource,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        '/reportar': (_) => const Scaffold(body: Text('Formulario reportar')),
      },
      home: MisReportesPage(datasource: datasource),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Map<String, dynamic> reporteEjemplo({
  int id = 1,
  String tipo = 'atraco',
  String estado = 'activo',
  String fecha = '2026-05-01',
  String barrio = 'Centro',
  int comuna = 1,
  String franja = '06:00-11:59',
  String descripcion = 'Hurto en vía pública',
  String? vereda,
  bool esRural = false,
}) {
  return {
    'id': id,
    'tipo_hurto': tipo,
    'estado': estado,
    'fecha_incidente': fecha,
    'barrio_ingresado': barrio,
    'comuna': comuna,
    'franja_horaria': franja,
    'descripcion': descripcion,
    'vereda': vereda,
    'es_rural': esRural,
    'objeto_hurtado': 'celular',
    'numero_agresores': '2',
    'tipo_reportante': 'victima',
    'direccion': 'Calle 10 # 20-30',
  };
}

void main() {
  group('HU-18 Frontend Flutter - Mis reportes', () {
    testWidgets('CP-HU18-F-01 muestra estado vacío', (tester) async {
      final fake = FakeMisReportesDatasource(reportes: []);

      await pumpMisReportes(tester, datasource: fake);

      expect(find.text('Aún no has registrado ningún reporte'), findsOneWidget);
      expect(
        find.text('Cuando registres un incidente, aparecerá aquí.'),
        findsOneWidget,
      );
      expect(find.text('Reportar incidente'), findsOneWidget);
      expect(fake.obtenerCalls, 1);
    });

    testWidgets('CP-HU18-F-02 muestra listado resumido de reportes', (
      tester,
    ) async {
      final fake = FakeMisReportesDatasource(reportes: [reporteEjemplo()]);

      await pumpMisReportes(tester, datasource: fake);

      expect(find.text('Atraco'), findsOneWidget);
      expect(find.text('activo'), findsOneWidget);
      expect(find.text('01/05/2026'), findsOneWidget);
      expect(find.textContaining('Centro · Comuna 1'), findsOneWidget);
      expect(find.text('06:00-11:59'), findsOneWidget);
      expect(find.text('Hurto en vía pública'), findsOneWidget);
      expect(find.text('Ver'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('CP-HU18-F-03 muestra acciones de reporte activo', (
      tester,
    ) async {
      final fake = FakeMisReportesDatasource(
        reportes: [reporteEjemplo(estado: 'activo')],
      );

      await pumpMisReportes(tester, datasource: fake);

      expect(find.text('Ver'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('CP-HU18-F-04 oculta editar y eliminar en reporte oculto', (
      tester,
    ) async {
      final fake = FakeMisReportesDatasource(
        reportes: [reporteEjemplo(estado: 'oculto')],
      );

      await pumpMisReportes(tester, datasource: fake);

      expect(find.text('Ver'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Eliminar'), findsNothing);
    });

    testWidgets('CP-HU18-F-05 muestra detalle del reporte desde el listado', (
      tester,
    ) async {
      final fake = FakeMisReportesDatasource(reportes: [reporteEjemplo()]);

      await pumpMisReportes(tester, datasource: fake);

      await tester.tap(find.text('Ver'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Detalle del reporte'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Atraco'), findsWidgets);
      expect(find.text('Descripción'), findsOneWidget);
      expect(find.text('Hurto en vía pública'), findsWidgets);
    });

    testWidgets('CP-HU18-F-06 solicita eliminación con motivo', (tester) async {
      final fake = FakeMisReportesDatasource(reportes: [reporteEjemplo()]);

      await pumpMisReportes(tester, datasource: fake);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Reporte duplicado');
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();

      expect(fake.eliminarCalls, 1);
      expect(fake.ultimoReporteIdEliminar, 1);
      expect(fake.ultimoMotivoEliminar, 'Reporte duplicado');
      expect(
        find.text('Solicitud enviada. Un administrador la revisará.'),
        findsOneWidget,
      );
    });

    testWidgets('CP-HU18-F-07 solicita eliminación sin motivo', (tester) async {
      final fake = FakeMisReportesDatasource(reportes: [reporteEjemplo()]);

      await pumpMisReportes(tester, datasource: fake);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();

      expect(fake.eliminarCalls, 1);
      expect(fake.ultimoMotivoEliminar, '');
      expect(
        find.text('Solicitud enviada. Un administrador la revisará.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'CP-HU18-F-08 muestra error al fallar solicitud de eliminación',
      (tester) async {
        final fake = FakeMisReportesDatasource(
          reportes: [reporteEjemplo()],
          errorEnEliminar: true,
        );

        await pumpMisReportes(tester, datasource: fake);

        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Motivo');
        await tester.tap(find.text('Enviar solicitud'));
        await tester.pumpAndSettle();

        expect(find.text('Ya existe una solicitud pendiente'), findsOneWidget);
      },
    );

    testWidgets('CP-HU18-F-09 abre formulario de reporte desde estado vacío', (
      tester,
    ) async {
      final fake = FakeMisReportesDatasource(reportes: []);

      await pumpMisReportes(tester, datasource: fake);

      await tester.tap(find.text('Reportar incidente'));
      await tester.pumpAndSettle();

      expect(find.text('Formulario reportar'), findsOneWidget);
    });

    testWidgets('CP-HU18-F-10 carga error inicial si datasource falla', (
      tester,
    ) async {
      final fake = FakeMisReportesDatasource(errorEnCarga: true);

      await pumpMisReportes(tester, datasource: fake);

      expect(find.text('Aún no has registrado ningún reporte'), findsOneWidget);
    });

    testWidgets('CP-HU18-F-11 muestra detalle con campos completos', (
      tester,
    ) async {
      final fake = FakeMisReportesDatasource(
        reportes: [
          reporteEjemplo(
            tipo: 'raponazo',
            fecha: '2026-05-10',
            barrio: 'San Fernando',
            comuna: 3,
            franja: '12:00-17:59',
            descripcion: 'Se llevó el celular',
          ),
        ],
      );

      await pumpMisReportes(tester, datasource: fake);

      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle del reporte'), findsOneWidget);
      expect(find.text('Raponazo'), findsWidgets);
      expect(find.text('San Fernando'), findsWidgets);
      expect(find.text('Comuna 3'), findsWidgets);
      expect(find.text('Se llevó el celular'), findsWidgets);
    });

    testWidgets(
      'CP-HU18-F-12 edita reporte exitosamente desde la pantalla real',
      (tester) async {
        final fake = FakeMisReportesDatasource(reportes: [reporteEjemplo()]);

        await pumpMisReportes(tester, datasource: fake);

        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();

        expect(find.text('Editar reporte'), findsOneWidget);
        expect(find.text('Guardar cambios'), findsOneWidget);

        final fechaField = find.byType(TextFormField).first;
        await tester.enterText(fechaField, '01/05/2026');
        await tester.pumpAndSettle();

        final guardarBtn = find.text('Guardar cambios');
        await tester.ensureVisible(guardarBtn);
        await tester.pumpAndSettle();
        await tester.tap(guardarBtn);
        await tester.pumpAndSettle();

        expect(fake.actualizarCalls, 1);
        expect(fake.ultimoReporteIdActualizar, 1);
        expect(find.text('Reporte actualizado'), findsOneWidget);
      },
    );
  });
}
