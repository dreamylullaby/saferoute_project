import request from 'supertest';
import app from '../../../../app.js';

/**
 * HU-06 Integración - Registrar reporte de hurto
 *
 * Flujo real: registro de usuario → login → crear reporte con JWT válido.
 * Valida contra la base de datos real (Supabase).
 */
describe('HU-06 Integración - Registrar reporte de hurto', () => {
  let token;
  let userId;

  // Registrar y autenticar un usuario antes de los tests de reporte
  beforeAll(async () => {
    const unique = Date.now();

    const registerRes = await request(app)
      .post('/api/auth/register')
      .send({
        username: `reporter_${unique}`,
        correo: `reporter_${unique}@mail.com`,
        password: 'pass123',
      });

    expect(registerRes.status).toBe(201);
    token  = registerRes.body.token;
    userId = registerRes.body.user.id;
  });

  const baseReporte = {
    tipo_reportante: 'victima',
    fecha_incidente: '2026-04-05',
    franja_horaria:  '12:00-17:59',
    latitud:          1.21361,
    longitud:        -77.28111,
    tipo_hurto:      'atraco',
    barrio_ingresado: 'Centro',
  };

  // CP-HU06-01: Crear reporte con campos obligatorios únicamente
  test('CP-HU06-01 integral: reporte con campos obligatorios', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...baseReporte, usuario_id: userId });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data.tipo_hurto).toBe('atraco');
    expect(res.body.data.estado).toBe('activo');
    expect(res.body.data.barrio_ingresado).toBe('Centro');
  });

  // CP-HU06-02: Crear reporte con todos los campos opcionales
  test('CP-HU06-02 integral: reporte con campos opcionales', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        ...baseReporte,
        usuario_id:       userId,
        direccion:        'Calle 18 #20-30',
        descripcion:      'Me hurtaron el celular al salir del trabajo.',
        objeto_hurtado:   'celular',
        numero_agresores: '2',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.objeto_hurtado).toBe('celular');
    expect(res.body.data.numero_agresores).toBe('2');
    expect(res.body.data.descripcion).toBe('Me hurtaron el celular al salir del trabajo.');
  });

  // CP-HU06-03: Descripción mayor a 300 caracteres → 400
  test('CP-HU06-03 integral: descripción mayor a 300 caracteres retorna 400', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        ...baseReporte,
        usuario_id:  userId,
        descripcion: 'a'.repeat(301),
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('descripcion excede la longitud máxima');
  });

  // CP-HU06-04: tipo_hurto inválido → 400
  test('CP-HU06-04 integral: tipo_hurto inválido retorna 400', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        ...baseReporte,
        usuario_id: userId,
        tipo_hurto: 'robo_banco',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('tipo_hurto inválido');
  });

  // CP-HU06-05: objeto_hurtado inválido → 400
  test('CP-HU06-05 integral: objeto_hurtado inválido retorna 400', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        ...baseReporte,
        usuario_id:     userId,
        objeto_hurtado: 'reloj',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('objeto_hurtado inválido');
  });

  // CP-HU06-06: numero_agresores inválido → 400
  test('CP-HU06-06 integral: numero_agresores inválido retorna 400', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        ...baseReporte,
        usuario_id:       userId,
        numero_agresores: '9',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('numero_agresores inválido');
  });

  // CP-HU06-07: Sin token → 401
  test('CP-HU06-07 integral: sin token retorna 401', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .send({ ...baseReporte, usuario_id: userId });

    expect(res.status).toBe(401);
  });

  // CP-HU06-08: barrio_ingresado vacío → 400
  test('CP-HU06-08 integral: barrio_ingresado vacío retorna 400', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        ...baseReporte,
        usuario_id:       userId,
        barrio_ingresado: '   ',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('barrio_ingresado es obligatorio');
  });

  // CP-HU06-09: Reporte creado tiene estado 'activo' por defecto
  test('CP-HU06-09 integral: estado del reporte es activo por defecto', async () => {
    const res = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...baseReporte, usuario_id: userId });

    expect(res.status).toBe(201);
    expect(res.body.data.estado).toBe('activo');
  });

  // CP-HU06-10: Obtener reporte creado por ID
  test('CP-HU06-10 integral: obtener reporte por ID', async () => {
    const createRes = await request(app)
      .post('/api/reportes')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...baseReporte, usuario_id: userId });

    expect(createRes.status).toBe(201);
    const reporteId = createRes.body.data.id;

    const getRes = await request(app)
      .get(`/api/reportes/${reporteId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(getRes.status).toBe(200);
    expect(getRes.body.success).toBe(true);
    expect(getRes.body.data.id).toBe(reporteId);
  });
});
