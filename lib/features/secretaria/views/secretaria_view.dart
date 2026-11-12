import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/clases_controller.dart';
import '../models/clase.dart';
import '../models/horario_clase.dart';
import 'widgets/clase_form_dialog.dart';
import 'widgets/horario_form_dialog.dart';

/// Panel de la Secretaria: gestión de Clases y Horarios (RF-013/018/023/028 y RF-015/020/025/030).
class SecretariaView extends StatelessWidget {
  const SecretariaView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPage(
      slivers: [
        const Box(_Header(), gapAfter: 28),

        // SPRINT 3 - Acceso a gestión de anuncios
        Box(
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/anuncios'),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Gestión de anuncios'),
            ),
          ),
          gapAfter: 28,
        ),

        const Box(_ClasesSection()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => const PageTitle(
        eyebrow: 'Panel de Secretaria',
        title: 'Clases y Horarios',
        subtitle: 'Gestión de clases activas e inhabilitadas.',
      );
}

// ── Sección de Clases ──────────────────────────────────────────────────────

class _ClasesSection extends StatelessWidget {
  const _ClasesSection();

  @override
  Widget build(BuildContext context) {
    final loading = context.select<ClasesController, bool>((c) => c.loading);
    final error = context.select<ClasesController, String?>((c) => c.error);
    final clases =
        context.select<ClasesController, List<Clase>>((c) => c.clases);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
              child:
                  SectionHeader(eyebrow: 'Catálogo activo', title: 'Clases')),
          const SizedBox(width: 16),
          PrimaryButton(
            label: 'Nueva clase',
            icon: Icons.add,
            onPressed: () => _crearClase(context),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (error != null)
        ErrorPanel(
          message: error,
          onRetry: () => context.read<ClasesController>().load(),
        )
      else if (loading)
        const SkeletonScope(
          child: Column(children: [
            SkeletonCard(height: 120),
            SizedBox(height: 12),
            SkeletonCard(height: 120),
            SizedBox(height: 12),
            SkeletonCard(height: 120),
          ]),
        )
      else if (clases.isEmpty)
        _EmptyState(
          mensaje: 'No hay clases registradas.',
          onAction: () => _crearClase(context),
          labelAction: 'Crear primera clase',
        )
      else
        // REGLA 4: lista que puede crecer → ListView.builder.
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: clases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ClaseCard(clase: clases[i]),
        ),
    ]);
  }

  Future<void> _crearClase(BuildContext context) async {
    final result = await ClaseFormDialog.show(context);
    if (result == null || !context.mounted) return;
    final ctrl = context.read<ClasesController>();
    await ctrl.crearClase(
        nombre: result.nombre, descripcion: result.descripcion);
    if (!context.mounted) return;
    _mostrarSnackError(context);
  }
}

// ── Tarjeta de Clase ───────────────────────────────────────────────────────

class _ClaseCard extends StatelessWidget {
  const _ClaseCard({required this.clase});
  final Clase clase;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la clase
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            decoration: BoxDecoration(
              color: clase.activa ? AppColors.indigo : AppColors.niebla,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clase.nombre.toUpperCase(),
                        style: display(24,
                            color: clase.activa
                                ? Colors.white
                                : AppColors.pizarra),
                      ),
                      if (clase.descripcion != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          clase.descripcion!,
                          style: ts(14,
                              color: clase.activa
                                  ? AppColors.onIndigoMuted
                                  : AppColors.pizarra),
                        ),
                      ],
                    ]),
              ),
              if (!clase.activa)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Inhabilitada',
                      style: ts(12, weight: kSemi, color: AppColors.danger)),
                ),
              _ClaseMenu(clase: clase),
            ]),
          ),

          // Horarios de la clase
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Horarios de atención',
                        style: ts(13, weight: kSemi, color: AppColors.pizarra)),
                    if (clase.activa)
                      TextButton.icon(
                        onPressed: () => _agregarHorario(context, clase),
                        icon: const Icon(Icons.add, size: 15),
                        label: Text('Agregar horario',
                            style: ts(13,
                                weight: kSemi, color: AppColors.cobalto)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (clase.horarios.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin horarios registrados.',
                        style: ts(13, color: AppColors.pizarra)),
                  )
                else
                  // REGLA 4: conjunto acotado (horarios de una clase).
                  Column(
                    children: [
                      for (int i = 0; i < clase.horarios.length; i++)
                        _HorarioRow(
                          horario: clase.horarios[i],
                          onEditar: clase.activa
                              ? () => _editarHorario(context, clase, i)
                              : null,
                          onInhabilitar:
                              (clase.activa && clase.horarios[i].activo)
                                  ? () => _inhabilitarHorario(context, clase, i)
                                  : null,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarHorario(BuildContext context, Clase clase) async {
    final horario = await HorarioFormDialog.show(context);
    if (horario == null || !context.mounted) return;
    final ctrl = context.read<ClasesController>();
    await ctrl.agregarHorario(clase.id, horario);
    if (!context.mounted) return;
    _mostrarSnackError(context);
  }

  Future<void> _editarHorario(
      BuildContext context, Clase clase, int index) async {
    final horario =
        await HorarioFormDialog.show(context, horario: clase.horarios[index]);
    if (horario == null || !context.mounted) return;
    final ctrl = context.read<ClasesController>();
    await ctrl.actualizarHorario(clase.id, index, horario);
    if (!context.mounted) return;
    _mostrarSnackError(context);
  }

  Future<void> _inhabilitarHorario(
      BuildContext context, Clase clase, int index) async {
    final confirmar = await _confirmarDialog(
      context,
      titulo: 'Inhabilitar horario',
      mensaje:
          '¿Inhabilitar el horario ${clase.horarios[index].diasLabel} ${clase.horarios[index].rangoHora}?',
    );
    if (!confirmar || !context.mounted) return;
    final ctrl = context.read<ClasesController>();
    await ctrl.inhabilitarHorario(clase.id, index);
    if (!context.mounted) return;
    _mostrarSnackError(context);
  }
}

// ── Menú de opciones de Clase ──────────────────────────────────────────────

class _ClaseMenu extends StatelessWidget {
  const _ClaseMenu({required this.clase});
  final Clase clase;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) => _onSelected(context, v),
      itemBuilder: (_) => [
        if (clase.activa) ...[
          PopupMenuItem(
            value: 'editar',
            child: Row(children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text('Editar clase', style: ts(14)),
            ]),
          ),
          PopupMenuItem(
            value: 'inhabilitar',
            child: Row(children: [
              const Icon(Icons.block, size: 18, color: AppColors.danger),
              const SizedBox(width: 10),
              Text('Inhabilitar', style: ts(14, color: AppColors.danger)),
            ]),
          ),
        ] else
          PopupMenuItem(
            value: 'reactivar',
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  size: 18, color: AppColors.success),
              const SizedBox(width: 10),
              Text('Reactivar', style: ts(14, color: AppColors.success)),
            ]),
          ),
      ],
    );
  }

  Future<void> _onSelected(BuildContext context, String accion) async {
    if (accion == 'editar') {
      final result = await ClaseFormDialog.show(context, clase: clase);
      if (result == null || !context.mounted) return;
      final ctrl = context.read<ClasesController>();
      await ctrl.actualizarClase(clase.id,
          nombre: result.nombre, descripcion: result.descripcion);
      if (!context.mounted) return;
      _mostrarSnackError(context);
    } else if (accion == 'inhabilitar') {
      final confirmar = await _confirmarDialog(
        context,
        titulo: 'Inhabilitar clase',
        mensaje:
            '¿Inhabilitar la clase "${clase.nombre}"? Todos sus horarios quedarán inactivos.',
      );
      if (!confirmar || !context.mounted) return;
      final ctrl = context.read<ClasesController>();
      await ctrl.inhabilitarClase(clase.id);
      if (!context.mounted) return;
      _mostrarSnackError(context);
    } else if (accion == 'reactivar') {
      final confirmar = await _confirmarDialog(
        context,
        titulo: 'Reactivar clase',
        mensaje: '¿Reactivar la clase "${clase.nombre}"?',
      );
      if (!confirmar || !context.mounted) return;
      final ctrl = context.read<ClasesController>();
      await ctrl.reactivarClase(clase.id);
      if (!context.mounted) return;
      _mostrarSnackError(context);
    }
  }
}

// ── Fila de Horario ────────────────────────────────────────────────────────

class _HorarioRow extends StatelessWidget {
  const _HorarioRow({
    required this.horario,
    this.onEditar,
    this.onInhabilitar,
  });
  final HorarioClase horario;
  final VoidCallback? onEditar;
  final VoidCallback? onInhabilitar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: horario.activo ? AppColors.niebla : AppColors.track,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(horario.diasLabel,
                  style: ts(14,
                      weight: kSemi,
                      color:
                          horario.activo ? AppColors.ink : AppColors.pizarra)),
              Text(horario.rangoHora,
                  style: ts(13,
                      color: horario.activo
                          ? AppColors.pizarra
                          : AppColors.pizarra)),
            ]),
          ),
          _EstadoPill(activo: horario.activo, small: true),
          if (onEditar != null || onInhabilitar != null) ...[
            const SizedBox(width: 4),
            if (onEditar != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: AppColors.cobalto,
                tooltip: 'Editar horario',
                onPressed: onEditar,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            if (onInhabilitar != null)
              IconButton(
                icon: const Icon(Icons.block, size: 16),
                color: AppColors.danger,
                tooltip: 'Inhabilitar horario',
                onPressed: onInhabilitar,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
          ],
        ]),
      ),
    );
  }
}

// ── Helpers visuales ───────────────────────────────────────────────────────

class _EstadoPill extends StatelessWidget {
  const _EstadoPill({required this.activo, this.small = false});
  final bool activo;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10,
          vertical: small ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFE6F4EE) : const Color(0xFFFBE9E7),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          activo ? 'Activo' : 'Inhabilitado',
          style: ts(small ? 11 : 12,
              weight: kSemi,
              color: activo ? AppColors.success : AppColors.danger),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.mensaje,
      required this.onAction,
      required this.labelAction});
  final String mensaje;
  final VoidCallback onAction;
  final String labelAction;

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(children: [
          const Icon(Icons.event_note_outlined,
              size: 48, color: AppColors.pizarra),
          const SizedBox(height: 12),
          Text(mensaje, style: ts(15, color: AppColors.pizarra)),
          const SizedBox(height: 16),
          PrimaryButton(label: labelAction, onPressed: onAction),
        ]),
      );
}

// ── Utilidades ─────────────────────────────────────────────────────────────

Future<bool> _confirmarDialog(
  BuildContext context, {
  required String titulo,
  required String mensaje,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(titulo, style: display(22)),
      content: Text(mensaje, style: ts(15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancelar',
              style: ts(14, weight: kSemi, color: AppColors.pizarra)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Confirmar',
              style: ts(14, weight: kSemi, color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

void _mostrarSnackError(BuildContext context) {
  final err = context.read<ClasesController>().lastActionError;
  if (err != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}
