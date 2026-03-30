/**
 * Componente raíz de la aplicación React del panel de administración.
 * Define las rutas principales y protege el acceso al dashboard.
 * @module App
 */
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import LoginAdmin from "./page/LoginAdmin";
import Dashboard from "./page/Dashboard";

/**
 * Componente de ruta protegida.
 * Redirige al login si no hay sesión de administrador en sessionStorage.
 * @param {Object} props
 * @param {React.ReactNode} props.children - Componente a renderizar si hay sesión
 */
function ProtectedRoute({ children }) {
  const admin = sessionStorage.getItem("admin");
  return admin ? children : <Navigate to="/" replace />;
}

/**
 * Componente principal con configuración de rutas.
 * - "/" → LoginAdmin
 * - "/dashboard" → Dashboard (protegida)
 */
function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LoginAdmin />} />
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
