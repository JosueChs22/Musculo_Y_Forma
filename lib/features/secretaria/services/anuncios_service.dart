import '../models/anuncio.dart';

/// Una página de anuncios y el cursor para pedir la siguiente (null si no hay más).
class PaginaAnuncios {
  const PaginaAnuncios(this.anuncios, this.siguiente);
  final List<Anuncio> anuncios;
  final String? siguiente;
}

/// Contrato del servicio de anuncios (panel de la Secretaria).
abstract class AnunciosService {
  /// RF-032: anuncios activos e inhabilitados, del más nuevo al más viejo, sin la imagen.
  Future<PaginaAnuncios> getAnuncios({String? cursor});

  /// RF-092: lo que ven los clientes: solo anuncios activos y vigentes, con su imagen.
  Future<PaginaAnuncios> getAnunciosVigentes({String? cursor});

  /// RF-032 #6: el anuncio completo, con su imagen.
  Future<Anuncio> getAnuncio(String id);

  /// RF-017: publica un anuncio (queda Activo). [imagen] es una data URL o null.
  Future<Anuncio> crearAnuncio({
    required String titulo,
    required String contenido,
    required String clasificacion,
    required DateTime fechaPublicacion,
    DateTime? fechaFin,
    String? imagen,
  });

  /// RF-022: modifica el anuncio. La imagen solo se toca si [cambiarImagen] es true:
  /// con [imagen] null se quita y con una data URL se reemplaza.
  Future<Anuncio> actualizarAnuncio({
    required String id,
    required String titulo,
    required String contenido,
    required String clasificacion,
    required DateTime fechaPublicacion,
    DateTime? fechaFin,
    String? imagen,
    bool cambiarImagen = false,
  });

  /// RF-027: cambia el estado a Inhabilitado (no borra nada).
  Future<Anuncio> inhabilitarAnuncio(String id);

  /// Vuelve a publicar un anuncio inhabilitado.
  Future<Anuncio> habilitarAnuncio(String id);
}
