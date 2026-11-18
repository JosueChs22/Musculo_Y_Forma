import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/reglamento.dart';

String _dos(int n) => n.toString().padLeft(2, '0');

String _fecha(DateTime d) {
  final l = d.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)}/${l.year}';
}

/// Detalle completo de un reglamento (RF-102 #5), con las acciones de editar
/// (RF-098) e inhabilitar (RF-101). Las acciones cierran este diálogo y llaman a
/// [onEditar] / [onInhabilitar], que abre la pantalla de origen.
class ReglamentoDetalleDialog extends StatelessWidget {
  const ReglamentoDetalleDialog({
    super.key,
    required this.reglamento,
    required this.onEditar,
    required this.onInhabilitar,
    required this.onHabilitar,
  });

  final Reglamento reglamento;
  final VoidCallback onEditar;
  final VoidCallback onInhabilitar;
  final VoidCallback onHabilitar;

  @override
  Widget build(BuildContext context) {
    final r = reglamento;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(r.titulo.toUpperCase(), style: display(26)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Estado'),
            const SizedBox(height: 2),
            Text(r.estado.valor,
                style: ts(16, weight: kSemi, color: r.estaActivo ? AppColors.success : AppColors.danger)),
            const SizedBox(height: 12),
            const Eyebrow('Contenido'),
            const SizedBox(height: 2),
            SelectableText(r.contenido, style: ts(16)),
            const SizedBox(height: 12),
            const Eyebrow('Publicado'),
            const SizedBox(height: 2),
            Text(_fecha(r.fechaCreacion), style: ts(16)),
            if (r.fechaActualizacion != null) ...[
              const SizedBox(height: 12),
              const Eyebrow('Última actualización'),
              const SizedBox(height: 2),
              Text(_fecha(r.fechaActualizacion!), style: ts(16)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
        if (r.estaActivo)
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
