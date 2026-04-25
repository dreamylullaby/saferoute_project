import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import LoginAdmin     from "./page/LoginAdmin.jsx";
import Dashboard      from "./page/Dashboard.jsx";
import ForgotPassword from "./page/ForgotPassword.jsx";
import ResetPassword  from "./page/ResetPassword.jsx";

function ProtectedRoute({ children }) {
  const admin = sessionStorage.getItem("admin");
  return admin ? children : <Navigate to="/" replace />;
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/"                element={<LoginAdmin />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password"  element={<ResetPassword />} />
        <Route path="/dashboard"       element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
