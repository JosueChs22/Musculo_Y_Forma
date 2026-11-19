import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets.dart';
import '../../../auth/models/usuario.dart';
import '../../controllers/usuarios_controller.dart';

/// Formulario para crear (RF-096) o editar (RF-099) una Secretaria o un Entrenador.
/// Si se pasa [usuario], se abre en modo edición con sus datos y la contraseña opcional.
class UsuarioFormDialog extends StatefulWidget {
  const UsuarioFormDialog({super.key, required this.controller, this.usuario});
  final UsuariosController controller;
  final Usuario? usuario;

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario?.nombre);
  late final _apellido1 = TextEditingController(text: widget.usuario?.primerApellido);
  late final _apellido2 = TextEditingController(text: widget.usuario?.segundoApellido);
  late final _correo = TextEditingController(text: widget.usuario?.correo);
  late final _telefono = TextEditingController(text: widget.usuario?.telefono);
  late final _usuario = TextEditingController(text: widget.usuario?.usuario);
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();

  late RolUsuario _rol = widget.usuario?.rol ?? RolUsuario.secretaria;
  bool _ocultar = true;

  bool get _editando => widget.usuario != null;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido1, _apellido2, _correo, _telefono, _usuario, _contrasena, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final c = widget.controller;
    final ok = _editando
        ? await c.actualizarUsuario(
            id: widget.usuario!.id,
            nombre: _nombre.text,
            primerApellido: _apellido1.text,
            segundoApellido: _apellido2.text,
            correo: _correo.text,
            telefono: _telefono.text,
            rol: _rol,
            usuario: _usuario.text,
            contrasena: _contrasena.text, // vacía = no se cambia
          )
        : await c.crearUsuario(
            nombre: _nombre.text,
            primerApellido: _apellido1.text,
            segundoApellido: _apellido2.text,
            correo: _correo.text,
            telefono: _telefono.text,
            rol: _rol,
            usuario: _usuario.text,
            contrasena: _contrasena.text,
          );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(_editando ? 'Usuario actualizado correctamente' : 'Usuario creado correctamente'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final enabled = !c.guardando;
        final error = _editando ? c.errorEditar : c.errorCrear;

        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(_editando ? 'EDITAR USUARIO' : 'NUEVO USUARIO', style: display(28)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Eyebrow('Rol'),
                  const SizedBox(height: 8),
                  SegmentedButton<RolUsuario>(
                    segments: const [
                      ButtonSegment(value: RolUsuario.secretaria, label: Text('Secretaria')),
                      ButtonSegment(value: RolUsuario.entrenador, label: Text('Entrenador')),
                    ],
                    selected: {_rol},
                    showSelectedIcon: false,
                    onSelectionChanged: enabled ? (s) => setState(() => _rol = s.first) : null,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.indigo,
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _campo(_nombre, 'Nombre', enabled, (v) => Validators.requerido(v, 'El nombre')),
                  _campo(_apellido1, 'Primer apellido', enabled,
                      (v) => Validators.requerido(v, 'El primer apellido')),
                  _campo(_apellido2, 'Segundo apellido (opcional)', enabled, null),
                  _campo(_correo, 'Correo electrónico', enabled, Validators.correo,
                      tipo: TextInputType.emailAddress),
                  _campo(_telefono, 'Teléfono (8 dígitos)', enabled, Validators.telefono,
                      tipo: TextInputType.phone),
                  _campo(_usuario, 'Nombre de usuario', enabled, Validators.usuario),
                  _campo(
                    _contrasena,
                    _editando ? 'Nueva contraseña (opcional)' : 'Contraseña',
                    enabled,
                    // Al editar se puede dejar vacía: entonces la contraseña no cambia
                    _editando
                        ? (v) => (v == null || v.isEmpty) ? null : Validators.contrasena(v)
                        : Validators.contrasena,
                    oculto: _ocultar,
                    sufijo: IconButton(
                      tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                    ),
                  ),
                  _campo(
                    _confirmar,
                    _editando ? 'Confirmar nueva contraseña' : 'Confirmar contraseña',
                    enabled,
                    (v) => (_editando && _contrasena.text.isEmpty)
                        ? null
                        : Validators.confirmacion(v, _contrasena.text),
                    oculto: _ocultar,
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(error, style: ts(14, weight: kSemi, color: AppColors.danger)),
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
              label: _editando ? 'Guardar cambios' : 'Crear usuario',
              busy: c.guardando,
              onPressed: _guardar,
            ),
          ],
        );
      },
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta,
    bool enabled,
    String? Function(String?)? validator, {
    TextInputType? tipo,
    bool oculto = false,
    Widget? sufijo,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: oculto,
          keyboardType: tipo,
          autofillHints: oculto ? const [AutofillHints.newPassword] : null,
          decoration: InputDecoration(labelText: etiqueta, suffixIcon: sufijo),
          validator: validator,
        ),
      );
}
