import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'anuncios_theme.dart';

class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});

  @override
  State<AnunciosScreen> createState() => _AnunciosScreenState();
}

class _AnunciosScreenState extends State<AnunciosScreen> {
  // Para Flutter Web o Windows en la misma computadora.
  // En un emulador Android usar http://10.0.2.2:3001
  static const String apiUrl = 'http://localhost:3001/api/anuncios';

  List<Map<String, dynamic>> anuncios = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarAnuncios();
  }

  Future<void> cargarAnuncios() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(Uri.parse(apiUrl));

      if (respuesta.statusCode != 200) {
        throw Exception('Error HTTP ${respuesta.statusCode}');
      }

      final datos = jsonDecode(respuesta.body);

      if (datos is! List) {
        throw Exception('La API no devolvió una lista');
      }

      if (!mounted) return;

      setState(() {
        anuncios = datos
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> abrirFormulario([Map<String, dynamic>? anuncio]) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioAnuncio(
        apiUrl: apiUrl,
        anuncio: anuncio,
      ),
    );

    if (guardado == true) {
      await cargarAnuncios();
    }
  }

  Future<void> inhabilitar(Map<String, dynamic> anuncio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inhabilitar anuncio'),
        content: Text(
          '¿Deseás inhabilitar "${anuncio['titulo']}"?\n\n'
          'El anuncio dejará de mostrarse como publicado, '
          'pero permanecerá guardado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, inhabilitar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final id = anuncio['_id'];

      final respuesta = await http.patch(
        Uri.parse('$apiUrl/$id/inhabilitar'),
      );

      if (respuesta.statusCode != 200) {
        throw Exception(_mensajeError(respuesta));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anuncio inhabilitado correctamente')),
      );

      await cargarAnuncios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  static String _mensajeError(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);
      return datos['mensaje']?.toString() ??
          'Error HTTP ${respuesta.statusCode}';
    } catch (_) {
      return 'Error HTTP ${respuesta.statusCode}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AnunciosTheme.cobalto,
        ),
      ),
      child: ColoredBox(
        color: AnunciosTheme.fondo,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MÚSCULO Y FORMA',
                  style: AnunciosTheme.texto(
                    size: 13,
                    color: AnunciosTheme.cobalto,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión de anuncios',
                  style: AnunciosTheme.titulo(size: 36),
                ),
                const SizedBox(height: 6),
                Text(
                  'Panel de la Secretaria',
                  style: AnunciosTheme.texto(),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      style: AnunciosTheme.botonPrincipal(),
                      onPressed: () => abrirFormulario(),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear anuncio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: cargarAnuncios,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar lista'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _contenido()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Text(
          'No se pudieron cargar los anuncios.\n$error',
          textAlign: TextAlign.center,
          style: AnunciosTheme.texto(),
        ),
      );
    }

    if (anuncios.isEmpty) {
      return Center(
        child: Text(
          'Todavía no hay anuncios registrados.',
          style: AnunciosTheme.texto(size: 17),
        ),
      );
    }

    return ListView.separated(
      itemCount: anuncios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final anuncio = anuncios[index];
        final activo = anuncio['estado'] == 'Activo';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: AnunciosTheme.tarjeta(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    anuncio['titulo']?.toString() ?? '',
                    style: AnunciosTheme.titulo(size: 24),
                  ),
                  Chip(
                    label: Text(activo ? 'Activo' : 'Inhabilitado'),
                    backgroundColor: activo
                        ? const Color(0xFFE2F5E9)
                        : const Color(0xFFF0F0F0),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                anuncio['contenido']?.toString() ?? '',
                style: AnunciosTheme.texto(),
              ),
              const SizedBox(height: 12),
              Text(
                'Clasificación: ${anuncio['clasificacion'] ?? 'Sin clasificación'}',
                style: AnunciosTheme.texto(size: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => abrirFormulario(anuncio),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  if (activo)
                    OutlinedButton.icon(
                      onPressed: () => inhabilitar(anuncio),
                      icon: const Icon(Icons.block),
                      label: const Text('Inhabilitar'),
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

class _FormularioAnuncio extends StatefulWidget {
  const _FormularioAnuncio({
    required this.apiUrl,
    this.anuncio,
  });

  final String apiUrl;
  final Map<String, dynamic>? anuncio;

  @override
  State<_FormularioAnuncio> createState() => _FormularioAnuncioState();
}

class _FormularioAnuncioState extends State<_FormularioAnuncio> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController titulo;
  late final TextEditingController contenido;
  late final TextEditingController clasificacion;

  DateTime? fechaPublicacion;
  DateTime? fechaFin;
  bool guardando = false;

  bool get editando => widget.anuncio != null;

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

    fechaPublicacion = DateTime.tryParse(
      datos['fecha_publicacion']?.toString() ?? '',
    )?.toLocal();

    fechaFin = DateTime.tryParse(
      datos['fecha_fin']?.toString() ?? '',
    )?.toLocal();
  }

  @override
  void dispose() {
    titulo.dispose();
    contenido.dispose();
    clasificacion.dispose();
    super.dispose();
  }

  Future<void> seleccionarFecha(bool publicacion) async {
    final actual = publicacion ? fechaPublicacion : fechaFin;

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (seleccionada == null || !mounted) return;

    setState(() {
      if (publicacion) {
        fechaPublicacion = seleccionada;
      } else {
        fechaFin = seleccionada;
      }
    });
  }

  String formatoFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  Future<void> guardar() async {
    if (!formKey.currentState!.validate()) return;

    if (fechaPublicacion == null ||
        (fechaFin != null && fechaFin!.isBefore(fechaPublicacion!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisá las fechas del anuncio')),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      final datos = <String, dynamic>{
        'titulo': titulo.text.trim(),
        'contenido': contenido.text.trim(),
        'clasificacion': clasificacion.text.trim().isEmpty
            ? null
            : clasificacion.text.trim(),
        'fecha_publicacion': fechaPublicacion!.toUtc().toIso8601String(),
        'fecha_fin': fechaFin?.toUtc().toIso8601String(),
      };

      final uri = editando
          ? Uri.parse('${widget.apiUrl}/${widget.anuncio!['_id']}')
          : Uri.parse(widget.apiUrl);

      final respuesta = editando
          ? await http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(datos),
            )
          : await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(datos),
            );

      if (respuesta.statusCode != (editando ? 200 : 201)) {
        final mensaje = jsonDecode(respuesta.body);
        throw Exception(mensaje['mensaje'] ?? 'Error al guardar');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A55E8),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          floatingLabelStyle: TextStyle(
            color: Color(0xFF3A55E8),
          ),
        ),
      ),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
                    style: AnunciosTheme.titulo(size: 30),
                  ),
                  const SizedBox(height: 20),

                  // TÍTULO
                  TextFormField(
                    controller: titulo,
                    maxLength: 150,
                    style: const TextStyle(color: Colors.black87),
                    cursorColor: const Color(0xFF3A55E8),
                    decoration: AnunciosTheme.campo('Título'),
                    validator: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Ingresá el título'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // CONTENIDO
                  TextFormField(
                    controller: contenido,
                    maxLength: 5000,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.black87),
                    cursorColor: const Color(0xFF3A55E8),
                    decoration: AnunciosTheme.campo('Contenido'),
                    validator: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Ingresá el contenido'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // CLASIFICACIÓN
                  TextFormField(
                    controller: clasificacion,
                    maxLength: 60,
                    style: const TextStyle(color: Colors.black87),
                    cursorColor: const Color(0xFF3A55E8),
                    decoration: AnunciosTheme.campo('Clasificación'),
                  ),
                  const SizedBox(height: 12),

                  // FECHA DE PUBLICACIÓN
                  OutlinedButton.icon(
                    onPressed: () => seleccionarFecha(true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Publicación: ${formatoFecha(fechaPublicacion)}',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // FECHA DE VENCIMIENTO
                  OutlinedButton.icon(
                    onPressed: () => seleccionarFecha(false),
                    icon: const Icon(Icons.event),
                    label: Text(
                      'Vencimiento: ${formatoFecha(fechaFin)}',
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() => fechaFin = null);
                    },
                    child: const Text('Sin fecha de vencimiento'),
                  ),

                  const SizedBox(height: 20),

                  // BOTONES
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      TextButton(
                        onPressed: guardando
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: AnunciosTheme.botonPrincipal(),
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
      ),
    );
  }
}
