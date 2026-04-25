# SafeRoute — Cómo correr el proyecto

Guía rápida para levantar todo el entorno de desarrollo.

---

## Requisitos previos

- Node.js instalado
- Flutter SDK instalado
- Celular Android conectado por USB con depuración USB activada
- Backend configurado con `.env` (Supabase, JWT, etc.)
- Dashboard web configurado con `frontend-web/dashboard/.env` (VITE_MAPBOX_TOKEN)

---

## Paso 1: Levantar el Backend

Abrir una terminal en la carpeta `backend/` y correr:

```
node src/server.js
```

Debería decir algo como "Servidor corriendo en puerto 3000".
Dejar esta terminal abierta.

---

## Paso 2: Conectar el celular al backend (ADB Reverse)

Esto hace que el celular pueda acceder a `localhost:3000` de tu PC.
Abrir otra terminal (en cualquier carpeta) y correr:

```
C:\Android\platform-tools\adb.exe reverse tcp:3000 tcp:3000
```

Si dice "3000", funcionó.
Hay que correr esto cada vez que desconectes y reconectes el celular.

---

## Paso 3: Correr la app Flutter

Abrir otra terminal en `frontend-movil/saferoute_app/` y correr:

```
flutter pub get
flutter run
```

O si prefieres usar el archivo batch que ya existe:

```
.\debug_run.bat
```

---

## Paso 4: Levantar el Dashboard Web (opcional)

Abrir otra terminal en `frontend-web/dashboard/` y correr:

```
npm run dev
```

Se abre en `http://localhost:3001`.
Los cambios se reflejan al instante (Vite hot reload).

---

## Resumen de terminales

| Terminal | Carpeta | Comando | Puerto |
|----------|---------|---------|--------|
| 1 | `backend/` | `node src/server.js` | 3000 |
| 2 | cualquiera | `C:\Android\platform-tools\adb.exe reverse tcp:3000 tcp:3000` | — |
| 3 | `frontend-movil/saferoute_app/` | `flutter run` | — |
| 4 | `frontend-web/dashboard/` | `npm run dev` | 3001 |

---

## Problemas comunes

**"Error de conexión" en la app Flutter:**
- Verificar que el backend esté corriendo (terminal 1)
- Verificar que `adb reverse` esté activo (terminal 2)
- En el `.env` de Flutter, `API_BASE_URL` debe ser `http://localhost:3000`

**"401 Unauthorized" en el dashboard web:**
- Cerrar sesión y volver a iniciar sesión

**El dashboard no refleja cambios:**
- Vite debería reflejarlos al instante. Si no, `Ctrl+Shift+R` en el navegador

**Flutter no encuentra `fl_chart`:**
- Correr `flutter pub get` en la carpeta de la app
