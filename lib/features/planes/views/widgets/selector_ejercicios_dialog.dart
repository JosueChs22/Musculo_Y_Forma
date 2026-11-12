import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/imagen_red.dart';
import '../../../../core/skeleton.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../../ejercicios/controllers/ejercicios_controller.dart';
import '../../../ejercicios/models/ejercicio.dart';
import '../../../ejercicios/services/ejercicios_service.dart';

/// Busca en el catálogo y agrega ejercicios al plan sin cerrarse, para elegir
/// varios seguidos. [yaEsta] dice si el plan ya lo tiene; [onAgregar] lo agrega.
class SelectorEjerciciosDialog extends StatefulWidget {
  const SelectorEjerciciosDialog({super.key, required this.yaEsta, required this.onAgregar});

  final bool Function(String idEjercicio) yaEsta;

  /// Devuelve false si no se pudo agregar (ya estaba o se llegó al máximo).
  final bool Function(Ejercicio) onAgregar;

  @override
  State<SelectorEjerciciosDialog> createState() => _SelectorEjerciciosDialogState();
}

class _SelectorEjerciciosDialogState extends State<SelectorEjerciciosDialog> {
  // Controlador propio: la búsqueda y los filtros de este selector no tocan los de la pantalla del catálogo.
  late final _c = EjerciciosController(context.read<EjerciciosService>())..load();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _agregar(Ejercicio e) {
    final ok = widget.onAgregar(e);
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo agregar: el plan llegó al máximo de ejercicios.')));
    }
    setState(() {}); // refleja el check de "ya está en el plan"
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('AGREGAR EJERCICIOS', style: display(26)),
      content: SizedBox(
        width: 560,
        height: 520,
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              autofocus: true,
              onChanged: _c.buscar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre (mín. ${EjerciciosController.minimoBusqueda} letras)',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            if (_c.textoMuyCorto)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Escribe al menos ${EjerciciosController.minimoBusqueda} letras para buscar.',
                    style: ts(13, color: AppColors.pizarra)),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _Chip('Todos', _c.grupoFiltro == null, () => _c.filtrarGrupo(null)),
                for (final g in gruposMusculares) _Chip(g, _c.grupoFiltro == g, () => _c.filtrarGrupo(g)),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(child: _Lista(controller: _c, yaEsta: widget.yaEsta, onAgregar: _agregar)),
          ]),
        ),
      ),
      actions: [
        PrimaryButton(label: 'Listo', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          backgroundColor: AppColors.fill,
          selectedColor: AppColors.indigo,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          labelStyle: ts(14, weight: kSemi, color: selected ? Colors.white : AppColors.ink),
        ),
      );
}

class _Lista extends StatelessWidget {
  const _Lista({required this.controller, required this.yaEsta, required this.onAgregar});
  final EjerciciosController controller;
  final bool Function(String) yaEsta;
  final void Function(Ejercicio) onAgregar;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.error != null) return ErrorPanel(message: c.error!, onRetry: c.load);
    if (c.loading) {
      return const SkeletonScope(
        child: Column(children: [SkeletonRow(), SizedBox(height: 8), SkeletonRow(), SizedBox(height: 8), SkeletonRow()]),
      );
    }
    if (c.items.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text('No hay ejercicios que coincidan con la búsqueda.', style: ts(15, color: AppColors.pizarra)),
      );
    }

    final extra = (c.hayMas || c.cargandoMas) ? 1 : 0;
    // REGLA 4: lista virtualizada; REGLA 6: las miniaturas solo se piden al mostrarse
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
        final e = c.items[i];
        final agregado = yaEsta(e.id);
        return Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: ImagenRed(e.imagenUrl, size: 52),
            title: Text(e.nombre, overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi)),
            subtitle: Text(e.resumen.isEmpty ? 'Sin datos' : e.resumen,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, color: AppColors.pizarra)),
            trailing: agregado
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : const Icon(Icons.add_circle_outline, color: AppColors.cobalto),
            onTap: agregado ? null : () => onAgregar(e),
          ),
        );
      },
    );
  }
}
