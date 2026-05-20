/**
 * @module userController
 * @description Controlador HTTP para autenticación y gestión de usuarios.
 * Maneja registro local, login local/admin, login con Google, logout,
 * actualización de username y gestión de FCM tokens.
 */

import bcrypt from "bcrypt";
import crypto from "crypto";
import admin from "../../infrastructure/firebase/firebase.js";
import db from "../../infrastructure/database/dbScript/db.js";
import { generateToken } from "../../config/jwt.js";
import { enviarCorreoRecuperacion } from "../../infrastructure/email/emailService.js";

/**
 * Maneja POST /api/auth/register
 * Registra un nuevo usuario local con contraseña hasheada.
 * Requiere aceptación de términos y condiciones.
 * @param {import('express').Request} req - Body: { username, correo, password, aceptaTerminos }
 * @param {import('express').Response} res - Retorna { user: { id, username, correo, rol } }
 */
export const registerLocal = async (req, res) => {

  try {

    const { username, correo, password, aceptaTerminos } = req.body;

    if (!username || !correo || !password)
      return res.status(400).json({ message: "Todos los campos son obligatorios" });

    if (!aceptaTerminos)
      return res.status(400).json({ message: "Debes aceptar los términos y condiciones para registrarte" });

    const { data: existingUsername } = await db
      .from("usuarios")
      .select("id")
      .eq("username", username)
      .single();

    if (existingUsername)
      return res.status(409).json({ message: "El apodo ya está en uso" });

    const { data: existing } = await db
      .from("usuarios")
      .select("id")
      .eq("correo", correo)
      .single();

    if (existing)
      return res.status(409).json({ message: "El correo ya está registrado" });

    const password_hash = await bcrypt.hash(password, 12);

    const { data: newUser, error } = await db
      .from("usuarios")
      .insert({
        username,
        correo,
        password_hash,
        rol: "usuario",
        auth_provider: ["local"],
        estado: "activo"
      })
      .select()
      .single();

    if (error) throw error;

    // Guardar evidencia de aceptación de términos
    const ipOrigen = req.headers['x-forwarded-for']?.split(',')[0]?.trim()
      || req.socket?.remoteAddress
      || null;

    await db.from("aceptacion_terminos").insert({
      usuario_id:       newUser.id,
      version_terminos: 'v1.0',
      ip_origen:        ipOrigen,
    });

    res.status(201).json({
      user: {
        id: newUser.id,
        username: newUser.username,
        correo: newUser.correo,
        rol: newUser.rol
      },
      token: generateToken({ id: newUser.id, rol: newUser.rol })
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

/**
 * GET /api/auth/terminos
 * Retorna el texto de los términos y condiciones y política de privacidad vigentes.
 */
export const getTerminos = (req, res) => {
  res.json({
    version: 'v2.0',
    fecha_vigencia: '2026-05-14',
    terminos: `TÉRMINOS Y CONDICIONES DE USO DE CIVICTRACKIO

Versión final. Fecha de entrada en vigencia: 14 de mayo de 2026.
Nombre comercial: CivicTrackIO
Correo de contacto: civictrackio@gmail.com

1. Identificación y objeto
El presente documento establece los términos y condiciones que regulan el acceso, navegación y uso de CivicTrackIO, plataforma tecnológica orientada a la prevención ciudadana mediante geolocalización, reporte colaborativo de incidentes y visualización de zonas de riesgo. El uso de la plataforma implica la aceptación plena, expresa e incondicional de lo aquí dispuesto.

2. Naturaleza del servicio
CivicTrackIO es una herramienta informativa y preventiva que permite a los usuarios consultar mapas interactivos, registrar incidentes de forma colaborativa y acceder a estadísticas sobre hechos de riesgo o seguridad. La información suministrada es orientativa; no constituye asesoría profesional ni alerta oficial, y no reemplaza las actuaciones ni recomendaciones de las autoridades competentes. CivicTrackIO no garantiza la eliminación de riesgos ni la seguridad total de los usuarios.

3. Condiciones de acceso
El acceso a determinadas funcionalidades podrá requerir la creación de una cuenta mediante registro local o autenticación con terceros (por ejemplo, Google, a través de Firebase). El usuario se obliga a suministrar información veraz, completa y actualizada, y será responsable de la custodia de sus credenciales de acceso.

4. Registro y autenticación
CivicTrackIO podrá habilitar mecanismos de autenticación basados en correo electrónico, apodo, contraseña, tokens de sesión y tecnologías equivalentes. En caso de autenticación mediante servicios de terceros, los datos requeridos serán tratados conforme a las finalidades aquí descritas y a la Política de Privacidad aplicable.

5. Finalidad de la plataforma
La plataforma facilita la consulta de información georreferenciada sobre incidentes reportados por la comunidad, apoya la toma de decisiones preventivas y promueve la participación ciudadana. El uso del servicio deberá ceñirse exclusivamente a dichas finalidades.

6. Uso de la ubicación y consentimiento informado
CivicTrackIO podrá solicitar acceso a la ubicación del usuario para mostrar reportes cercanos, zonas de riesgo y métricas asociadas al entorno inmediato. El tratamiento de geolocalización requiere el consentimiento previo, expreso e informado del titular; el usuario podrá otorgarlo o revocarlo desde la configuración del dispositivo o de la aplicación. La revocatoria del consentimiento podrá limitar ciertas funciones de la plataforma.

7. Conducta del usuario
El usuario se compromete a utilizar CivicTrackIO de manera lícita, diligente, responsable y conforme a la buena fe. Queda prohibido: incluir información falsa, maliciosa o que induzca a error; suplantar identidad o atribuirse la de terceros; utilizar la plataforma para hostigar, amenazar o divulgar contenido ilícito; alterar, interferir o vulnerar la seguridad de la aplicación o de sus componentes; emplear los contenidos o funcionalidades con fines distintos a los previstos por CivicTrackIO.

8. Reportes colaborativos
Los reportes realizados por los usuarios serán tratados con fines preventivos, analíticos y de visualización comunitaria. CivicTrackIO procurará, en la medida de lo técnicamente posible, preservar el carácter anónimo o despersonalizado de dichos reportes; no obstante, ciertos elementos técnicos o contextuales podrán conservarse internamente para garantizar la seguridad, continuidad y mejora del servicio.

9. Propiedad intelectual
Todos los derechos sobre la estructura, diseño, desarrollo, interfaz, bases de datos, código fuente, manuales, signos distintivos y demás elementos protegidos de CivicTrackIO pertenecen a sus desarrolladores o titulares autorizados, salvo los contenidos generados por usuarios o componentes sujetos a licencias de terceros. Queda prohibida su reproducción, transformación, distribución o explotación no autorizada.

10. Limitación de responsabilidad
CivicTrackIO no garantiza la ausencia de incidentes, la veracidad absoluta de los reportes, ni la disponibilidad ininterrumpida del servicio. El usuario reconoce que la plataforma tiene carácter orientativo y que cualquier decisión de desplazamiento o permanencia en determinada zona debe adoptarse bajo su propio criterio y responsabilidad.

11. Suspensión y modificación del servicio
CivicTrackIO podrá modificar, limitar, suspender o dar por terminadas, total o parcialmente, las funcionalidades de la plataforma cuando ello resulte necesario por razones técnicas, de seguridad, mantenimiento, actualización o por causas ajenas a su control.

12. Eliminación de cuenta
El usuario podrá solicitar la eliminación de su cuenta cuando la funcionalidad esté habilitada. Una vez efectuada la eliminación, los datos personales asociados al perfil podrán ser suprimidos o anonimizados, sin perjuicio de la conservación de aquella información que deba mantenerse por razones legales, de seguridad, auditoría o integridad operativa.

13. Tratamiento de datos personales
El tratamiento de los datos personales se regirá por la Política de Privacidad y Tratamiento de Datos Personales de la plataforma. El responsable del tratamiento es el equipo de desarrollo de CivicTrackIO. Para consultas: civictrackio@gmail.com.

14. Legislación aplicable
Estos términos se interpretarán y aplicarán conforme a las leyes de la República de Colombia.`,
    politica_privacidad: `POLÍTICA DE PRIVACIDAD Y TRATAMIENTO DE DATOS PERSONALES DE CIVICTRACKIO

Versión final. Fecha de entrada en vigencia: 14 de mayo de 2026.
Nombre comercial: CivicTrackIO
Correo de contacto: civictrackio@gmail.com

1. Introducción
CivicTrackIO, en su calidad de responsable del tratamiento de datos personales, adopta la presente Política en cumplimiento de la Ley 1581 de 2012, el Decreto 1377 de 2013 y demás disposiciones aplicables en la República de Colombia.

2. Responsable del tratamiento
El responsable del tratamiento y administrador de la plataforma es el equipo de desarrollo de CivicTrackIO. Para consultas, solicitudes de derechos o reclamaciones: civictrackio@gmail.com.

3. Qué datos recolectamos
CivicTrackIO recolecta únicamente los datos necesarios: correo electrónico, apodo o nombre de usuario, contraseña (si hay registro local), nombre y correo asociados a cuenta de terceros (Google), ubicación geográfica (con autorización expresa), información de incidentes reportados, y datos técnicos de sesión y autenticación.

4. Finalidades del tratamiento
Los datos se usan para: gestionar registro y autenticación; habilitar el acceso seguro; mostrar mapas, estadísticas y zonas de riesgo según ubicación autorizada; procesar reportes colaborativos con fines preventivos y estadísticos; mejorar la experiencia, desempeño y seguridad técnica; y atender requerimientos operativos o de cumplimiento normativo.

5. Base legal y consentimiento
El tratamiento se realizará con la autorización previa, expresa e informada del titular, salvo excepciones legales. El consentimiento para la geolocalización será recabado de forma diferenciada y clara.

6. Protección y medidas de seguridad
CivicTrackIO implementará medidas técnicas, administrativas y organizativas razonables para proteger los datos frente a pérdida, alteración, acceso o uso no autorizado: control de acceso, autenticación segura, cifrado cuando sea aplicable, expiración de sesiones y auditorías periódicas.

7. Derechos de los titulares
El titular tiene derecho a conocer, actualizar, rectificar, solicitar prueba de la autorización, ser informado sobre el uso de sus datos, presentar quejas ante la autoridad competente, revocar la autorización y solicitar la supresión de datos cuando proceda. Canal: civictrackio@gmail.com.

8. Menores de edad
CivicTrackIO podrá ser utilizado por personas a partir de los 15 años; en el tratamiento de datos de menores se respetará el interés superior del menor y la normativa aplicable.

9. Eliminación de cuenta y supresión
El titular podrá solicitar la eliminación de su cuenta; se suprimirán o desasociarán los datos personales del perfil, sin perjuicio de la conservación de datos anonimizados o requeridos por ley.

10. Modificaciones
La política podrá modificarse para reflejar cambios normativos, tecnológicos o funcionales; cualquier modificación será publicada por los medios habilitados por CivicTrackIO.

11. Legislación aplicable
Esta política se rige por la Constitución Política de Colombia, la Ley 1581 de 2012, el Decreto 1377 de 2013 y demás normas aplicables.`,
    aviso_ubicacion: `Al habilitar la ubicación autorizas a CivicTrackIO a recolectar y usar tu posición geográfica con la finalidad de mostrar reportes cercanos, calcular zonas de riesgo y mejorar la experiencia de prevención en la aplicación. Este tratamiento se realiza con tu consentimiento previo, expreso e informado; puedes revocar el permiso en cualquier momento desde la configuración del dispositivo o de la aplicación. Para consultas sobre el tratamiento de tus datos y para ejercer tus derechos escribe a civictrackio@gmail.com.`,
  });
};

/**
 * Maneja POST /api/auth/login
 * Autentica un usuario local verificando correo o username, estado activo y contraseña.
 * El campo "correo" del body acepta tanto correo como username (case-insensitive).
 * @param {import('express').Request} req - Body: { correo, password }
 * @param {import('express').Response} res - Retorna { user: { id, username, correo, rol } }
 */
export const loginLocal = async (req, res) => {

  try {

    const { correo, password } = req.body;
    const input = correo?.trim().toLowerCase();

    if (!input || !password)
      return res.status(400).json({ message: "Correo/usuario y contraseña son requeridos" });

    // Determinar si es correo o username
    const isEmail = input.includes('@');

    let data;
    if (isEmail) {
      const result = await db
        .from("usuarios")
        .select("*")
        .ilike("correo", input)
        .eq("estado", "activo")
        .single();
      data = result.data;
    } else {
      const result = await db
        .from("usuarios")
        .select("*")
        .ilike("username", input)
        .eq("estado", "activo")
        .single();
      data = result.data;
    }

    if (!data)
      return res.status(404).json({ message: "Usuario no encontrado" });

    const passwordValida = await bcrypt.compare(password, data.password_hash);

    if (!passwordValida)
      return res.status(401).json({ message: "Contraseña incorrecta" });

    res.json({
      user: {
        id: data.id,
        username: data.username,
        correo: data.correo,
        rol: data.rol
      },
      token: generateToken({ id: data.id, rol: data.rol })
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

/**
 * Maneja POST /api/auth/admin-login
 * Login exclusivo para administradores. Verifica rol antes de responder.
 * Acepta correo o username (case-insensitive).
 * @param {import('express').Request} req - Body: { correo, password }
 * @param {import('express').Response} res
 */
export const loginAdmin = async (req, res) => {

  try {

    const { correo, password } = req.body;
    const input = correo?.trim().toLowerCase();

    if (!input || !password)
      return res.status(400).json({ message: "Correo/usuario y contraseña son requeridos" });

    const isEmail = input.includes('@');

    let data;
    if (isEmail) {
      const result = await db
        .from("usuarios")
        .select("*")
        .ilike("correo", input)
        .eq("estado", "activo")
        .single();
      data = result.data;
    } else {
      const result = await db
        .from("usuarios")
        .select("*")
        .ilike("username", input)
        .eq("estado", "activo")
        .single();
      data = result.data;
    }

    if (!data)
      return res.status(404).json({ message: "Usuario no encontrado" });

    if (data.rol !== "admin")
      return res.status(403).json({ message: "Acceso denegado" });

    const passwordValida = await bcrypt.compare(password, data.password_hash);

    if (!passwordValida)
      return res.status(401).json({ message: "Contraseña incorrecta" });

    res.json({
      user: {
        id: data.id,
        username: data.username,
        correo: data.correo,
        rol: data.rol
      },
      token: generateToken({ id: data.id, rol: data.rol })
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

/**
 * Maneja POST /api/auth/logout
 * El cliente debe eliminar el token localmente.
 * Responde con confirmación para que el frontend limpie su storage.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 */
export const logoutUser = (req, res) => {
  res.json({ message: "Sesión cerrada correctamente" });
};

/**
 * Maneja POST /api/auth/google
 * Autentica o registra un usuario mediante Google Sign-In.
 * Verifica el idToken con Firebase Admin y crea el usuario si no existe.
 * @param {import('express').Request} req - Body: { idToken }
 * @param {import('express').Response} res - Retorna { user: { id, username, correo, rol } }
 */
export const loginGoogle = async (req, res) => {

  try {

    const { idToken } = req.body;

    const decodedToken = await admin.auth().verifyIdToken(idToken);

    const { uid, email, name, picture } = decodedToken;

    let { data: user } = await db
      .from("usuarios")
      .select("*")
      .eq("google_id", uid)
      .single();

    if (!user) {
      // Buscar si ya existe un usuario con ese correo (registro local previo)
      const { data: existingUser } = await db
        .from("usuarios")
        .select("*")
        .eq("correo", email)
        .single();

      if (existingUser) {
        // Vincular cuenta Google al usuario local existente
        const updatedProviders = Array.isArray(existingUser.auth_provider)
          ? existingUser.auth_provider
          : [existingUser.auth_provider];
        if (!updatedProviders.includes('google')) updatedProviders.push('google');

        const { error } = await db
          .from("usuarios")
          .update({ google_id: uid, foto_url: picture || existingUser.foto_url, auth_provider: updatedProviders })
          .eq("id", existingUser.id);

        if (error) throw error;
        user = existingUser;
      } else {
        // Crear usuario nuevo
        const { data: newUser, error } = await db
          .from("usuarios")
          .insert({
            username: name,
            correo: email,
            google_id: uid,
            foto_url: picture,
            rol: "usuario",
            auth_provider: ["google"],
            estado: "activo"
          })
          .select()
          .single();

        if (error) throw error;
        user = newUser;
      }
    }

    res.json({
      user: {
        id: user.id,
        username: user.username,
        correo: user.correo,
        rol: user.rol
      },
      token: generateToken({ id: user.id, rol: user.rol })
    });

  } catch (error) {
    console.error("Error loginGoogle:", error);
    res.status(401).json({ message: "Token inválido", detail: error.message || error });
  }

};

/**
 * Maneja PATCH /api/auth/username
 * Actualiza el apodo de un usuario (usado tras login con Google).
 * @param {import('express').Request} req - Body: { username }, req.user.id del token
 * @param {import('express').Response} res
 */

/**
 * Maneja PATCH /api/auth/fcm-token
 * Guarda, actualiza o limpia el FCM token del dispositivo del usuario.
 * Se llama al abrir la app (guardar) y al cerrar sesión (limpiar con string vacío).
 * @param {import('express').Request} req - Body: { fcm_token }
 * @param {import('express').Response} res
 */
export const updateFcmToken = async (req, res) => {

  try {

    const { fcm_token } = req.body;
    const userId = req.user.id;

    if (fcm_token === undefined || fcm_token === null)
      return res.status(400).json({ message: "fcm_token es obligatorio" });

    // String vacío = limpiar token (logout), string con contenido = guardar
    const tokenValue = fcm_token.trim().length === 0 ? null : fcm_token.trim();

    const { error } = await db
      .from("usuarios")
      .update({ fcm_token: tokenValue })
      .eq("id", userId);

    if (error) throw error;

    res.json({ message: tokenValue ? "FCM token actualizado correctamente" : "FCM token eliminado" });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

export const updateUsername = async (req, res) => {

  try {

    const { username } = req.body;
    const userId = req.user.id;

    if (!username || username.trim().length < 3)
      return res.status(400).json({ message: "El apodo debe tener al menos 3 caracteres" });

    const { data: existing } = await db
      .from("usuarios")
      .select("id")
      .eq("username", username.trim())
      .single();

    if (existing)
      return res.status(409).json({ message: "Ese apodo ya está en uso, elige otro" });

    const { data: updated, error } = await db
      .from("usuarios")
      .update({ username: username.trim() })
      .eq("id", userId)
      .select()
      .single();

    if (error) throw error;

    res.json({ user: { id: updated.id, username: updated.username, correo: updated.correo, rol: updated.rol } });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

/**
 * POST /api/auth/forgot-password
 * Genera token de recuperación y envía correo con enlace.
 * Siempre responde igual para no revelar si el correo existe.
 */
export const forgotPassword = async (req, res) => {
  try {
    const { correo, plataforma = 'web' } = req.body;

    if (!correo || !correo.includes('@'))
      return res.status(400).json({ message: "Correo inválido" });

    // Buscar usuario (sin revelar si existe en la respuesta)
    const { data: usuario } = await db
      .from("usuarios")
      .select("id, correo, auth_provider")
      .eq("correo", correo.toLowerCase().trim())
      .eq("estado", "activo")
      .single();

    // Si existe y tiene método local, generar token
    const providers = usuario ? (Array.isArray(usuario.auth_provider) ? usuario.auth_provider : [usuario.auth_provider]) : [];
    if (usuario && providers.includes('local')) {
      const token     = crypto.randomBytes(32).toString('hex');
      const expiracion = new Date(Date.now() + 60 * 60 * 1000); // 1 hora

      await db.from("password_resets").insert({
        usuario_id: usuario.id,
        token,
        expiration: expiracion.toISOString(),
        usado: false,
      });

      // Enviar correo (silencioso si falla)
      try {
        await enviarCorreoRecuperacion(usuario.correo, token, plataforma);
      } catch (emailErr) {
        console.warn('[Email] Error al enviar correo de recuperación:', emailErr.message);
      }
    }

    // Siempre respuesta estándar
    res.json({ message: "Si el correo está registrado, recibirás un enlace de recuperación." });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/**
 * POST /api/auth/reset-password
 * Valida token, verifica expiración y actualiza contraseña.
 * Body: { token, nuevaPassword }
 */
export const resetPassword = async (req, res) => {
  try {
    const { token, nuevaPassword } = req.body;

    if (!token)         return res.status(400).json({ message: "Token requerido" });
    if (!nuevaPassword) return res.status(400).json({ message: "Nueva contraseña requerida" });
    if (nuevaPassword.length < 8)
      return res.status(400).json({ message: "La contraseña debe tener al menos 8 caracteres" });

    // Buscar token
    const { data: reset, error } = await db
      .from("password_resets")
      .select("*")
      .eq("token", token)
      .single();

    if (error || !reset)
      return res.status(400).json({ message: "Token inválido" });

    if (reset.usado)
      return res.status(400).json({ message: "Este enlace ya fue utilizado" });

    if (new Date(reset.expiration) < new Date())
      return res.status(400).json({ message: "El enlace ha expirado. Solicita uno nuevo." });

    // Actualizar contraseña
    const password_hash = await bcrypt.hash(nuevaPassword, 12);

    const { error: updateError } = await db
      .from("usuarios")
      .update({ password_hash })
      .eq("id", reset.usuario_id);

    if (updateError) throw updateError;

    // Marcar token como usado
    await db.from("password_resets").update({ usado: true }).eq("id", reset.id);

    // Enviar email de confirmación (silencioso si falla)
    try {
      const { data: usr } = await db.from("usuarios").select("correo").eq("id", reset.usuario_id).single();
      if (usr) {
        const { enviarCorreoPasswordCambiada } = await import("../../infrastructure/email/emailService.js");
        await enviarCorreoPasswordCambiada(usr.correo);
      }
    } catch (_) {}

    res.json({ message: "Contraseña actualizada correctamente" });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
