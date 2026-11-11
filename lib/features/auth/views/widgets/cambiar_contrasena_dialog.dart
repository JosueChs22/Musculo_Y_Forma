import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets.dart';
import '../../controllers/auth_controller.dart';

/// Formulario para cambiar la contraseña del usuario con sesión iniciada (RF-035).
class CambiarContrasenaDialog extends StatefulWidget {
  const CambiarContrasenaDialog({super.key, required this.controller});
  final AuthController controller;

  @override
  State<CambiarContrasenaDialog> createState() => _CambiarContrasenaDialogState();
}

class _CambiarContrasenaDialogState extends State<CambiarContrasenaDialog> {
  final _form = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final ok = await widget.controller.cambiarContrasena(_actual.text, _nueva.text);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final enabled = !c.cambiando;

        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('CAMBIAR CONTRASEÑA', style: display(28)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _campo(
                    _actual,
                    'Contraseña actual',
                    enabled,
                    (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                    sufijo: IconButton(
                      tooltip: _ocultar ? 'Mostrar contraseñas' : 'Ocultar contraseñas',
                      icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                    ),
                  ),
                  _campo(
                    _nueva,
                    'Nueva contraseña',
                    enabled,
                    (v) => Validators.contrasena(v) ?? Validators.distintaDeActual(v, _actual.text),
                  ),
                  _campo(
                    _confirmar,
                    'Confirmar nueva contraseña',
                    enabled,
                    (v) => Validators.confirmacion(v, _nueva.text),
                  ),
                  Text(
                    'Mínimo 8 caracteres, con al menos una letra y un número, sin espacios.',
                    style: ts(13, color: AppColors.pizarra),
                  ),
                  if (c.errorCambio != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(c.errorCambio!, style: ts(14, weight: kSemi, color: AppColors.danger)),
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
            PrimaryButton(label: 'Guardar', busy: c.cambiando, onPressed: _guardar),
          ],
        );
      },
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta,
    bool enabled,
    String? Function(String?) validator, {
    Widget? sufijo,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: _ocultar,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: etiqueta, suffixIcon: sufijo),
          validator: validator,
        ),
      );
}
