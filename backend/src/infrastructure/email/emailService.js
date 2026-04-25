// src/infrastructure/email/emailService.js

import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

/**
 * Envía el correo de recuperación de contraseña.
 * @param {string} correo     - Correo del destinatario
 * @param {string} token      - Token de recuperación
 * @param {string} plataforma - 'web' | 'app'
 */
export const enviarCorreoRecuperacion = async (correo, token, plataforma = 'web') => {
  const enlace = plataforma === 'web'
    ? `${process.env.FRONTEND_WEB_URL}/reset-password?token=${token}`
    : `${process.env.FRONTEND_APP_URL}?token=${token}`;

  await resend.emails.send({
    from:    process.env.RESEND_FROM_EMAIL,
    to:      correo,
    subject: 'Recuperación de contraseña — SafeRoute',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #2563eb;">SafeRoute</h2>
        <p>Recibimos una solicitud para restablecer tu contraseña.</p>
        <p>Haz clic en el siguiente enlace para continuar. El enlace expira en <strong>1 hora</strong>.</p>
        <a href="${enlace}"
           style="display:inline-block;padding:12px 24px;background:#2563eb;color:#fff;
                  border-radius:8px;text-decoration:none;font-weight:600;margin:16px 0;">
          Restablecer contraseña
        </a>
        <p style="color:#64748b;font-size:13px;">
          Si no solicitaste esto, ignora este correo. Tu contraseña no cambiará.
        </p>
        <p style="color:#94a3b8;font-size:12px;">
          O copia este enlace en tu navegador:<br/>
          <span style="word-break:break-all;">${enlace}</span>
        </p>
      </div>
    `,
  });
};
