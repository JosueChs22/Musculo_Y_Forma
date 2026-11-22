import 'package:flutter/material.dart';

import '../../../../core/fechas.dart';
import '../../../../core/theme.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets.dart';
import '../../controllers/anuncios_controller.dart';
import '../../models/anuncio.dart';
import '../../utils/imagen_anuncio.dart';

/// Formulario para publicar (RF-017) o editar (RF-022) un anuncio.
/// Si se pasa [anuncio], se abre en modo edición con sus datos.
class AnuncioFormDialog extends StatefulWidget {
  const AnuncioFormDialog({super.key, required this.controller, this.anuncio});
  final AnunciosController controller;
  final Anuncio? anuncio;

  @override
  State<AnuncioFormDialog> createState() => _AnuncioFormDialogState();
}

class _AnuncioFormDialogState extends State<AnuncioFormDialog> {
  static const _maxTitulo = 150;
  static const _maxContenido = 5000;

  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.anuncio?.titulo);
  late final _contenido = TextEditingController(text: widget.anuncio?.contenido);

  late String _clasificacion = _clasificacionInicial();
  late DateTime _publicacion = _soloDia(widget.anuncio?.fechaPublicacion ?? DateTime.now());
  late DateTime? _fin = widget.anuncio?.fechaFin == null ? null : _soloDia(widget.anuncio!.fechaFin!);

  // Imagen: _imagen es la que se muestra (data URL). Si el anuncio ya tenía una pero no
  // se pudo traer, _tieneActual la marca y se conserva sin tocarla.
  late String? _imagen = widget.anuncio?.imagen;
  late bool _tieneActual = widget.anuncio?.tieneImagen ?? false;
  bool _cambioImagen = false;
  bool _eligiendo = false;
  String? _errorImagen;

  bool get _editando => widget.anuncio != null;
  bool get _hayImagen => _imagen != null || _tieneActual;

  static DateTime get _hoy {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Las fechas no pueden quedar en el pasado, salvo una que ya tenía el anuncio y no se tocó
  /// (así se puede corregir un anuncio viejo). RF-017 #5: la vigencia no puede terminar antes de empezar.
  String? get _errorFechas {
    final a = widget.anuncio;
    final pubOriginal = a == null ? null : _soloDia(a.fechaPublicacion);
    final finOriginal = a?.fechaFin == null ? null : _soloDia(a!.fechaFin!);
    if (_publicacion.isBefore(_hoy) && _publicacion != pubOriginal) {
      return 'La fecha de publicación no puede ser anterior a hoy.';
    }
    if (_fin != null && _fin!.isBefore(_hoy) && _fin != finOriginal) {
      return 'La fecha de fin no puede ser anterior a hoy.';
    }
    if (_fin != null && _fin!.isBefore(_publicacion)) {
      return 'La fecha de fin no puede ser anterior a la de publicación.';
    }
    return null;
  }

  String _clasificacionInicial() {
    final c = widget.anuncio?.clasificacion;
    return (c != null && kClasificacionesAnuncio.contains(c)) ? c : kClasificacionesAnuncio.first;
  }

  static DateTime _soloDia(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _contenido.dispose();
    super.dispose();
  }

  Future<void> _elegirPublicacion() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _publicacion,
      firstDate: _editando ? DateTime(2020) : _hoy,
      lastDate: DateTime(2100),
      helpText: 'Fecha de publicación',
    );
    if (d != null) setState(() => _publicacion = d);
  }

  Future<void> _elegirFin() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fin ?? _publicacion,
      firstDate: _editando ? DateTime(2020) : _hoy,
      lastDate: DateTime(2100),
      helpText: 'Fecha de fin de vigencia',
    );
    if (d != null) setState(() => _fin = d);
  }

  Future<void> _elegirImagen() async {
    setState(() {
      _eligiendo = true;
      _errorImagen = null;
    });
    final r = await elegirImagen();
    if (!mounted) return;
    setState(() {
      _eligiendo = false;
      if (r.dataUrl != null) {
        _imagen = r.dataUrl;
        _cambioImagen = true;
      }
      _errorImagen = r.error;
    });
  }

  void _quitarImagen() => setState(() {
        _imagen = null;
        _tieneActual = false;
        _cambioImagen = true;
        _errorImagen = null;
      });

  Future<void> _guardar() async {
    if (!_form.currentState!.validate() || _errorFechas != null) {
      setState(() {}); // muestra el error de fechas si lo hay
      return;
    }
    final c = widget.controller;
    final ok = _editando
        ? await c.actualizarAnuncio(
            id: widget.anuncio!.id,
            titulo: _titulo.text,
            contenido: _contenido.text,
            clasificacion: _clasificacion,
            fechaPublicacion: _publicacion,
            fechaFin: _fin,
            imagen: _imagen,
            cambiarImagen: _cambioImagen,
          )
        : await c.crearAnuncio(
            titulo: _titulo.text,
            contenido: _contenido.text,
            clasificacion: _clasificacion,
            fechaPublicacion: _publicacion,
            fechaFin: _fin,
            imagen: _imagen,
          );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(_editando ? 'Anuncio actualizado correctamente' : 'Anuncio publicado correctamente'),
    ));
  }

  Widget _seccionImagen(bool enabled) {
    final dataUrl = _imagen;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('Imagen (opcional)'),
      const SizedBox(height: 8),
      if (dataUrl != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: AppColors.niebla,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Image.memory(
                bytesDeDataUrl(dataUrl),
                width: double.infinity,
                fit: BoxFit.contain, // completa, sin recortar
                errorBuilder: (context, error, stack) =>
                    Text('No se pudo mostrar la imagen.', style: ts(14, color: AppColors.danger)),
              ),
            ),
          ),
        )
      else if (_tieneActual)
        Text('El anuncio ya tiene una imagen: se conserva si no la cambia.', style: ts(14, color: AppColors.pizarra)),
      if (_hayImagen) const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SecondaryButton(
          label: _hayImagen ? 'Cambiar imagen' : 'Adjuntar imagen',
          icon: Icons.image_outlined,
          onPressed: enabled && !_eligiendo ? _elegirImagen : null,
        ),
        if (_hayImagen)
          TextButton(
            onPressed: enabled ? _quitarImagen : null,
            child: Text('Quitar', style: ts(15, weight: kSemi, color: AppColors.danger)),
          ),
      ]),
      if (_errorImagen != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_errorImagen!, style: ts(14, weight: kSemi, color: AppColors.danger)),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final enabled = !c.guardando;

        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(_editando ? 'EDITAR ANUNCIO' : 'NUEVO ANUNCIO', style: display(28)),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextFormField(
                    controller: _titulo,
                    enabled: enabled,
                    maxLength: _maxTitulo,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => Validators.requerido(v, 'El título'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contenido,
                    enabled: enabled,
                    maxLength: _maxContenido,
                    minLines: 5,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(labelText: 'Contenido', alignLabelWithHint: true),
                    validator: (v) => Validators.requerido(v, 'El contenido'),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Clasificación'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _clasificacion,
                        isExpanded: true,
                        isDense: true,
                        items: [
                          for (final k in kClasificacionesAnuncio) DropdownMenuItem(value: k, child: Text(k)),
                        ],
                        onChanged: enabled ? (v) => setState(() => _clasificacion = v ?? _clasificacion) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CampoFecha(
                    label: 'Fecha de publicación',
                    valor: _publicacion,
                    vacio: '',
                    enabled: enabled,
                    onTap: _elegirPublicacion,
                  ),
                  const SizedBox(height: 16),
                  _CampoFecha(
                    label: 'Fecha de fin de vigencia (opcional)',
                    valor: _fin,
                    vacio: 'Sin fecha de fin',
                    enabled: enabled,
                    onTap: _elegirFin,
                    onLimpiar: () => setState(() => _fin = null),
                  ),
                  if (_errorFechas != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_errorFechas!, style: ts(14, weight: kSemi, color: AppColors.danger)),
                    ),
                  const SizedBox(height: 16),
                  _seccionImagen(enabled),
                  if (c.errorGuardar != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(c.errorGuardar!, style: ts(14, weight: kSemi, color: AppColors.danger)),
                    ),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: enabled ? () => Navigator.of(context).pop() : null,
              child: Text('Cancelar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
            ),
            PrimaryButton(
              label: _editando ? 'Guardar cambios' : 'Publicar',
              busy: c.guardando,
              onPressed: _guardar,
            ),
          ],
        );
      },
    );
  }
}

/// Campo que muestra una fecha y abre el selector al tocarlo. Con [onLimpiar] y una fecha
/// elegida aparece una X para quitarla.
class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.label,
    required this.valor,
    required this.vacio,
    required this.enabled,
    required this.onTap,
    this.onLimpiar,
  });

  final String label;
  final DateTime? valor;
  final String vacio;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    final puedeLimpiar = onLimpiar != null && valor != null;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: puedeLimpiar
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Quitar fecha',
                  onPressed: enabled ? onLimpiar : null,
                )
              : const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          valor == null ? vacio : fechaCorta(valor!),
          style: ts(16, color: valor == null ? AppColors.pizarra : AppColors.ink),
        ),
      ),
    );
  }
}
