import { describe, test, expect, beforeEach, jest } from '@jest/globals';
import ReportController from '../../../interfaces/controllers/reportController.js';

describe('HU-18 Backend Unitarias - ReportController', () => {
    let repository;
    let controller;
    let req;
    let res;

    beforeEach(() => {
        repository = {
            findByUsuario: jest.fn(),
            findByIdAndUsuario: jest.fn(),
            updateOwn: jest.fn(),
            crearSolicitudEliminacion: jest.fn(),
        };

        controller = new ReportController(repository);

        req = {
            user: { id: 7 },
            params: {},
            body: {},
        };

        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn(),
        };
    });

    test('CP-HU18-B-01 lista reportes del usuario autenticado', async () => {
        repository.findByUsuario.mockResolvedValue([{ id: 'rep-1' }]);

        await controller.getMisReportes(req, res);

        expect(repository.findByUsuario).toHaveBeenCalledWith(7);
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            success: true,
            data: [{ id: 'rep-1' }],
        });
    });

    test('CP-HU18-B-02 obtiene detalle de reporte propio', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({ id: 'rep-1' });

        await controller.getMiReporteById(req, res);

        expect(repository.findByIdAndUsuario).toHaveBeenCalledWith('rep-1', 7);
        expect(res.status).toHaveBeenCalledWith(200);
    });

    test('CP-HU18-B-03 rechaza detalle de reporte ajeno o inexistente', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue(null);

        await controller.getMiReporteById(req, res);

        expect(repository.findByIdAndUsuario).toHaveBeenCalledWith('rep-1', 7);
        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: 'Reporte no encontrado o no te pertenece',
        });
    });

    test('CP-HU18-B-04 edita reporte propio activo exitosamente', async () => {
        req.params = { id: 'rep-1' };

        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });

        req.body = {
            tipo_reportante: 'victima',
            franja_horaria: '12:00-17:59',
            tipo_hurto: 'fleteo',
            objeto_hurtado: 'celular',
            numero_agresores: '2',
            descripcion: 'Actualizado',
            barrio_ingresado: 'Centro',
            direccion: 'Calle 10',
        };

        repository.updateOwn.mockResolvedValue({
            id: 'rep-1',
            ...req.body,
        });

        await controller.updateOwn(req, res);

        expect(repository.findByIdAndUsuario).toHaveBeenCalledWith('rep-1', 7);
        expect(repository.updateOwn).toHaveBeenCalledWith(
            'rep-1',
            7,
            expect.objectContaining({
                tipo_reportante: 'victima',
                franja_horaria: '12:00-17:59',
                tipo_hurto: 'fleteo',
                objeto_hurtado: 'celular',
                numero_agresores: '2',
                descripcion: 'Actualizado',
                barrio_ingresado: 'Centro',
                direccion: 'Calle 10',
            })
        );
        expect(res.status).toHaveBeenCalledWith(200);
    });

    test('CP-HU18-B-05 rechaza update sin campos', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        req.body = {};

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: 'No se enviaron campos para actualizar',
        });
    });

    test('CP-HU18-B-06 rechaza edición de reporte no activo', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'oculto',
        });
        req.body = { tipo_hurto: 'atraco' };

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: 'Solo se pueden editar reportes activos',
        });
    });

    test('CP-HU18-B-07 rechaza tipo_reportante inválido', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        req.body = { tipo_reportante: 'anonimo' };

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json.mock.calls[0][0].message).toContain('tipo_reportante inválido');
    });

    test('CP-HU18-B-08 rechaza franja_horaria inválida', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        req.body = { franja_horaria: '25:00-30:00' };

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json.mock.calls[0][0].message).toContain('franja_horaria inválida');
    });

    test('CP-HU18-B-09 rechaza tipo_hurto inválido', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        req.body = { tipo_hurto: 'invalido' };

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json.mock.calls[0][0].message).toContain('tipo_hurto inválido');
    });

    test('CP-HU18-B-10 rechaza objeto_hurtado inválido', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        req.body = { objeto_hurtado: 'moto' };

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json.mock.calls[0][0].message).toContain('objeto_hurtado inválido');
    });

    test('CP-HU18-B-11 rechaza numero_agresores inválido', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        req.body = { numero_agresores: '10' };

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json.mock.calls[0][0].message).toContain('numero_agresores inválido');
    });

    test('CP-HU18-B-12 rechaza descripción mayor a 300 caracteres', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        req.body = { descripcion: 'a'.repeat(301) };

        await controller.updateOwn(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: 'descripcion excede 300 caracteres',
        });
    });

    test('CP-HU18-B-13 solicita eliminación exitosamente', async () => {
        req.params = { id: 'rep-1' };

        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });

        req.body = { motivo: 'Reporte duplicado' };

        repository.crearSolicitudEliminacion.mockResolvedValue({
            id: 'sol-1',
            motivo: 'Reporte duplicado',
        });

        await controller.solicitarEliminacion(req, res);

        expect(repository.findByIdAndUsuario).toHaveBeenCalledWith('rep-1', 7);
        expect(repository.crearSolicitudEliminacion).toHaveBeenCalledWith('rep-1', 7, 'Reporte duplicado');
        expect(res.status).toHaveBeenCalledWith(201);
    });

    test('CP-HU18-B-14 rechaza eliminación de reporte ya eliminado', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'eliminado',
        });

        await controller.solicitarEliminacion(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: 'El reporte ya está eliminado',
        });
    });

    test('CP-HU18-B-15 rechaza segunda solicitud pendiente', async () => {
        req.params = { id: 'rep-1' };
        repository.findByIdAndUsuario.mockResolvedValue({
            id: 'rep-1',
            estado: 'activo',
        });
        repository.crearSolicitudEliminacion.mockRejectedValue(
            new Error('Ya existe una solicitud pendiente')
        );

        await controller.solicitarEliminacion(req, res);

        expect(res.status).toHaveBeenCalledWith(409);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: 'Ya existe una solicitud pendiente',
        });
    });
});