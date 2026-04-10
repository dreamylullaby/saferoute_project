import request from 'supertest';
import app from '../../../../app.js';

describe('HU-05 Integración - Login local', () => {
  test('CP-HU05-01 integral: login exitoso', async () => {
    const unique = Date.now();

    const registerPayload = {
      username: `login_${unique}`,
      correo: `login_${unique}@mail.com`,
      password: 'pass123',
    };

    await request(app).post('/api/auth/register').send(registerPayload);

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        correo: registerPayload.correo,
        password: registerPayload.password,
      });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('user');
    expect(res.body.user.correo).toBe(registerPayload.correo);
  });

  test('CP-HU05-02 integral: contraseña incorrecta', async () => {
    const unique = Date.now();

    const registerPayload = {
      username: `wrong_${unique}`,
      correo: `wrong_${unique}@mail.com`,
      password: 'pass123',
    };

    await request(app).post('/api/auth/register').send(registerPayload);

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        correo: registerPayload.correo,
        password: 'otra123',
      });

    expect(res.status).toBe(401);
  });
});
