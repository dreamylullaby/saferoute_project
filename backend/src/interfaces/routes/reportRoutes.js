// src/interfaces/routes/reportRoutes.js

import express from "express";
import ReportController    from "../controllers/reportController.js";
import ReportRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/reportRepositoryImpl.js";
import { authenticate, requireAdmin } from "../middlewares/auth.js";

const router = express.Router();

const repository = new ReportRepositoryImpl();
const controller = new ReportController(repository);

/** GET /api/reportes/zonas/top?top=10&fechaDesde=&fechaHasta= — Top N zonas con más hurtos */
router.get('/zonas/top', authenticate, (req, res) => controller.getTopZonas(req, res));

/** GET /api/reportes/estadisticas/comparacion — Comparación entre dos períodos */
router.get('/estadisticas/comparacion', authenticate, (req, res) => controller.getComparacion(req, res));

/** GET /api/reportes/estadisticas — Estadísticas por período */
router.get('/estadisticas', authenticate, (req, res) => controller.getEstadisticas(req, res));

/** GET /api/reportes/admin/resumen — Resumen de conteos para el dashboard (solo admin) */
router.get('/admin/resumen', authenticate, requireAdmin, (req, res) => controller.getResumen(req, res));

/** GET /api/reportes/admin — Listado paginado con filtros para el panel admin (solo admin) */
router.get('/admin', authenticate, requireAdmin, (req, res) => controller.listAdmin(req, res));

/** POST /api/reportes — Crea un nuevo reporte (requiere autenticación) */
router.post('/', authenticate, (req, res) => controller.create(req, res));

/** GET /api/reportes/mapa — Reportes activos para el mapa (requiere autenticación) */
router.get('/mapa', authenticate, (req, res) => controller.getForMap(req, res));

/** GET /api/reportes/mapa/nuevos?desde= — Reportes nuevos desde timestamp (requiere autenticación) */
router.get('/mapa/nuevos', authenticate, (req, res) => controller.getNewForMap(req, res));

/** GET /api/reportes/mapa/filtros?comunas=&franjas=&tipos=&fechaDesde=&fechaHasta= — Reportes filtrados para el mapa */
router.get('/mapa/filtros', authenticate, (req, res) => controller.getFiltered(req, res));

/** GET /api/reportes/barrios-por-coordenadas?lat=X&lng=Y — Barrios de la comuna detectada por coordenadas */
router.get('/barrios-por-coordenadas', authenticate, (req, res) => controller.buscarBarriosPorCoordenadas(req, res));

/** GET /api/reportes/corregimientos — Lista todos los corregimientos */
router.get('/corregimientos', authenticate, (req, res) => controller.listarCorregimientos(req, res));

/** GET /api/reportes/corregimientos-por-coordenadas?lat=X&lng=Y — Detecta corregimiento por coordenadas */
router.get('/corregimientos-por-coordenadas', authenticate, (req, res) => controller.buscarCorregimientoPorCoordenadas(req, res));

/** GET /api/reportes/corregimientos/:id/veredas — Veredas de un corregimiento */
router.get('/corregimientos/:id/veredas', authenticate, (req, res) => controller.listarVeredas(req, res));

/** GET /api/reportes/buscar-rural?q=texto — Busca veredas y corregimientos por texto */
router.get('/buscar-rural', authenticate, (req, res) => controller.buscarRural(req, res));

/** GET /api/reportes/barrios?q= — Busca barrios similares al texto ingresado */
router.get('/barrios', authenticate, (req, res) => controller.buscarBarrios(req, res));

/** GET /api/reportes/mis-reportes — Reportes del usuario autenticado */
router.get('/mis-reportes', authenticate, (req, res) => controller.getMisReportes(req, res));

/** GET /api/reportes/mis-reportes/:id — Detalle de reporte propio */
router.get('/mis-reportes/:id', authenticate, (req, res) => controller.getMiReporteById(req, res));

/** GET /api/reportes — Lista todos los reportes no eliminados (requiere autenticación) */
router.get('/', authenticate, (req, res) => controller.list(req, res));

/** PUT /api/reportes/:id — Editar reporte propio */
router.put('/:id', authenticate, (req, res) => controller.updateOwn(req, res));

/** POST /api/reportes/:id/solicitar-eliminacion — Solicitar eliminación de reporte propio */
router.post('/:id/solicitar-eliminacion', authenticate, (req, res) => controller.solicitarEliminacion(req, res));

/** GET /api/reportes/:id — Obtiene un reporte por su UUID (requiere autenticación) */
router.get('/:id', authenticate, (req, res) => controller.getById(req, res));

export default router;