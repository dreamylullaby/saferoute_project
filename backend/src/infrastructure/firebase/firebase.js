/**
 * Inicialización de Firebase Admin SDK.
 * Lee las credenciales del service account desde firebase-key.json.
 * Se usa para verificar tokens de autenticación de Google (idToken).
 * @module firebase
 */
import admin from "firebase-admin";
import fs from "fs";

try {
  const serviceAccount = JSON.parse(
    fs.readFileSync(
      new URL("../../config/firebase-key.json", import.meta.url)
    )
  );
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (e) {
  console.warn("[Firebase] firebase-key.json no encontrado. Login con Google deshabilitado.");
}

export default admin;
