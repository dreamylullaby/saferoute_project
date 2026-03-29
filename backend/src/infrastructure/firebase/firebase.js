import admin from "firebase-admin";
import fs from "fs";

// ajustar la ruta
const serviceAccount = JSON.parse(
  fs.readFileSync(
    new URL("../../config/firebase-key.json", import.meta.url)
  )
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

export default admin;