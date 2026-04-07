import request from 'supertest';
import app from '../../../../app.js';

describe('HU-04 Integración - Registro local', () => {
  test('CP-HU04-08 integral: registro exitoso', async () => {
    const unique = Date.now();

    const payload = {
      username: `luna_${unique}`,
      correo: `luna_${unique}@mail.com`,
      password: 'pass123',
    };

    const res = await request(app)
      .post('/api/auth/register')
      .send(payload);

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('user');
    expect(res.body.user.correo).toBe(payload.correo);
    expect(res.body.user.rol).toBe('usuario');
  });

  test('CP-HU04-09 integral: correo ya registrado', async () => {
    const unique = Date.now();

    const base = {
      username: `luna_a_${unique}`,
      correo: `luna_dup_${unique}@mail.com`,
      password: 'pass123',
    };

    await request(app).post('/api/auth/register').send(base);

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        ...base,
        username: `otro_apodo_${unique}`,
      });

    expect(res.status).toBe(409);
    expect(res.body).toEqual({
      message: 'El correo ya está registrado',
    });
  });

  test('CP-HU04-10 integral: apodo duplicado', async () => {
    const unique = Date.now();

    const base = {
      username: `mismo_apodo_${unique}`,
      correo: `uno_${unique}@mail.com`,
      password: 'pass123',
    };

    await request(app).post('/api/auth/register').send(base);

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        ...base,
        correo: `dos_${unique}@mail.com`,
      });

    expect(res.status).toBe(409);
    expect(res.body).toEqual({
      message: 'El apodo ya está en uso',
    });
  });
});
