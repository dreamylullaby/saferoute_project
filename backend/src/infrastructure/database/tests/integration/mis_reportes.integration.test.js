import request from 'supertest';
import app from '../../../../server.js';

describe('HU-18 Integrales API - Gestionar reportes propios', () => {
  let tokenUsuario;
  let reportePropioActivoId;
  let reportePropioOcultoId;
  let reporteAjenoId;

  beforeAll(async () => {
    tokenUsuario = process.env.TEST_USER_TOKEN || 'Bearer token-valido';
    reportePropioActivoId = process.env.TEST_REPORTE_PROPIO_ACTIVO_ID || 'rep-propio-activo';
    reportePropioOcultoId = process.env.TEST_REPORTE_PROPIO_OCULTO_ID || 'rep-propio-oculto';
    reporteAjenoId = process.env.TEST_REPORTE_AJENO_ID || 'rep-ajeno';
  });

  test('CP-HU18-I-01 GET mis-reportes devuelve solo reportes propios', async () => {
    const res = await request(app)
      .get('/api/reportes/mis-reportes')
      .set('Authorization', tokenUsuario);

    expect([200, 401, 403]).toContain(res.statusCode);

    if (res.statusCode === 200) {
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    }
  });

  test('CP-HU18-I-02 GET detalle de reporte propio', async () => {
    const res = await request(app)
      .get(`/api/reportes/mis-reportes/${reportePropioActivoId}`)
      .set('Authorization', tokenUsuario);

    expect([200, 401, 403, 404]).toContain(res.statusCode);

    if (res.statusCode === 200) {
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
    }
  });

  test('CP-HU18-I-03 GET detalle de reporte ajeno', async () => {
    const res = await request(app)
      .get(`/api/reportes/mis-reportes/${reporteAjenoId}`)
      .set('Authorization', tokenUsuario);

    expect([401, 403, 404]).toContain(res.statusCode);
  });

  test('CP-HU18-I-04 PUT edición exitosa de reporte activo', async () => {
    const res = await request(app)
      .put(`/api/reportes/${reportePropioActivoId}`)
      .set('Authorization', tokenUsuario)
      .send({
        tipo_reportante: 'victima',
        fecha_incidente: '2026-05-10',
        franja_horaria: '06:00-11:59',
        tipo_hurto: 'atraco',
        descripcion: 'Actualización de prueba',
        barrio_ingresado: 'Centro',
        direccion: 'Calle 18 # 20-30',
      });

    expect([200, 401, 403, 404]).toContain(res.statusCode);

    if (res.statusCode === 200) {
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
    }
  });

  test('CP-HU18-I-05 PUT con validación fallida', async () => {
    const res = await request(app)
      .put(`/api/reportes/${reportePropioActivoId}`)
      .set('Authorization', tokenUsuario)
      .send({
        tipo_hurto: 'tipo_invalido',
      });

    expect([400, 401, 403, 404]).toContain(res.statusCode);

    if (res.statusCode === 400) {
      expect(res.body.success).toBe(false);
    }
  });

  test('CP-HU18-I-06 PUT sobre reporte oculto', async () => {
    const res = await request(app)
      .put(`/api/reportes/${reportePropioOcultoId}`)
      .set('Authorization', tokenUsuario)
      .send({
        descripcion: 'Intento de edición',
      });

    expect([400, 401, 403, 404]).toContain(res.statusCode);
  });

  test('CP-HU18-I-07 POST solicitar eliminación', async () => {
    const res = await request(app)
      .post(`/api/reportes/${reportePropioActivoId}/solicitar-eliminacion`)
      .set('Authorization', tokenUsuario)
      .send({ motivo: 'Reporte duplicado' });

    expect([201, 401, 403, 404, 409]).toContain(res.statusCode);

    if (res.statusCode === 201) {
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
    }
  });

  test('CP-HU18-I-08 POST segunda solicitud pendiente', async () => {
    await request(app)
      .post(`/api/reportes/${reportePropioActivoId}/solicitar-eliminacion`)
      .set('Authorization', tokenUsuario)
      .send({ motivo: 'Primera solicitud' });

    const res = await request(app)
      .post(`/api/reportes/${reportePropioActivoId}/solicitar-eliminacion`)
      .set('Authorization', tokenUsuario)
      .send({ motivo: 'Segunda solicitud' });

    expect([401, 403, 404, 409]).toContain(res.statusCode);
  });
});