import express from "express";
import { loginLocal, loginGoogle, registerLocal } from "../controllers/userController.js";

const router = express.Router();

router.post("/register", registerLocal);
router.post("/login", loginLocal);
router.post("/google", loginGoogle);

export default router;
