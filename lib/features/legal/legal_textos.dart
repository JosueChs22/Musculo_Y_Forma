// BORRADOR – revisar con asesoría legal.
//
// Textos del Aviso de privacidad y de los Términos y condiciones de Músculo y Forma.
// Redactados como referencia técnica a partir de la Ley 8968 de Costa Rica (Protección
// de la Persona frente al Tratamiento de sus Datos Personales) y su reglamento, con
// los principios del RGPD como buena práctica. NO son asesoría legal: un abogado debe
// revisarlos, completar los datos entre [CORCHETES] y confirmar los plazos antes de
// publicarlos.
//
// Al cambiar cualquier texto se sube [kVersionLegal] aquí y VERSION_LEGAL en la API
// (GYM-API/src/services/mi.service.js): a todos los usuarios se les vuelve a pedir
// la aceptación.

/// Versión vigente de los textos legales (debe coincidir con la de la API).
const kVersionLegal = '1.0-2026-11-24';

/// Fecha de la versión vigente, como se muestra al usuario.
const kFechaLegal = '24 de noviembre de 2026';

/// Aviso que acompaña a los textos hasta que un abogado los apruebe.
const kAvisoBorrador = 'BORRADOR – revisar con asesoría legal';

class SeccionLegal {
  const SeccionLegal(this.titulo, this.parrafos);
  final String titulo;
  final List<String> parrafos;
}

class DocumentoLegal {
  const DocumentoLegal(
      {required this.titulo, required this.resumen, required this.secciones});
  final String titulo;
  final String resumen;
  final List<SeccionLegal> secciones;
}

const kPoliticaPrivacidad = DocumentoLegal(
  titulo: 'Aviso de privacidad',
  resumen:
      'Cómo Músculo y Forma recoge, usa, protege y comparte sus datos personales, '
      'incluidos los datos de salud de sus mediciones, y cómo ejercer sus derechos.',
  secciones: [
    SeccionLegal('1. Responsable de la base de datos', [
      'El responsable del tratamiento es [RAZÓN SOCIAL DEL GIMNASIO], cédula jurídica [NÚMERO], '
          'con domicilio en [DIRECCIÓN], Costa Rica ("Músculo y Forma" o "el gimnasio").',
      'Contacto para temas de privacidad: [CORREO DE PRIVACIDAD] · teléfono [TELÉFONO].',
      '[Indicar si la base de datos está inscrita ante la Agencia de Protección de Datos de los '
          'Habitantes (PRODHAB), cuando corresponda por su naturaleza.]',
    ]),
    SeccionLegal('2. Datos que tratamos', [
      'Datos de identificación y contacto: nombre y apellidos, cédula (si se registra), correo, '
          'teléfono, nombre de usuario o carné.',
      'Datos de la membresía y uso del servicio: rol, estado de la cuenta, fecha de ingreso, '
          'fecha de pago, planes de entrenamiento, citas con su entrenador y último inicio de sesión.',
      'Datos de salud (datos sensibles): peso, estatura, porcentaje de grasa corporal, grasa '
          'visceral, masa muscular, índice de masa corporal, edad, medidas corporales, nivel de '
          'actividad física y observaciones de su entrenador. Solo se registran si usted da su '
          'consentimiento expreso y separado.',
      'Datos técnicos mínimos: el token de su sesión, guardado en el almacenamiento seguro de su '
          'dispositivo o navegador para mantenerlo conectado.',
    ]),
    SeccionLegal('3. Para qué los usamos (finalidades)', [
      'Administrar su membresía, su cuenta y el acceso a la app.',
      'Preparar y dar seguimiento a sus planes de entrenamiento y agendar citas con su entrenador.',
      'Solo con su consentimiento expreso: registrar sus mediciones corporales y mostrarle su '
          'evolución, para que su entrenador ajuste su plan.',
      'Enviarle avisos del servicio (por ejemplo, recuperación de contraseña).',
      'No usamos sus datos para publicidad de terceros, no los vendemos y no tomamos decisiones '
          'automatizadas que le produzcan efectos jurídicos.',
    ]),
    SeccionLegal('4. Consentimiento y datos de salud', [
      'Al crear o usar su cuenta se le pide aceptar este aviso. El tratamiento de sus datos de '
          'salud requiere un consentimiento aparte, expreso y por escrito (casilla independiente).',
      'Si no da ese consentimiento, puede usar la app con normalidad, pero no se registrarán ni '
          'mostrarán mediciones. Puede darlo o retirarlo cuando quiera desde Perfil; retirarlo no '
          'afecta el tratamiento hecho antes.',
    ]),
    SeccionLegal('5. Quién tiene acceso', [
      'Solo el personal que lo necesita para prestar el servicio: su entrenador (planes, citas y '
          'mediciones), la secretaría (membresía y citas) y la administración (cuentas).',
      'Encargados del tratamiento que alojan la información por cuenta del gimnasio: '
          '[PROVEEDOR DE BASE DE DATOS – p. ej. MongoDB Atlas, región ___], [PROVEEDOR DE '
          'SERVIDOR – p. ej. Render, región ___] y [PROVEEDOR DE CORREO]. Algunos pueden estar '
          'fuera de Costa Rica; [describir las garantías contractuales de transferencia].',
      'No compartimos sus datos con otros terceros salvo obligación legal u orden de autoridad '
          'competente.',
    ]),
    SeccionLegal('6. Cómo los protegemos', [
      'Conexiones cifradas (HTTPS), contraseñas guardadas con hash, control de acceso por rol '
          'validado en el servidor, límites de intentos y registro de cambios en las cuentas.',
    ]),
    SeccionLegal('7. Cuánto tiempo los conservamos', [
      'Mientras su membresía esté activa y, después, durante [PLAZO – definir con asesoría legal, '
          'considerando obligaciones contables y tributarias]. Las mediciones se eliminan o '
          'anonimizan [PLAZO] después de terminada la relación o al atender una solicitud de '
          'supresión, salvo que la ley exija conservarlas.',
    ]),
    SeccionLegal('8. Sus derechos (ARCO)', [
      'Acceso: desde Perfil › "Descargar mis datos" obtiene una copia en formato JSON de lo que '
          'guardamos sobre usted.',
      'Rectificación: puede pedir a la secretaría o a la administración que corrija datos '
          'inexactos.',
      'Cancelación o supresión: desde Perfil › "Solicitar eliminación de mi cuenta". La '
          'administración la atenderá en un plazo de [PLAZO, p. ej. 5 días hábiles según el '
          'reglamento – confirmar] y le informará qué datos deben conservarse por ley.',
      'Oposición y revocación: puede retirar el consentimiento de datos de salud desde Perfil o '
          'escribir a [CORREO DE PRIVACIDAD].',
      'Si considera que no atendimos su solicitud, puede acudir a la Agencia de Protección de '
          'Datos de los Habitantes (PRODHAB).',
    ]),
    SeccionLegal('9. Cookies y almacenamiento local', [
      'La app no usa cookies de seguimiento, analítica ni publicidad de terceros. Solo guarda en '
          'su dispositivo o navegador el token de la sesión (almacenamiento estrictamente '
          'necesario para mantenerlo conectado), que se borra al cerrar sesión. Por eso no se '
          'muestra un banner de cookies.',
    ]),
    SeccionLegal('10. Menores de edad', [
      'Las personas menores de 18 años solo pueden registrarse con la autorización de su madre, '
          'padre o representante legal, quien otorga los consentimientos. [Confirmar el '
          'procedimiento con asesoría legal.]',
    ]),
    SeccionLegal('11. Cambios a este aviso', [
      'Si cambiamos este aviso publicaremos la nueva versión con su fecha y le pediremos aceptarla '
          'de nuevo al ingresar a la app.',
    ]),
  ],
);

const kTerminos = DocumentoLegal(
  titulo: 'Términos y condiciones',
  resumen:
      'Reglas de uso de la app de Músculo y Forma para socios y personal del gimnasio.',
  secciones: [
    SeccionLegal('1. Quiénes somos y aceptación', [
      'La app es ofrecida por [RAZÓN SOCIAL DEL GIMNASIO], cédula jurídica [NÚMERO]. Al usarla '
          'usted acepta estos términos y el Aviso de privacidad.',
    ]),
    SeccionLegal('2. Cuentas', [
      'Las cuentas las crea el gimnasio. Usted es responsable de mantener su contraseña en '
          'secreto y de avisar si sospecha de un uso no autorizado.',
      'El gimnasio puede inhabilitar una cuenta por fin de la membresía o por uso indebido, '
          'informando el motivo.',
    ]),
    SeccionLegal('3. El servicio', [
      'La app permite consultar planes de entrenamiento, horarios, anuncios, el reglamento, citas '
          'y, si usted lo autoriza, su progreso corporal.',
      'La información de la app es de apoyo al entrenamiento y no sustituye una evaluación '
          'médica. Consulte a un profesional de la salud antes de iniciar o cambiar su actividad '
          'física, sobre todo si tiene alguna condición médica.',
    ]),
    SeccionLegal('4. Uso aceptable', [
      'No está permitido intentar acceder a datos de otras personas, interferir con el '
          'funcionamiento de la app ni usarla para fines distintos al servicio del gimnasio.',
    ]),
    SeccionLegal('5. Membresía, pagos y derechos del consumidor', [
      'Las condiciones de la membresía (precio, vigencia, cancelación y reembolsos) son las del '
          'contrato firmado en el gimnasio y el reglamento interno, conforme a la Ley 7472 de '
          'Promoción de la Competencia y Defensa Efectiva del Consumidor. [Revisar con asesoría '
          'legal.]',
    ]),
    SeccionLegal('6. Disponibilidad y responsabilidad', [
      'Procuramos que la app esté disponible, pero puede haber interrupciones por mantenimiento o '
          'causas ajenas. [Cláusula de limitación de responsabilidad a definir con asesoría '
          'legal, sin afectar derechos irrenunciables del consumidor.]',
    ]),
    SeccionLegal('7. Cambios y ley aplicable', [
      'Podemos actualizar estos términos; la nueva versión se publicará con su fecha y se le '
          'pedirá aceptarla. Se rigen por las leyes de la República de Costa Rica.',
      'Consultas: [CORREO DE CONTACTO].',
    ]),
  ],
);
