import { jest } from '@jest/globals';

jest.unstable_mockModule('../dbScript/db.js', () => ({
    default: {
        from: jest.fn(),
        rpc: jest.fn(),
    },
}));

const supabase = (await import('../dbScript/db.js')).default;
const { default: CreateReport } = await import('../../../application/use-cases/createReport.js');
const { default: ReportRepositoryImpl } = await import('../repositoriesImplementation/reportRepositoryImpl.js');
const { default: ReportController } = await import('../../../interfaces/controllers/reportController.js');

describe('HU-06 Backend - createReport', () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    const validData = {
        usuario_id: 'uuid-user-123',
        tipo_reportante: 'victima',
        fecha_incidente: '2026-04-05',
        franja_horaria: '12:00-17:59',
        latitud: 1.21361,
        longitud: -77.28111,
        direccion: 'Calle 18 #20-30',
        tipo_hurto: 'atraco',
        barrio_ingresado: 'Centro',
        descripcion: 'Me hurtaron el celular al salir del trabajo.',
        objeto_hurtado: 'celular',
        numero_agresores: '2',
    };

    test('CP-HU06-05: registrar con datos opcionales', async () => {
        const createMock = jest.fn().mockResolvedValue({
            id: 'rep-001',
            ...validData,
            estado: 'activo',
        });

        const repository = { create: createMock };
        const useCase = new CreateReport(repository);

        const result = await useCase.execute(validData);

        expect(createMock).toHaveBeenCalledWith({
            ...validData,
            barrio_ingresado: 'Centro',
            estado: 'activo',
        });
        expect(result).toEqual({
            id: 'rep-001',
            ...validData,
            estado: 'activo',
        });
    });

    test('CP-HU06-06: registrar sin datos opcionales', async () => {
        const createMock = jest.fn().mockResolvedValue({
            id: 'rep-002',
            usuario_id: 'uuid-user-123',
            tipo_reportante: 'victima',
            fecha_incidente: '2026-04-05',
            franja_horaria: '12:00-17:59',
            latitud: 1.21361,
            longitud: -77.28111,
            tipo_hurto: 'atraco',
            barrio_ingresado: 'Centro',
            estado: 'activo',
            descripcion: null,
            objeto_hurtado: null,
            numero_agresores: null,
        });

        const repository = { create: createMock };
        const useCase = new CreateReport(repository);

        const data = {
            usuario_id: 'uuid-user-123',
            tipo_reportante: 'victima',
            fecha_incidente: '2026-04-05',
            franja_horaria: '12:00-17:59',
            latitud: 1.21361,
            longitud: -77.28111,
            tipo_hurto: 'atraco',
            barrio_ingresado: ' Centro ',
        };

        const result = await useCase.execute(data);

        expect(createMock).toHaveBeenCalledWith({
            ...data,
            barrio_ingresado: 'Centro',
            estado: 'activo',
        });
        expect(result.id).toBe('rep-002');
    });

    test('CP-HU06-07: persistencia de datos opcionales', async () => {
        const insertChain = {
            insert: jest.fn().mockReturnThis(),
            select: jest.fn().mockResolvedValue({
                data: [{
                    id: 'rep-003',
                    ...validData,
                    estado: 'activo',
                }],
                error: null,
            }),
        };

        supabase.from.mockReturnValueOnce(insertChain);

        const repository = new ReportRepositoryImpl();
        const result = await repository.create({
            ...validData,
            estado: 'activo',
        });

        expect(supabase.from).toHaveBeenCalledWith('reportes');
        expect(insertChain.insert).toHaveBeenCalledWith([{
            usuario_id: validData.usuario_id,
            tipo_reportante: validData.tipo_reportante,
            fecha_incidente: validData.fecha_incidente,
            franja_horaria: validData.franja_horaria,
            latitud: validData.latitud,
            longitud: validData.longitud,
            direccion: validData.direccion,
            tipo_hurto: validData.tipo_hurto,
            descripcion: validData.descripcion,
            objeto_hurtado: validData.objeto_hurtado,
            numero_agresores: validData.numero_agresores,
            estado: 'activo',
            barrio_ingresado: validData.barrio_ingresado,
        }]);
        expect(result.id).toBe('rep-003');
    });

    test('CP-HU06-08: manejo de datos inválidos opcionales', async () => {
        const repository = { create: jest.fn() };
        const useCase = new CreateReport(repository);

        const invalidData = {
            ...validData,
            objeto_hurtado: 'reloj',
        };

        await expect(useCase.execute(invalidData))
            .rejects
            .toThrow('objeto_hurtado inválido');

        expect(repository.create).not.toHaveBeenCalled();
    });

    test('CP-HU06-09: validar valor inválido en numero_agresores', async () => {
        const repository = { create: jest.fn() };
        const useCase = new CreateReport(repository);

        const invalidData = {
            ...validData,
            numero_agresores: '5',
        };

        await expect(useCase.execute(invalidData))
            .rejects
            .toThrow('numero_agresores inválido');

        expect(repository.create).not.toHaveBeenCalled();
    });

    test('CP-HU06-10: guardar descripción válida', async () => {
        const createMock = jest.fn().mockImplementation(async (payload) => ({
            id: 'rep-010',
            ...payload,
        }));

        const repository = { create: createMock };
        const useCase = new CreateReport(repository);

        const data = {
            ...validData,
            descripcion: 'Descripción válida con menos de 300 caracteres.',
        };

        const result = await useCase.execute(data);

        expect(createMock).toHaveBeenCalledWith({
            ...data,
            barrio_ingresado: 'Centro',
            estado: 'activo',
        });
        expect(result.descripcion).toBe('Descripción válida con menos de 300 caracteres.');
    });

    test('CP-HU06-03-backend: descripción mayor a 300 caracteres', async () => {
        const repository = { create: jest.fn() };
        const useCase = new CreateReport(repository);

        const invalidData = {
            ...validData,
            descripcion: 'a'.repeat(301),
        };

        await expect(useCase.execute(invalidData))
            .rejects
            .toThrow('descripcion excede la longitud máxima de 300 caracteres');

        expect(repository.create).not.toHaveBeenCalled();
    });

    test('CP-HU06-08-controller: retorna 400 cuando hay error de validación', async () => {
        const repository = { create: jest.fn() };
        const controller = new ReportController(repository);

        const req = {
            body: {
                ...validData,
                numero_agresores: '9',
            },
        };

        const res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn(),
        };

        await controller.create(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: expect.stringContaining('numero_agresores inválido'),
        });
    });

    test('CP-HU06-05-controller: retorna 201 cuando crea reporte correctamente', async () => {
        const repository = {
            create: jest.fn().mockResolvedValue({
                id: 'rep-201',
                ...validData,
                estado: 'activo',
            }),
            findById: jest.fn(),
            findAll: jest.fn(),
        };

        const controller = new ReportController(repository);

        const req = { body: validData };
        const res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn(),
        };

        await controller.create(req, res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(res.json).toHaveBeenCalledWith({
            success: true,
            message: 'Reporte registrado con éxito.',
            data: {
                id: 'rep-201',
                ...validData,
                estado: 'activo',
            },
        });
    });
});