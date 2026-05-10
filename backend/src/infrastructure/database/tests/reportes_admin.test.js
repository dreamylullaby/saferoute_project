import { jest, describe, beforeEach, test, expect } from '@jest/globals';

jest.unstable_mockModule('../dbScript/db.js', () => ({
    default: {
        from: jest.fn(),
    },
}));

const supabase = (await import('../dbScript/db.js')).default;
const { default: ReportRepositoryImpl } = await import('../repositoriesImplementation/ReportRepositoryImpl.js');
const { default: ReportController } = await import('../../../interfaces/controllers/reportController.js');

describe('HU-10 Backend - Reportes admin', () => {
    let repository;
    let controller;
    let req;
    let res;

    beforeEach(() => {
        jest.clearAllMocks();
        repository = new ReportRepositoryImpl();
        controller = new ReportController(repository);
        req = { query: {}, params: {} };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn(),
        };
    });

    function mockAdminQuery(data, count = 0, error = null) {
        const result = { data, count, error };
        const query = {
            select: jest.fn().mockReturnThis(),
            neq: jest.fn().mockReturnThis(),
            order: jest.fn().mockReturnThis(),
            range: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            gte: jest.fn().mockReturnThis(),
            lte: jest.fn().mockReturnThis(),
            then: (resolve, reject) => Promise.resolve(result).then(resolve, reject),
            catch: (reject) => Promise.resolve(result).catch(reject),
            finally: (cb) => Promise.resolve(result).finally(cb),
        };
        supabase.from.mockReturnValue(query);
        return query;
    }

    function mockFindByIdQuery(data, error = null) {
        const query = {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            maybeSingle: jest.fn().mockResolvedValue({ data, error }),
        };
        supabase.from.mockReturnValue(query);
        return query;
    }

    function ok(name) {
        console.log(`✅ PASS: ${name}`);
    }

    test('CP-HU10-BE-01 lista reportes admin con paginación', async () => {
        mockAdminQuery(
            [{ id: 'rep-1', tipo_hurto: 'atraco', barrio_ingresado: 'Centro' }],
            1,
            null
        );

        const result = await repository.findForAdmin({ page: 1, limit: 10 });

        expect(result.data).toHaveLength(1);
        expect(result.total).toBe(1);
        expect(result.page).toBe(1);
        expect(result.totalPages).toBe(1);
        ok('CP-HU10-BE-01 lista reportes admin con paginación');
    });

    test('CP-HU10-BE-02 filtra reportes admin por campos enviados', async () => {
        const query = mockAdminQuery([], 0, null);

        await repository.findForAdmin({
            page: 1,
            limit: 10,
            tipo_hurto: 'atraco',
            estado: 'activo',
            fechaDesde: '2026-04-01',
            fechaHasta: '2026-04-30',
            comuna: '1',
        });

        expect(query.eq).toHaveBeenCalledWith('tipo_hurto', 'atraco');
        expect(query.eq).toHaveBeenCalledWith('estado', 'activo');
        expect(query.eq).toHaveBeenCalledWith('comuna', 1);
        expect(query.gte).toHaveBeenCalledWith('fecha_incidente', '2026-04-01');
        expect(query.lte).toHaveBeenCalledWith('fecha_incidente', '2026-04-30');
        ok('CP-HU10-BE-02 filtra reportes admin por campos enviados');
    });

    test('CP-HU10-BE-03 obtiene detalle por id', async () => {
        mockFindByIdQuery({ id: 'rep-1', barrio_ingresado: 'Centro' });

        const result = await repository.findById('rep-1');

        expect(result.id).toBe('rep-1');
        expect(result.barrio_ingresado).toBe('Centro');
        ok('CP-HU10-BE-03 obtiene detalle por id');
    });

    test('CP-HU10-BE-04 error al listar reportes admin', async () => {
        mockAdminQuery(null, 0, { message: 'db error' });

        await expect(repository.findForAdmin({ page: 1, limit: 10 })).rejects.toThrow(
            'Error al obtener reportes admin: db error'
        );
        ok('CP-HU10-BE-04 error al listar reportes admin');
    });

    test('CP-HU10-BE-05 error al consultar detalle por id inexistente', async () => {
        mockFindByIdQuery(null, null);

        await expect(repository.findById('rep-x')).rejects.toThrow(
            'Reporte con id rep-x no encontrado'
        );
        ok('CP-HU10-BE-05 error al consultar detalle por id inexistente');
    });

    test('CP-HU10-BE-06 controller responde 200 al listar admin', async () => {
        controller = new ReportController({
            findForAdmin: jest.fn().mockResolvedValue({
                data: [{ id: 'rep-1' }],
                total: 1,
                page: 1,
                totalPages: 1,
            }),
        });

        req.query = { page: '1', limit: '10' };

        // CAMBIA este nombre por el método real de tu controller
        await controller.listAdmin(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            success: true,
            data: [{ id: 'rep-1' }],
            total: 1,
            page: 1,
            totalPages: 1,
        });

        ok('CP-HU10-BE-06 controller responde 200 al listar admin');
    });

    test('CP-HU10-BE-07 controller responde 200 al obtener detalle', async () => {
        controller = new ReportController({
            findById: jest.fn().mockResolvedValue({ id: 'rep-1' }),
        });

        req.params = { id: 'rep-1' };

        await controller.getById(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            success: true,
            data: { id: 'rep-1' },
        });
        ok('CP-HU10-BE-07 controller responde 200 al obtener detalle');
    });
});