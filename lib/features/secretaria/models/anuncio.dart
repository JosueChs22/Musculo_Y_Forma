import '../../../core/fechas.dart';

/// Clasificaciones con las que se puede etiquetar un anuncio (RF-017 #6).
/// Son las mismas que valida la API.
const kClasificacionesAnuncio = ['General', 'Promoción', 'Evento', 'Aviso', 'Clases'];

enum EstadoAnuncio {
  activo('Activo'),
  inhabilitado('Inhabilitado');

  const EstadoAnuncio(this.valor);
  final String valor;

  static EstadoAnuncio desdeTexto(String t) => values.firstWhere(
        (e) => e.valor == t,
        orElse: () => throw FormatException('Estado no válido: $t'),
      );
}

DateTime? _fecha(Object? v) => v == null ? null : DateTime.parse(v as String);

/// Anuncio tal como lo devuelve la API (DTO en camelCase).
///
/// Las listas llegan sin la imagen (pesa): traen [tieneImagen] y la imagen se pide
/// al abrir el detalle. Cuando viene, [imagen] es una data URL ("data:image/jpeg;base64,...").
class Anuncio {
  const Anuncio({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.estado,
    required this.fechaPublicacion,
    this.clasificacion,
    this.imagen,
    this.tieneImagen = false,
    this.fechaFin,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.fechaInhabilitacion,
  });

  final String id;
  final String titulo;
  final String contenido;
  final String? clasificacion;
  final String? imagen;
  final bool tieneImagen;
  final EstadoAnuncio estado;
  final DateTime fechaPublicacion;
  final DateTime? fechaFin;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final DateTime? fechaInhabilitacion;

  bool get estaActivo => estado == EstadoAnuncio.activo;

  /// Ya pasó su fecha de fin (la API deja de mostrarlo a los clientes).
  bool get vencido => fechaFin != null && fechaFin!.isBefore(DateTime.now());

  /// Todavía no llega su fecha de publicación.
  bool get programado => fechaPublicacion.isAfter(DateTime.now());

  /// Activo, ya publicado y sin vencer: es el que ven los clientes.
  bool get enVigencia => estaActivo && !vencido && !programado;

  /// Estado a mostrar (RF-032 #5): además de Activo / Inhabilitado avisa si ya venció
  /// o si todavía no llega su fecha de publicación.
  String get etiquetaEstado {
    if (!estaActivo) return estado.valor;
    if (vencido) return '${estado.valor} (vencido)';
    if (programado) return '${estado.valor} (programado)';
    return estado.valor;
  }

  /// Texto de vigencia (RF-032 #4).
  String get textoVigencia => fechaFin == null ? 'sin fecha de fin' : 'hasta ${fechaCorta(fechaFin!)}';

  factory Anuncio.fromJson(Map<String, dynamic> json) => Anuncio(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        contenido: json['contenido'] as String,
        clasificacion: json['clasificacion'] as String?,
        imagen: json['imagen'] as String?,
        tieneImagen: json['tieneImagen'] as bool? ?? json['imagen'] != null,
        estado: EstadoAnuncio.desdeTexto(json['estado'] as String),
        fechaPublicacion: DateTime.parse(json['fechaPublicacion'] as String),
        fechaFin: _fecha(json['fechaFin']),
        fechaCreacion: _fecha(json['fechaCreacion']),
        fechaActualizacion: _fecha(json['fechaActualizacion']),
        fechaInhabilitacion: _fecha(json['fechaInhabilitacion']),
      );

  Anuncio copyWith({EstadoAnuncio? estado}) => Anuncio(
        id: id,
        titulo: titulo,
        contenido: contenido,
        clasificacion: clasificacion,
        imagen: imagen,
        tieneImagen: tieneImagen,
        estado: estado ?? this.estado,
        fechaPublicacion: fechaPublicacion,
        fechaFin: fechaFin,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion,
        fechaInhabilitacion: fechaInhabilitacion,
      );
}
