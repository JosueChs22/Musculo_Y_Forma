import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/skeleton.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../controllers/buscador_clientes_controller.dart';
import '../../models/plan.dart';
import '../../services/planes_service.dart';

/// Resultado del selector: [cliente] null significa "dejar sin asignar".
class ClienteElegido {
  const ClienteElegido(this.cliente);
  final UsuarioResumen? cliente;
}

/// Busca clientes por nombre y devuelve el elegido (o null si se cierra sin elegir).
class ClientePickerDialog extends StatefulWidget {
  const ClientePickerDialog({super.key, this.actual});

  /// Cliente al que está asignado ahora, si lo hay.
  final UsuarioResumen? actual;

  static Future<ClienteElegido?> mostrar(BuildContext context, {UsuarioResumen? actual}) =>
      showDialog<ClienteElegido>(context: context, builder: (_) => ClientePickerDialog(actual: actual));

  @override
  State<ClientePickerDialog> createState() => _ClientePickerDialogState();
}

class _ClientePickerDialogState extends State<ClientePickerDialog> {
  late final _c = BuscadorClientesController(context.read<PlanesService>())..cargar();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('ASIGNAR A UN USUARIO', style: display(26)),
      content: SizedBox(
        width: 440,
        height: 400,
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              autofocus: true,
              onChanged: _c.buscar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre (mín. ${BuscadorClientesController.minimoBusqueda} letras)',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            if (_c.textoMuyCorto)
              Text('Escribe al menos ${BuscadorClientesController.minimoBusqueda} letras para buscar.',
                  style: ts(13, color: AppColors.pizarra)),
            const SizedBox(height: 4),
            Expanded(child: _Resultados(controller: _c, actual: widget.actual)),
          ]),
        ),
      ),
      actions: [
        if (widget.actual != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const ClienteElegido(null)),
            child: Text('Quitar asignación', style: ts(15, weight: kSemi, color: AppColors.danger)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
      ],
    );
  }
}

class _Resultados extends StatelessWidget {
  const _Resultados({required this.controller, required this.actual});
  final BuscadorClientesController controller;
  final UsuarioResumen? actual;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.error != null) return ErrorPanel(message: c.error!, onRetry: c.cargar);
    if (c.cargando) {
      return const SkeletonScope(
        child: Column(children: [SkeletonRow(), SizedBox(height: 8), SkeletonRow(), SizedBox(height: 8), SkeletonRow()]),
      );
    }
    if (c.items.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            c.hayTexto ? 'No hay usuarios que coincidan con esa búsqueda.' : 'Todavía no hay usuarios registrados.',
            style: ts(15, color: AppColors.pizarra),
          ),
        ),
      );
    }

    final extra = c.hayMas ? 1 : 0;
    // REGLA 4: lista virtualizada
    return ListView.builder(
      itemCount: c.items.length + extra,
      itemBuilder: (context, i) {
        if (i == c.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: c.cargandoMas
                  ? const SkeletonScope(child: SkeletonBox(width: 160, height: 40, radius: 18))
                  : SecondaryButton(label: 'Cargar más', onPressed: c.cargarMas),
            ),
          );
        }
        final u = c.items[i];
        final esActual = u.id == actual?.id;
        return Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Avatar(u.iniciales, size: 40, bg: AppColors.indigoSoft, fg: AppColors.indigo),
            title: Text(u.nombre, overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi)),
            subtitle: Text(u.usuario, style: ts(13, color: AppColors.pizarra)),
            trailing: esActual
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : const Icon(Icons.add_circle_outline, color: AppColors.cobalto),
            onTap: () => Navigator.of(context).pop(ClienteElegido(u)),
          ),
        );
      },
    );
  }
}
