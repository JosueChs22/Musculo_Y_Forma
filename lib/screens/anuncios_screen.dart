import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/theme.dart';

// API local de pruebas del Sprint 3.
const String _apiUrl = 'http://localhost:3001/api/anuncios';

// Tamaño máximo de imagen: 3 MB.
const int _maxImagen = 3 * 1024 * 1024;

// ==========================================
// FUNCIONES AUXILIARES
// ==========================================

String _fecha(dynamic valor) {
  if (valor == null || valor.toString().isEmpty) {
    return 'Sin vencimiento';
  }

  final fecha = DateTime.tryParse(valor.toString());

  if (fecha == null) {
    return 'No disponible';
  }

  final f = fecha.toLocal();

  return '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/'
      '${f.year}';
}

DateTime? _leerFecha(dynamic valor) {
  return DateTime.tryParse(
    valor?.toString() ?? '',
  )?.toLocal();
}

String _errorHttp(http.Response respuesta) {
  try {
    final body = jsonDecode(respuesta.body);

    if (body is Map) {
      return (body['mensaje'] ??
              body['error'] ??
              'HTTP ${respuesta.statusCode}')
          .toString();
    }
  } catch (_) {
    // Respuesta sin JSON válido.
  }

  return 'Error HTTP ${respuesta.statusCode}';
}

String? _urlImagen(dynamic imagen) {
  if (imagen is! String || imagen.trim().isEmpty) {
    return null;
  }

  if (imagen.startsWith('https://') || imagen.startsWith('http://')) {
    return imagen;
  }

  if (imagen.startsWith('/uploads/')) {
    return 'http://localhost:3001$imagen';
  }

  return null;
}

ButtonStyle _estiloPrincipal() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.ambar,
    foregroundColor: AppColors.ink,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

// ==========================================
// PANTALLA PRINCIPAL DE ANUNCIOS
// ==========================================

class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});

  @override
  State<AnunciosScreen> createState() {
    return _AnunciosScreenState();
  }
}

class _AnunciosScreenState extends State<AnunciosScreen> {
  List<Map<String, dynamic>> anuncios = [];

  bool cargando = false;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarAnuncios();
  }

  // ==========================================
  // GYM-82: VISUALIZAR ANUNCIOS
  // ==========================================

  Future<void> cargarAnuncios() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 20));

      if (respuesta.statusCode != 200) {
        throw Exception(_errorHttp(respuesta));
      }

      final datos = jsonDecode(respuesta.body);

      if (datos is! List) {
        throw Exception(
          'La API no devolvió una lista de anuncios',
        );
      }

      final lista = datos
          .map(
            (e) => Map<String, dynamic>.from(
              e as Map,
            ),
          )
          .toList();

      // Mostrar los anuncios recién creados primero.
      // Se utiliza el ObjectId de MongoDB.
      lista.sort((a, b) {
        final idA = a['_id']?.toString() ?? '';
        final idB = b['_id']?.toString() ?? '';

        return idB.compareTo(idA);
      });

      if (!mounted) return;

      setState(() {
        anuncios = lista;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  // ==========================================
  // CREAR Y EDITAR ANUNCIOS
  // ==========================================

  Future<void> abrirFormulario([
    Map<String, dynamic>? anuncio,
  ]) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _FormularioAnuncio(
          anuncio: anuncio,
        );
      },
    );

    if (guardado == true) {
      await cargarAnuncios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            anuncio == null
                ? 'Anuncio creado correctamente'
                : 'Anuncio actualizado correctamente',
          ),
        ),
      );
    }
  }

  // ==========================================
  // GYM-77: INHABILITAR ANUNCIOS
  // ==========================================

  Future<void> inhabilitar(
    Map<String, dynamic> anuncio,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Inhabilitar anuncio'),
          content: Text(
            '¿Deseás inhabilitar "${anuncio['titulo']}"?\n\n'
            'El anuncio permanecerá en la base de datos.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              child: const Text('Inhabilitar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    try {
      final id = anuncio['_id'];

      final respuesta = await http
          .patch(
            Uri.parse('$_apiUrl/$id/inhabilitar'),
          )
          .timeout(const Duration(seconds: 20));

      if (respuesta.statusCode != 200) {
        throw Exception(_errorHttp(respuesta));
      }

      await cargarAnuncios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anuncio inhabilitado correctamente',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  // ==========================================
  // VER DETALLES CON IMAGEN
  // ==========================================

  void verDetalles(
    Map<String, dynamic> anuncio,
  ) {
    final imagen = _urlImagen(
      anuncio['imagen'],
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            anuncio['titulo']?.toString() ?? 'Anuncio',
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imagen != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imagen,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Text(
                            'No se pudo cargar la imagen',
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    anuncio['contenido']?.toString() ?? '',
                    style: ts(15),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Clasificación: '
                    '${anuncio['clasificacion'] ?? 'Sin clasificación'}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publicación: '
                    '${_fecha(anuncio['fecha_publicacion'])}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vencimiento: '
                    '${_fecha(anuncio['fecha_fin'])}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: ${anuncio['estado']}',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.niebla,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MÚSCULO Y FORMA',
                style: ts(
                  13,
                  weight: kSemi,
                  color: AppColors.cobalto,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestión de anuncios',
                style: display(
                  36,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Panel de la Secretaria',
                style: ts(
                  15,
                  color: AppColors.pizarra,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    style: _estiloPrincipal(),
                    onPressed: () {
                      abrirFormulario();
                    },
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Crear anuncio',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: cargarAnuncios,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'Actualizar lista',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _contenido(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          'No se pudieron cargar los anuncios.\n$error',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (anuncios.isEmpty) {
      return Center(
        child: Text(
          'Todavía no hay anuncios registrados.',
          style: ts(
            16,
            color: AppColors.pizarra,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: anuncios.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 14);
      },
      itemBuilder: (context, index) {
        final anuncio = anuncios[index];

        final activo = anuncio['estado'] == 'Activo';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    anuncio['titulo']?.toString() ?? '',
                    style: display(
                      24,
                      color: AppColors.indigo,
                    ),
                  ),
                  Chip(
                    label: Text(
                      activo ? 'Activo' : 'Inhabilitado',
                    ),
                    backgroundColor: activo
                        ? const Color(0xFFE2F5E9)
                        : const Color(0xFFF0F0F0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                anuncio['contenido']?.toString() ?? '',
                style: ts(
                  15,
                  color: AppColors.pizarra,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Clasificación: '
                '${anuncio['clasificacion'] ?? 'Sin clasificación'}',
              ),
              const SizedBox(height: 6),
              Text(
                'Publicación: '
                '${_fecha(anuncio['fecha_publicacion'])}',
              ),
              const SizedBox(height: 6),
              Text(
                'Vencimiento: '
                '${_fecha(anuncio['fecha_fin'])}',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      verDetalles(anuncio);
                    },
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    label: const Text(
                      'Ver detalles',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      abrirFormulario(anuncio);
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label: const Text(
                      'Editar',
                    ),
                  ),
                  if (activo)
                    OutlinedButton.icon(
                      onPressed: () {
                        inhabilitar(anuncio);
                      },
                      icon: const Icon(
                        Icons.block,
                      ),
                      label: const Text(
                        'Inhabilitar',
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// FORMULARIO DE ANUNCIOS
// ==========================================

class _FormularioAnuncio extends StatefulWidget {
  const _FormularioAnuncio({
    this.anuncio,
  });

  final Map<String, dynamic>? anuncio;

  @override
  State<_FormularioAnuncio> createState() {
    return _FormularioAnuncioState();
  }
}

class _FormularioAnuncioState extends State<_FormularioAnuncio> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController titulo;
  late final TextEditingController contenido;
  late final TextEditingController clasificacion;

  DateTime? fechaPublicacion;
  DateTime? fechaFin;

  Uint8List? imagenBytes;
  String? nombreImagen;

  bool guardando = false;

  bool get editando {
    return widget.anuncio != null;
  }

  @override
  void initState() {
    super.initState();

    final datos = widget.anuncio ?? {};

    titulo = TextEditingController(
      text: datos['titulo']?.toString() ?? '',
    );

    contenido = TextEditingController(
      text: datos['contenido']?.toString() ?? '',
    );

    clasificacion = TextEditingController(
      text: datos['clasificacion']?.toString() ?? '',
    );

    fechaPublicacion = _leerFecha(
      datos['fecha_publicacion'],
    );

    fechaFin = _leerFecha(
      datos['fecha_fin'],
    );
  }

  @override
  void dispose() {
    titulo.dispose();
    contenido.dispose();
    clasificacion.dispose();
    super.dispose();
  }

  void aviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  // ==========================================
  // SELECCIONAR FECHAS
  // ==========================================

  Future<void> seleccionarFecha(
    bool publicacion,
  ) async {
    final actual = publicacion ? fechaPublicacion : fechaFin;

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (seleccionada == null || !mounted) {
      return;
    }

    setState(() {
      if (publicacion) {
        fechaPublicacion = seleccionada;
      } else {
        fechaFin = seleccionada;
      }
    });
  }

  // ==========================================
  // SELECCIONAR IMAGEN
  // CORREGIDO PARA FILE_PICKER ACTUAL
  // ==========================================

  Future<void> seleccionarImagen() async {
    try {
      final archivo = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
      );

      // El usuario canceló la selección.
      if (archivo == null || !mounted) {
        return;
      }

      final extension = archivo.extension?.toLowerCase() ?? '';

      if (![
        'jpg',
        'jpeg',
        'png',
        'webp',
      ].contains(extension)) {
        aviso(
          'Solo se permiten imágenes JPG, PNG o WebP',
        );
        return;
      }

      // Comprobar tamaño antes de leer el archivo.
      final tamano = await archivo.length();

      if (tamano != null && tamano > _maxImagen) {
        if (!mounted) return;

        aviso(
          'La imagen no debe superar los 3 MB',
        );
        return;
      }

      // Leer los datos de la imagen.
      final bytes = await archivo.readAsBytes();

      if (!mounted) return;

      if (bytes.length > _maxImagen) {
        aviso(
          'La imagen no debe superar los 3 MB',
        );
        return;
      }

      if (bytes.isEmpty) {
        aviso(
          'La imagen seleccionada está vacía',
        );
        return;
      }

      // Guardar imagen para vista previa y envío.
      setState(() {
        imagenBytes = bytes;
        nombreImagen = archivo.name;
      });
    } catch (e) {
      if (!mounted) return;

      aviso(
        'Error al seleccionar la imagen: $e',
      );
    }
  }

  // ==========================================
  // FORMATO DE FECHAS
  // ==========================================

  String formatoFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Seleccionar fecha';
    }

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  // ==========================================
  // GYM-67 / GYM-72
  // CREAR Y ACTUALIZAR CON IMÁGENES
  // ==========================================

  Future<void> guardar() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (fechaPublicacion == null) {
      aviso(
        'Seleccioná la fecha de publicación',
      );
      return;
    }

    if (fechaFin != null && fechaFin!.isBefore(fechaPublicacion!)) {
      aviso(
        'La fecha de vencimiento es inválida',
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final uri = editando
          ? Uri.parse(
              '$_apiUrl/${widget.anuncio!['_id']}',
            )
          : Uri.parse(_apiUrl);

      // Enviar datos como multipart/form-data.
      final solicitud = http.MultipartRequest(
        editando ? 'PUT' : 'POST',
        uri,
      );

      solicitud.fields.addAll({
        'titulo': titulo.text.trim(),
        'contenido': contenido.text.trim(),
        'clasificacion': clasificacion.text.trim(),
        'fecha_publicacion': fechaPublicacion!.toUtc().toIso8601String(),
        'fecha_fin': fechaFin?.toUtc().toIso8601String() ?? '',
      });

      // Adjuntar imagen si el usuario seleccionó una.
      if (imagenBytes != null && nombreImagen != null) {
        final extension = nombreImagen!.split('.').last.toLowerCase();

        final tipo = extension == 'png'
            ? MediaType('image', 'png')
            : extension == 'webp'
                ? MediaType('image', 'webp')
                : MediaType('image', 'jpeg');

        solicitud.files.add(
          http.MultipartFile.fromBytes(
            'imagen',
            imagenBytes!,
            filename: nombreImagen!,
            contentType: tipo,
          ),
        );
      }

      // Enviar al backend.
      final enviada = await solicitud.send().timeout(
            const Duration(seconds: 60),
          );

      final respuesta = await http.Response.fromStream(
        enviada,
      );

      final esperado = editando ? 200 : 201;

      if (respuesta.statusCode != esperado) {
        throw Exception(
          _errorHttp(respuesta),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        aviso(
          'Error al guardar el anuncio: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  // ==========================================
  // INTERFAZ DEL FORMULARIO
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editando ? 'Editar anuncio' : 'Crear anuncio',
                  style: display(
                    30,
                    color: AppColors.indigo,
                  ),
                ),

                const SizedBox(height: 20),

                // TÍTULO
                TextFormField(
                  controller: titulo,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresá el título';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // CONTENIDO
                TextFormField(
                  controller: contenido,
                  maxLength: 5000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresá el contenido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // CLASIFICACIÓN
                TextFormField(
                  controller: clasificacion,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Clasificación',
                  ),
                ),

                const SizedBox(height: 16),

                // BOTÓN PARA ADJUNTAR IMAGEN
                OutlinedButton.icon(
                  onPressed: guardando ? null : seleccionarImagen,
                  icon: const Icon(
                    Icons.image_outlined,
                  ),
                  label: Text(
                    imagenBytes == null
                        ? (editando && widget.anuncio?['imagen'] != null
                            ? 'Cambiar imagen'
                            : 'Adjuntar imagen')
                        : 'Cambiar imagen seleccionada',
                  ),
                ),

                if (nombreImagen != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    nombreImagen!,
                    style: ts(
                      13,
                      color: AppColors.pizarra,
                    ),
                  ),
                ],

                // VISTA PREVIA DE IMAGEN NUEVA
                if (imagenBytes != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imagenBytes!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  TextButton(
                    onPressed: guardando
                        ? null
                        : () {
                            setState(() {
                              imagenBytes = null;
                              nombreImagen = null;
                            });
                          },
                    child: const Text(
                      'Quitar selección',
                    ),
                  ),
                ]

                // IMAGEN ANTERIOR EN EDICIÓN
                else if (editando &&
                    _urlImagen(
                          widget.anuncio?['imagen'],
                        ) !=
                        null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _urlImagen(
                        widget.anuncio?['imagen'],
                      )!,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Text(
                          'Imagen anterior no disponible',
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // FECHA DE PUBLICACIÓN
                OutlinedButton.icon(
                  onPressed: guardando
                      ? null
                      : () {
                          seleccionarFecha(true);
                        },
                  icon: const Icon(
                    Icons.calendar_today,
                  ),
                  label: Text(
                    'Publicación: '
                    '${formatoFecha(fechaPublicacion)}',
                  ),
                ),

                const SizedBox(height: 8),

                // FECHA DE VENCIMIENTO
                OutlinedButton.icon(
                  onPressed: guardando
                      ? null
                      : () {
                          seleccionarFecha(false);
                        },
                  icon: const Icon(
                    Icons.event,
                  ),
                  label: Text(
                    'Vencimiento: '
                    '${formatoFecha(fechaFin)}',
                  ),
                ),

                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                          setState(() {
                            fechaFin = null;
                          });
                        },
                  child: const Text(
                    'Sin fecha de vencimiento',
                  ),
                ),

                const SizedBox(height: 20),

                // BOTONES DEL FORMULARIO
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    TextButton(
                      onPressed: guardando
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    ElevatedButton(
                      style: _estiloPrincipal(),
                      onPressed: guardando ? null : guardar,
                      child: Text(
                        guardando
                            ? 'Guardando...'
                            : editando
                                ? 'Guardar cambios'
                                : 'Crear anuncio',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
