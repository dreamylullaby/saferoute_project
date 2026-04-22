# SafeRoute — Steering: Mejoras Sprint 2 (Perfil de Usuario)

## Contexto general

Proyecto: **SafeRoute** — Aplicación de reportes de hurtos para la ciudad de Pasto.  
Stack: Fullstack en un solo repositorio. Backend con PostgreSQL 17 (Supabase), PostGIS, Node.js. Frontend conectado al mismo repo.  
Sprint de referencia: **Sprint 2 — Mejoras posteriores al cierre**.  
Estas tres HU no tienen código definitivo asignado aún; se identifican por nombre hasta que el equipo les asigne código formal.

---

## HU-A | Gestión y visualización de perfil de usuario

**Actor:** Usuario / Ciudadano / Administrador  
**Descripción:** Como usuario o administrador, quiero acceder a mi perfil para actualizar mi información personal y configuración de la cuenta, con el fin de mantener mis datos actualizados y gestionar mis preferencias dentro del sistema.

### Criterios de aceptación

| CID | Condición | Resultado esperado |
|-----|-----------|-------------------|
| 1 | El usuario accede a la sección "Perfil". | El sistema muestra: correo electrónico, apodo, foto de perfil, opción para cambiar contraseña y fecha de creación de cuenta. |
| 2 | El usuario actualiza su apodo o foto de perfil. | El sistema guarda los cambios correctamente y muestra un mensaje de confirmación. |
| 3 | El usuario selecciona "Cambiar contraseña" e ingresa los datos requeridos. | El sistema valida la información y actualiza la contraseña exitosamente. |
| 4 | El usuario desactiva las notificaciones desde el perfil. | El sistema permite desactivarlas, pero muestra un mensaje informativo indicando que se recomienda mantenerlas activas para recibir alertas de seguridad. |
| 5 | El usuario intenta desactivar el permiso de ubicación desde el perfil. | El sistema muestra una advertencia indicando que la ubicación es necesaria para el funcionamiento del mapa y alertas, y permite desactivarla informando que dichas funciones quedarán limitadas. |
| 6 | El usuario selecciona la opción "Cerrar sesión". | El sistema elimina la sesión activa y redirige al usuario a la pantalla de inicio de sesión. |

### Tareas técnicas

#### Backend
- [ ] **Endpoint `GET /api/perfil`** — Retorna los campos: `correo`, `username` (apodo), `foto_url`, `fecha_creacion`, `rol`. Origen: tabla `usuarios`.
- [ ] **Endpoint `PATCH /api/perfil`** — Permite actualizar `username` y `foto_url`. Validar que `username` no esté duplicado (constraint `UNIQUE` ya existe en BD).
- [ ] **Endpoint `PATCH /api/perfil/password`** — Recibe `password_actual` y `password_nuevo`. Verificar hash actual con bcrypt, actualizar `password_hash`. Solo aplica a usuarios con `auth_provider = 'local'`.
- [ ] **Endpoint `PATCH /api/perfil/notificaciones`** — Actualiza el campo `activo` en tabla `configuracion_alertas` del usuario autenticado.
- [ ] **Endpoint `POST /api/auth/logout`** — Invalida el token JWT / sesión activa del usuario.
- [ ] Todos los endpoints deben requerir autenticación (middleware JWT). El usuario solo puede modificar su propio perfil.

#### Frontend
- [ ] **Página `/perfil`** — Mostrar datos del usuario: correo (solo lectura), apodo (editable), foto de perfil (con opción de cambiar), fecha de creación (solo lectura).
- [ ] **Formulario de edición de apodo/foto** — Llamar a `PATCH /api/perfil`. Mostrar toast/mensaje de confirmación al guardar.
- [ ] **Modal "Cambiar contraseña"** — Campos: contraseña actual, nueva contraseña, confirmar nueva contraseña. Llamar a `PATCH /api/perfil/password`. Ocultar opción si `auth_provider = 'google'`.
- [ ] **Toggle de notificaciones** — Al desactivar, mostrar un banner/aviso: *"Se recomienda mantener las notificaciones activas para recibir alertas de seguridad."*
- [ ] **Toggle de ubicación** — Al intentar desactivar, mostrar advertencia: *"El mapa y las alertas de proximidad quedarán limitados sin acceso a tu ubicación."* Permitir confirmar la desactivación.
- [ ] **Botón "Cerrar sesión"** — Llamar a `POST /api/auth/logout`, limpiar token local y redirigir a `/login`.

#### Base de datos
- [ ] ✅ Tabla `usuarios` ya contiene los campos necesarios (`username`, `correo`, `foto_url`, `fecha_creacion`, `fcm_token`, `auth_provider`).
- [ ] ✅ Tabla `configuracion_alertas` ya contiene el campo `activo` para gestionar notificaciones.
- [ ] No se requieren migraciones adicionales para esta HU.

---

## HU-B | Eliminar cuenta de usuario

**Actor:** Usuario / Ciudadano  
**Descripción:** Como usuario ciudadano, quiero eliminar mi cuenta del sistema, para proteger mi información y dejar de usar la aplicación, asegurando que los reportes realizados no se pierdan y sean reasignados al administrador.

### Criterios de aceptación

| CID | Condición | Resultado esperado |
|-----|-----------|-------------------|
| 1 | El usuario accede a "Perfil" y selecciona "Eliminar cuenta". | El sistema solicita confirmación antes de realizar la eliminación. |
| 2 | El usuario confirma la eliminación de la cuenta. | El sistema elimina o desactiva la cuenta del usuario y cierra la sesión automáticamente. |
| 3 | El usuario tiene reportes registrados en el sistema. | El sistema reasigna los reportes del usuario a una cuenta administrativa para conservar la información registrada. |
| 4 | El usuario cancela la eliminación. | El sistema no realiza cambios y retorna a la pantalla de perfil. |

### Tareas técnicas

#### Backend
- [ ] **Endpoint `DELETE /api/perfil`** — Lógica de eliminación de cuenta:
  1. Seleccionar aleatoriamente uno de los tres administradores activos para recibir los reportes:
     ```js
     const ADMIN_UUIDS = [
       '9de3faee-d951-4af0-8e64-60bfccff2856', // admin_lily
       '9a2a47e7-77e1-4ba9-83f6-63d8c84476c0', // admin_sarah
       '8f7175e5-5538-4e08-956c-810ede81a8b7', // admin_luna
     ];
     const adminDestino = ADMIN_UUIDS[Math.floor(Math.random() * ADMIN_UUIDS.length)];
     ```
  2. Reasignar todos los reportes del usuario: `UPDATE reportes SET usuario_id = adminDestino WHERE usuario_id = <usuario_autenticado>`.
  3. Cambiar el `estado` del usuario a `'bloqueado'` (soft-delete, para conservar trazabilidad).
  4. Invalidar la sesión/token activo.
  5. Retornar confirmación de eliminación.
- [ ] Proteger el endpoint con middleware JWT. El usuario solo puede eliminar su propia cuenta (no la de otros).
- [ ] Registrar en logs la eliminación con timestamp, `usuario_id` y el `adminDestino` al que se reasignaron los reportes.

#### Frontend
- [ ] **Botón "Eliminar cuenta"** en la página `/perfil` — Ubicar en zona de peligro (danger zone), visualmente separado de las otras opciones.
- [ ] **Modal de confirmación** — Texto claro: *"¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer. Tus reportes serán conservados y reasignados."* Botones: "Cancelar" y "Eliminar cuenta" (en rojo).
- [ ] Al confirmar: llamar a `DELETE /api/perfil`, limpiar sesión local y redirigir a `/login` con mensaje: *"Tu cuenta ha sido eliminada."*
- [ ] Al cancelar: cerrar el modal sin hacer nada.

#### Base de datos
- [ ] ✅ Campo `estado` en `usuarios` permite `'bloqueado'` para soft-delete.
- [ ] ⚠️ La FK `fk_usuario` en `reportes` tiene `ON DELETE SET DEFAULT` apuntando al UUID `00000000-0000-0000-0000-000000000001`. Como la reasignación ahora se hace manualmente en el backend (antes del soft-delete), este default no se activará — pero hay que asegurarse de que el UPDATE de reasignación se ejecute **antes** de cualquier cambio en el usuario.
- [ ] Los tres admins destino ya existen en la BD:
  - `9de3faee-d951-4af0-8e64-60bfccff2856` → admin_lily
  - `9a2a47e7-77e1-4ba9-83f6-63d8c84476c0` → admin_sarah
  - `8f7175e5-5538-4e08-956c-810ede81a8b7` → admin_luna

---

## HU-C | Gestionar reportes propios

**Actor:** Usuario / Ciudadano  
**Descripción:** Como usuario ciudadano, quiero visualizar los reportes de hurto que he registrado, para poder editarlos o eliminarlos si cometí un error o si el reporte ya no es válido.

### Criterios de aceptación

| CID | Condición | Resultado esperado |
|-----|-----------|-------------------|
| 1 | El usuario accede a la sección "Mis reportes". | El sistema muestra un listado con los reportes registrados por el usuario (fecha, tipo, zona y estado). |
| 2 | El usuario selecciona un reporte del listado. | El sistema muestra el detalle completo del reporte registrado. |
| 3 | El usuario edita un reporte modificando información permitida (ej. descripción u objeto hurtado). | El sistema valida los datos y actualiza el reporte correctamente. |
| 4 | El usuario intenta editar un campo no permitido (ej. id, usuario propietario). | El sistema bloquea la edición y muestra un mensaje indicando que el campo no es editable. |
| 5 | El usuario elimina un reporte propio. | El sistema solicita confirmación y elimina el reporte correctamente o lo marca como eliminado. |

### Tareas técnicas

#### Backend
- [ ] **Endpoint `GET /api/mis-reportes`** — Retorna los reportes donde `usuario_id = <usuario autenticado>` y `estado != 'eliminado'`. Campos a retornar: `id`, `fecha_incidente`, `tipo_hurto`, `zona_id`, `barrio_ingresado`, `comuna`, `estado`. Soportar paginación básica (`?page=1&limit=10`).
- [ ] **Endpoint `GET /api/mis-reportes/:id`** — Retorna el detalle completo del reporte. Verificar que `usuario_id` del reporte coincida con el usuario autenticado (no permitir ver reportes ajenos).
- [ ] **Endpoint `PATCH /api/mis-reportes/:id`** — Permite actualizar **únicamente** los campos: `descripcion`, `objeto_hurtado`, `numero_agresores`, `franja_horaria`. Ignorar (o rechazar con error) cualquier intento de modificar: `id`, `usuario_id`, `zona_id`, `comuna`, `fecha_creacion`, `estado`. Registrar `fecha_actualizacion = now()` y `actualizado_por = usuario_id`.
- [ ] **Endpoint `DELETE /api/mis-reportes/:id`** — Soft-delete: actualizar `estado = 'eliminado'`. Verificar que el reporte pertenece al usuario autenticado.
- [ ] Todos los endpoints protegidos con middleware JWT.

#### Frontend
- [ ] **Página `/mis-reportes`** — Listado de reportes propios con columnas: fecha, tipo de hurto, barrio/zona y estado (badge de color). Botón "Ver detalle" por fila.
- [ ] **Página/Modal de detalle `/mis-reportes/:id`** — Mostrar todos los campos del reporte. Botones: "Editar" y "Eliminar".
- [ ] **Formulario de edición** — Solo habilitar los campos editables: `descripcion`, `objeto_hurtado`, `numero_agresores`, `franja_horaria`. Los demás campos deben mostrarse como solo lectura con indicador visual claro. Al guardar, llamar a `PATCH /api/mis-reportes/:id`.
- [ ] **Eliminación con confirmación** — Modal: *"¿Deseas eliminar este reporte? Esta acción no se puede deshacer."* Al confirmar, llamar a `DELETE /api/mis-reportes/:id` y refrescar el listado.
- [ ] Manejar estado vacío: si el usuario no tiene reportes, mostrar mensaje: *"Aún no has registrado ningún reporte."*

#### Base de datos
- [ ] ✅ Tabla `reportes` ya tiene `estado` con valor `'eliminado'` permitido por constraint.
- [ ] ✅ Campos `fecha_actualizacion` y `actualizado_por` ya existen en `reportes` para auditoría.
- [ ] ✅ FK `fk_actualizado_por` ya referencia a `usuarios(id)`.
- [ ] ✅ Índice `idx_reportes_usuario_id` ya existe para búsquedas por usuario.
- [ ] No se requieren migraciones adicionales para esta HU.

---

## Notas generales para Kiro

- Las tres HU comparten la página `/perfil` como punto de entrada. Construir primero la página base de perfil (HU-A) antes de añadir las secciones de eliminar cuenta (HU-B) y gestionar reportes (HU-C).
- Orden de implementación sugerido: **HU-A → HU-C → HU-B** (la eliminación de cuenta es la más crítica y debe ir al final, después de validar el resto del perfil).
- El usuario administrador con UUID `00000000-0000-0000-0000-000000000001` es clave para HU-B. Confirmar su existencia en la BD antes de iniciar desarrollo.
- No se requieren migraciones de base de datos para ninguna de las tres HU; el esquema actual ya soporta toda la funcionalidad descrita.
