# Mejoras extra posibles

Documento temporal para discutir con el asesor y el equipo antes de implementar.

---

## 1. Hard delete de reportes

Actualmente al "eliminar" un reporte solo se hace soft delete (estado = eliminado). El reporte sigue en la BD.

Propuesta: agregar un botón "Eliminar permanentemente" que solo aparezca cuando el reporte ya tiene estado "eliminado". Flujo:
- Admin elimina → soft delete (estado = eliminado)
- Admin filtra por "Eliminado", revisa, confirma → hard delete (se borra de la BD)
- Modal de confirmación: "Esta acción es irreversible"
- Requiere endpoint: DELETE /api/admin/reportes/:id

Decisión pendiente: ¿implementar hard delete o dejar solo soft delete?

---

## 2. Hard delete de usuarios

Mismo caso que reportes. Actualmente solo soft delete. ¿Se necesita un borrado permanente?

Consideraciones:
- Los reportes del usuario quedan reasignados al admin por defecto (FK ON DELETE SET DEFAULT)
- La auditoría mantiene referencia al usuario
- La función eliminar_cuenta_usuario() ya anonimiza datos personales

---

## 3. Reportes sin coordenadas y lógica de incidentes

La función `asignar_o_crear_incidente` solo agrupa reportes si tienen coordenadas. Si un reporte no tiene latitud/longitud, se crea un incidente nuevo con centro NULL y nunca se agrupa con otros.

Actualmente el formulario de la app obliga coordenadas y barrio, así que en uso normal no debería pasar. Pero si se inserta un reporte directo por query SQL (sin coordenadas), queda como incidente huérfano sin ubicación.

Condiciones para agrupar en un incidente existente (TODAS deben cumplirse):
- Mismo tipo_hurto
- Misma fecha_incidente (exacta)
- Misma franja_horaria (exacta)
- Dentro de 150 metros del centro del incidente

Si alguna no se cumple → se crea incidente nuevo.

Preguntar al asesor:
- ¿Está bien que la BD permita reportes sin coordenadas? (el formulario lo obliga, pero la BD no)
- ¿Se debería agregar NOT NULL a latitud/longitud en la tabla reportes? (rompería reportes rurales sin GPS)
- ¿Los parámetros de agrupación (150m, misma fecha exacta, misma franja) son adecuados o se deberían relajar?

---
