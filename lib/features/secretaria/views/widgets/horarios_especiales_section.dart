import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../controllers/horarios_especiales_controller.dart';
import '../../models/horario_especial.dart';
import 'horario_especial_form_dialog.dart';

/// Sección de horarios especiales del Sprint 2.
/// RF-016, RF-021, RF-026 y RF-031.
class HorariosEspecialesSection extends StatefulWidget {
  const HorariosEspecialesSection({super.key});

  @override
  State<HorariosEspecialesSection> createState() =>
      _HorariosEspecialesSectionState();
}

class _HorariosEspecialesSectionState extends State<HorariosEspecialesSection> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HorariosEspecialesController>().cargar();
      }
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _crear() async {
    final horario = await HorarioEspecialFormDialog.show(context);

    if (horario == null || !mounted) return;

    final controller = context.read<HorariosEspecialesController>();

    final correcto = await controller.crear(horario);

    if (!mounted) return;

    if (correcto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario especial creado correctamente.'),
        ),
      );
    } else {
      _mostrarError(
        controller.error ?? 'No se pudo crear el horario.',
      );
    }
  }

  Future<void> _editar(HorarioEspecial actual) async {
    final horario = await HorarioEspecialFormDialog.show(
      context,
      horario: actual,
    );

    if (horario == null || !mounted) return;

    final controller = context.read<HorariosEspecialesController>();

    final correcto = await controller.actualizar(
      actual.id,
      horario,
    );

    if (!mounted) return;

    if (correcto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario especial actualizado.'),
        ),
      );
    } else {
      _mostrarError(
        controller.error ?? 'No se pudo actualizar el horario.',
      );
    }
  }

  Future<void> _inhabilitar(HorarioEspecial horario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inhabilitar horario'),
        content: Text(
          '¿Deseás inhabilitar el horario especial '
          '"${horario.motivo}" del ${horario.fecha}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Inhabilitar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final controller = context.read<HorariosEspecialesController>();
    final correcto = await controller.inhabilitar(horario.id);

    if (!mounted) return;

    if (correcto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario especial inhabilitado.'),
        ),
      );
    } else {
      _mostrarError(
        controller.error ?? 'No se pudo inhabilitar el horario.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HorariosEspecialesController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horarios especiales',
                  style: display(24),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestioná cierres y cambios excepcionales '
                  'en el horario del gimnasio.',
                  style: ts(14, color: AppColors.pizarra),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: controller.busy ? null : _crear,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo horario'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (controller.cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (controller.error != null && controller.horarios.isEmpty)
          Column(
            children: [
              Text(controller.error!),
              TextButton(
                onPressed: controller.cargar,
                child: const Text('Reintentar'),
              ),
            ],
          )
        else if (controller.horarios.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No hay horarios especiales registrados.'),
          )
        else
          Column(
            children: [
              for (final horario in controller.horarios)
                _HorarioEspecialCard(
                  horario: horario,
                  busy: controller.busy,
                  onEditar: () => _editar(horario),
                  onInhabilitar: () => _inhabilitar(horario),
                ),
            ],
          ),
      ],
    );
  }
}

class _HorarioEspecialCard extends StatelessWidget {
  const _HorarioEspecialCard({
    required this.horario,
    required this.busy,
    required this.onEditar,
    required this.onInhabilitar,
  });

  final HorarioEspecial horario;
  final bool busy;
  final VoidCallback onEditar;
  final VoidCallback onInhabilitar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              horario.motivo,
              style: ts(16, weight: kSemi),
            ),
            const SizedBox(height: 8),
            Text('Fecha: ${horario.fecha}'),
            Text('Horario: ${horario.descripcionHorario}'),
            Text('Estado: ${horario.estado}'),
            if (horario.observaciones != null &&
                horario.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                horario.observaciones!,
                style: ts(13, color: AppColors.pizarra),
              ),
            ],
            if (horario.activo) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : onEditar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onInhabilitar,
                    icon: const Icon(Icons.block),
                    label: const Text('Inhabilitar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
