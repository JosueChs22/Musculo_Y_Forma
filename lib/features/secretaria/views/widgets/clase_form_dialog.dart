import 'package:flutter/material.dart';

import '../../../../core/widgets.dart';
import '../../models/clase.dart';

/// Diálogo para crear o actualizar una Clase (RF-013 / RF-018).
class ClaseFormDialog extends StatefulWidget {
  const ClaseFormDialog({super.key, this.clase});

  /// Si es null, crea una clase nueva; si no, edita la existente.
  final Clase? clase;

  static Future<({String nombre, String? descripcion})?> show(
    BuildContext context, {
    Clase? clase,
  }) =>
      showDialog<({String nombre, String? descripcion})>(
        context: context,
        builder: (_) => ClaseFormDialog(clase: clase),
      );

  @override
  State<ClaseFormDialog> createState() => _ClaseFormDialogState();
}

class _ClaseFormDialogState extends State<ClaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.clase?.nombre ?? '');
    _descripcion = TextEditingController(text: widget.clase?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.clase != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageTitle(
                  eyebrow: esEdicion ? 'Editar' : 'Crear',
                  title: esEdicion ? 'Editar clase' : 'Nueva clase',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre de la clase'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcion,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Cancelar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    PrimaryButton(
                      label: esEdicion ? 'Guardar cambios' : 'Crear clase',
                      onPressed: _submit,
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
