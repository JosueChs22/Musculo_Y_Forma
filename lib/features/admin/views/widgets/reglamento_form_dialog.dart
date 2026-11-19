import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets.dart';
import '../../controllers/reglamentos_controller.dart';
import '../../models/reglamento.dart';

/// Formulario para publicar (RF-097) o editar (RF-098) un reglamento.
/// Si se pasa [reglamento], se abre en modo edición con sus datos.
class ReglamentoFormDialog extends StatefulWidget {
  const ReglamentoFormDialog({super.key, required this.controller, this.reglamento});
  final ReglamentosController controller;
  final Reglamento? reglamento;

  @override
  State<ReglamentoFormDialog> createState() => _ReglamentoFormDialogState();
}

class _ReglamentoFormDialogState extends State<ReglamentoFormDialog> {
  static const _maxTitulo = 150;
  static const _maxContenido = 10000;

  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.reglamento?.titulo);
  late final _contenido = TextEditingController(text: widget.reglamento?.contenido);

  bool get _editando => widget.reglamento != null;

  @override
  void dispose() {
    _titulo.dispose();
    _contenido.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final c = widget.controller;
    final ok = _editando
        ? await c.actualizarReglamento(
            id: widget.reglamento!.id,
            titulo: _titulo.text,
            contenido: _contenido.text,
          )
        : await c.crearReglamento(titulo: _titulo.text, contenido: _contenido.text);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(_editando
          ? 'Reglamento actualizado correctamente'
          : 'Reglamento publicado correctamente'),
    ));
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
          title: Text(_editando ? 'EDITAR REGLAMENTO' : 'NUEVO REGLAMENTO', style: display(28)),
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
                    minLines: 8,
                    maxLines: 14,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(labelText: 'Contenido', alignLabelWithHint: true),
                    validator: (v) => Validators.requerido(v, 'El contenido'),
                  ),
                  if (c.errorGuardar != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
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
