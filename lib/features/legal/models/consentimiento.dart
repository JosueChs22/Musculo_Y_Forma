/// Estado del consentimiento del usuario con sesión (GET /mi/consentimiento).
class Consentimiento {
  const Consentimiento({
    required this.version,
    required this.fecha,
    required this.datosSalud,
    required this.fechaDatosSalud,
    required this.versionVigente,
    this.solicitudSupresion,
  });

  /// Versión del aviso que aceptó (null si nunca aceptó).
  final String? version;
  final DateTime? fecha;

  /// Consentimiento expreso para tratar datos de salud (mediciones).
  final bool datosSalud;
  final DateTime? fechaDatosSalud;
  final String versionVigente;
  final SolicitudSupresion? solicitudSupresion;

  /// Hay que mostrarle el aviso: nunca aceptó o la versión cambió.
  bool get requiereAceptar => version == null || version != versionVigente;

  Consentimiento copyWith(
          {bool? datosSalud,
          DateTime? fechaDatosSalud,
          SolicitudSupresion? solicitudSupresion}) =>
      Consentimiento(
        version: version,
        fecha: fecha,
        datosSalud: datosSalud ?? this.datosSalud,
        fechaDatosSalud: fechaDatosSalud ?? this.fechaDatosSalud,
        versionVigente: versionVigente,
        solicitudSupresion: solicitudSupresion ?? this.solicitudSupresion,
      );

  factory Consentimiento.fromJson(Map<String, dynamic> j) => Consentimiento(
        version: j['version'] as String?,
        fecha: _fecha(j['fecha']),
        datosSalud: j['datosSalud'] == true,
        fechaDatosSalud: _fecha(j['fechaDatosSalud']),
        versionVigente: (j['versionVigente'] as String?) ?? '',
        solicitudSupresion: j['solicitudSupresion'] is Map<String, dynamic>
            ? SolicitudSupresion.fromJson(
                j['solicitudSupresion'] as Map<String, dynamic>)
            : null,
      );
}

/// Solicitud de eliminación de la cuenta (derecho de supresión).
class SolicitudSupresion {
  const SolicitudSupresion({required this.fecha, required this.estado});
  final DateTime? fecha;
  final String estado;

  bool get pendiente => estado == 'Pendiente';

  factory SolicitudSupresion.fromJson(Map<String, dynamic> j) =>
      SolicitudSupresion(
          fecha: _fecha(j['fecha']),
          estado: (j['estado'] as String?) ?? 'Pendiente');
}

DateTime? _fecha(Object? v) => v is String ? DateTime.tryParse(v) : null;
