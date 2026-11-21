import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../../../auth/models/usuario.dart';
import '../../../../core/theme.dart';

enum SeccionEntrenador { planes, ejercicios, citas, mediciones, historial }

class MenuEntrenador extends StatelessWidget {
  const MenuEntrenador({super.key, required this.seccion});

  final SeccionEntrenador seccion;

  static const _opciones =
      <(SeccionEntrenador, String, String, IconData, String)>[
    (
      SeccionEntrenador.planes,
      'Planes',
      '/coach',
      Icons.fitness_center_outlined,
      'planes',
    ),
    (
      SeccionEntrenador.ejercicios,
      'Ejercicios',
      '/coach/ejercicios',
      Icons.sports_gymnastics_outlined,
      'ejercicios',
    ),
    (
      SeccionEntrenador.citas,
      'Citas',
      '/coach/citas',
      Icons.event_note_outlined,
      'citas',
    ),
    (
      SeccionEntrenador.mediciones,
      'Mediciones',
      '/coach/mediciones',
      Icons.straighten_outlined,
      'mediciones',
    ),
    (
      SeccionEntrenador.historial,
      'Historial',
      '/coach/mediciones/historial',
      Icons.history,
      'historial',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rol = context.select<AuthController, RolUsuario?>(
      (controller) => controller.usuario?.rol,
    );
    final opciones = _opciones
        .where(
          (opcion) =>
              (opcion.$1 != SeccionEntrenador.mediciones &&
                  opcion.$1 != SeccionEntrenador.historial) ||
              rol == RolUsuario.entrenador,
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opcion in opciones)
                ChoiceChip(
                  avatar: Icon(
                    opcion.$4,
                    size: 18,
                    color:
                        seccion == opcion.$1 ? Colors.white : AppColors.pizarra,
                  ),
                  label: Text(opcion.$2),
                  selected: seccion == opcion.$1,
                  showCheckmark: false,
                  onSelected: (_) => context.go(opcion.$3),
                  selectedColor: AppColors.indigo,
                  side: BorderSide.none,
                  labelStyle: ts(
                    14,
                    weight: kSemi,
                    color: seccion == opcion.$1 ? Colors.white : AppColors.ink,
                  ),
                ),
            ],
          );
        }
        return SegmentedButton<SeccionEntrenador>(
          segments: [
            for (final opcion in opciones)
              ButtonSegment(
                value: opcion.$1,
                label: Text(opcion.$2),
                icon: Icon(opcion.$4),
              ),
          ],
          selected: {seccion},
          showSelectedIcon: false,
          onSelectionChanged: (seleccion) {
            final opcion =
                opciones.firstWhere((opcion) => opcion.$1 == seleccion.first);
            context.go(opcion.$3);
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.indigo,
            selectedForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
      },
    );
  }
}
