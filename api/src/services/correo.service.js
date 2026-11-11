// Envío de correos por API web (HTTPS). Render gratis bloquea los puertos SMTP,
// así que no se usa Gmail/SMTP. Proveedor según las variables del .env:
//  - BREVO_API_KEY:  Brevo (plan gratis, 300/día, verifica un solo remitente sin dominio)
//  - RESEND_API_KEY: Resend (sin dominio propio solo envía al dueño de la cuenta)
//  - ninguna:        imprime el código en la consola de la API (desarrollo)
//
// MAIL_FROM_EMAIL debe ser un remitente verificado en el proveedor.

const MINUTOS_VALIDEZ = 15;

const REMITENTE = () => ({
  email: process.env.MAIL_FROM_EMAIL,
  name: process.env.MAIL_FROM_NAME || 'Músculo y Forma',
});

async function enviarConBrevo(para, asunto, texto) {
  const r = REMITENTE();
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'api-key': process.env.BREVO_API_KEY,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      sender: { email: r.email, name: r.name },
      to: [{ email: para }],
      subject: asunto,
      textContent: texto,
    }),
  });
  if (!res.ok) throw new Error(`Brevo respondió ${res.status}: ${await res.text()}`);
}

async function enviarConResend(para, asunto, texto) {
  const r = REMITENTE();
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: `${r.name} <${r.email || 'onboarding@resend.dev'}>`,
      to: [para],
      subject: asunto,
      text: texto,
    }),
  });
  if (!res.ok) throw new Error(`Resend respondió ${res.status}: ${await res.text()}`);
}

async function enviarCodigoRecuperacion(correo, codigo) {
  const asunto = 'Código para recuperar tu contraseña';
  const texto =
    `Tu código para recuperar la contraseña de Músculo y Forma es: ${codigo}\n\n` +
    `Vence en ${MINUTOS_VALIDEZ} minutos. Si no lo solicitaste, ignora este mensaje.`;

  if (process.env.BREVO_API_KEY) return enviarConBrevo(correo, asunto, texto);
  if (process.env.RESEND_API_KEY) return enviarConResend(correo, asunto, texto);

  // Sin proveedor configurado: solo para desarrollo
  console.log(`[CORREO SIMULADO] Código de recuperación para ${correo}: ${codigo}`);
}

module.exports = { enviarCodigoRecuperacion, MINUTOS_VALIDEZ };
