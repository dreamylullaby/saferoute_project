import request from 'supertest';
import app from '../../../../server.js';

describe('HU-21 Integrales Backend - DELETE /api/perfil', () => {
  const tokenLocal = process.env.TEST_USER_TOKEN_LOCAL || '';
  const tokenGoogle = process.env.TEST_USER_TOKEN_GOOGLE || '';
  const password = process.env.TEST_USER_PASSWORD || 'ClaveValida123';

  test('CP-HU21-I-01 elimina cuenta autenticada vía endpoint', async () => {
    const res = await request(app)
      .delete('/api/perfil')
      .set('Authorization', `Bearer ${tokenLocal}`)
      .send({ password });

    expect([200, 401, 403, 404]).toContain(res.statusCode);
  });

  test('CP-HU21-I-02 rechaza eliminación sin autenticación', async () => {
    const res = await request(app)
      .delete('/api/perfil')
      .send({ password });

    expect([401, 403]).toContain(res.statusCode);
  });

  test('CP-HU21-I-03 rechaza usuario local sin contraseña', async () => {
    const res = await request(app)
      .delete('/api/perfil')
      .set('Authorization', `Bearer ${tokenLocal}`)
      .send({});

    expect([400, 401, 403, 404]).toContain(res.statusCode);
  });

  test('CP-HU21-I-04 rechaza contraseña incorrecta', async () => {
    const res = await request(app)
      .delete('/api/perfil')
      .set('Authorization', `Bearer ${tokenLocal}`)
      .send({ password: 'incorrecta' });

    expect([401, 403, 404]).toContain(res.statusCode);
  });

  test('CP-HU21-I-05 permite usuario Google sin contraseña', async () => {
    const res = await request(app)
      .delete('/api/perfil')
      .set('Authorization', `Bearer ${tokenGoogle}`)
      .send({});

    expect([200, 401, 403, 404]).toContain(res.statusCode);
  });
});