import { jest } from "@jest/globals";

// ✅ mocks en ESM (ANTES de importar el controlador)
jest.unstable_mockModule("../dbScript/db.js", () => ({
  default: {
    from: jest.fn()
  }
}));

jest.unstable_mockModule("bcrypt", () => ({
  default: {
    compare: jest.fn()
  }
}));

jest.unstable_mockModule("../../../config/jwt.js", () => ({
  generateToken: jest.fn()
}));

// ✅ importar después de mockear
const { loginLocal } = await import("../../../interfaces/controllers/userController.js");
const bcrypt = (await import("bcrypt")).default;
const db = (await import("../dbScript/db.js")).default;
const jwtMock = await import("../../../config/jwt.js");
const { generateToken } = jwtMock;
import jwt from "jsonwebtoken";

describe("HU-02 Backend - loginLocal", () => {

  let req, res;

  beforeEach(() => {
    req = { body: {} };

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
  });

  test("CP-HU02-06: Usuario no encontrado", async () => {
    req.body = {
      correo: "noexiste@fake.com",
      password: "123456"
    };

    db.from.mockReturnValue({
      select: () => ({
        eq: () => ({
          eq: () => ({
            single: async () => ({ data: null, error: true })
          })
        })
      })
    });

    await loginLocal(req, res);

    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({
      message: "Usuario no encontrado"
    });
  });

  test("CP-HU02-07: Contraseña incorrecta", async () => {
    req.body = {
      correo: "user@pasto.com",
      password: "wrongpass"
    };

    db.from.mockReturnValue({
      select: () => ({
        eq: () => ({
          eq: () => ({
            single: async () => ({
              data: {
                id: "1",
                username: "test",
                correo: "user@pasto.com",
                rol: "usuario",
                password_hash: "hash"
              },
              error: null
            })
          })
        })
      })
    });

    bcrypt.compare.mockResolvedValue(false);

    await loginLocal(req, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({
      message: "Contraseña incorrecta"
    });
  });

  test("CP-HU02-05: Login exitoso", async () => {
    req.body = {
      correo: "user@pasto.com",
      password: "pass123"
    };

    db.from.mockReturnValue({
      select: () => ({
        eq: () => ({
          eq: () => ({
            single: async () => ({
              data: {
                id: "1",
                username: "luna",
                correo: "user@pasto.com",
                rol: "usuario",
                password_hash: "hash"
              },
              error: null
            })
          })
        })
      })
    });

    bcrypt.compare.mockResolvedValue(true);
    generateToken.mockReturnValue("fake-jwt");

    await loginLocal(req, res);

    expect(res.json).toHaveBeenCalledWith({
      user: {
        id: "1",
        username: "luna",
        correo: "user@pasto.com",
        rol: "usuario"
      },
      token: "fake-jwt"
    });
  });

  test("CP-HU02-08: Generación y verificación de JWT", () => {

    const SECRET = "test_secret";

    const payload = {
      id: "123",
      rol: "usuario"
    };

    console.log("\n--- CP-HU02-08 ---");
    console.log("Entrada:", payload);
    console.log("Resultado esperado: token válido y verificable");

    const token = jwt.sign(payload, SECRET, { expiresIn: "8h" });

    console.log("Token generado:", token);

    const decoded = jwt.verify(token, SECRET);

    console.log("Payload decodificado:", decoded);

    expect(decoded.id).toBe(payload.id);
    expect(decoded.rol).toBe(payload.rol);

  });
  test("CP-HU02-09: Verificación real de hash con bcrypt", async () => {

    // 🔥 obtener bcrypt REAL ignorando el mock
    const realBcrypt = jest.requireActual("bcrypt");

    const password = "pass123";

    console.log("\n--- CP-HU02-09 ---");
    console.log("Entrada:", password);
    console.log("Resultado esperado: comparación válida con hash");

    // 🔐 generar hash REAL
    const hash = await realBcrypt.hash(password, 12);

    console.log("Hash generado:", hash);

    // ✅ comparar correcto
    const isValid = await realBcrypt.compare(password, hash);

    console.log("Resultado comparación correcta:", isValid);

    expect(isValid).toBe(true);

    // ❌ incorrecto
    const isInvalid = await realBcrypt.compare("wrongpass", hash);

    console.log("Resultado comparación incorrecta:", isInvalid);

    expect(isInvalid).toBe(false);

  });
});
