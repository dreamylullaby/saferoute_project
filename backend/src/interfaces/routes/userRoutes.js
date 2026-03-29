import express from "express";
import { loginLocal, loginGoogle } from "../controllers/userController.js";

const router = express.Router();

router.post("/login", loginLocal);
router.post("/google", loginGoogle);

export default router;
