import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import userRoutes from "./interfaces/routes/userRoutes.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// rutas
app.use("/api/auth", userRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));