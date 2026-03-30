import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import LoginAdmin from "./page/LoginAdmin";
import Dashboard from "./page/Dashboard";

function ProtectedRoute({ children }) {
  const admin = sessionStorage.getItem("admin");
  return admin ? children : <Navigate to="/" replace />;
}

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
