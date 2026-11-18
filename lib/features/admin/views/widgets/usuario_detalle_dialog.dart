import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../../auth/models/usuario.dart';

String _dos(int n) => n.toString().padLeft(2, '0');

String _fecha(DateTime d) {
  final l = d.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)}/${l.year}';
}

String _fechaHora(DateTime d) {
  final l = d.toLocal();
  return '${_fecha(d)} ${_dos(l.hour)}:${_dos(l.minute)}';
}

/// Detalle completo de un usuario administrativo (RF-103 / RF-104 #9), con las
/// acciones de editar (RF-099) e inhabilitar (RF-100). Las acciones cierran este
/// diálogo y llaman a [onEditar] / [onInhabilitar], que abre la pantalla de origen.
class UsuarioDetalleDialog extends StatelessWidget {
  const UsuarioDetalleDialog({
    super.key,
    required this.usuario,
    required this.onEditar,
    required this.onInhabilitar,
    required this.onHabilitar,
  });

  final Usuario usuario;
  final VoidCallback onEditar;
  final VoidCallback onInhabilitar;
  final VoidCallback onHabilitar;

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(u.nombreCompleto.toUpperCase(), style: display(26)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Dato('Identificador', u.id, copiable: true),
            _Dato('Rol', u.rol.valor),
            _Dato('Usuario', u.usuario),
            _Dato('Correo', u.correo),
            _Dato('Teléfono', u.telefono),
            _Dato('Estado', u.estado.valor),
            _Dato('Fecha de ingreso', _fecha(u.fechaIngreso)),
            _Dato('Último acceso', u.ultimoLogin == null ? 'Nunca' : _fechaHora(u.ultimoLogin!)),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
        if (u.estaActivo)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onInhabilitar();
            },
            child: Text('Inhabilitar', style: ts(15, weight: kSemi, color: AppColors.danger)),
          )
        else
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onHabilitar();
            },
            child: Text('Habilitar', style: ts(15, weight: kSemi, color: AppColors.success)),
          ),
        PrimaryButton(
          label: 'Editar',
          icon: Icons.edit_outlined,
          onPressed: () {
            Navigator.of(context).pop();
            onEditar();
          },
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.valor, {this.copiable = false});
  final String label;
  final String valor;
  final bool copiable;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(label),
          const SizedBox(height: 2),
          // El identificador se puede seleccionar y copiar para buscarlo
          copiable ? SelectableText(valor, style: ts(16)) : Text(valor, style: ts(16)),
        ]),
      );
}
