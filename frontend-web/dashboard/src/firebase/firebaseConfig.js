/**
 * Configuración de Firebase para el panel de administración.
 * Inicializa la app y exporta las instancias de Auth y GoogleAuthProvider.
 * @module firebaseConfig
 */
import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyB-t6b7plOtez2YQGhSbJdYg3myQhH_JuI",
  authDomain: "saferouteapp2026.firebaseapp.com",
  projectId: "saferouteapp2026",
  storageBucket: "saferouteapp2026.firebasestorage.app",
  messagingSenderId: "455431452213",
  appId: "1:455431452213:web:c53fe2b4a26145a0b4637c"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();
