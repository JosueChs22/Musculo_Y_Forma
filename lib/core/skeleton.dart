import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

/// REGLA 1: los skeletons reemplazan a los spinners de pantalla completa.
///
/// [SkeletonScope] anima una sola vez la opacidad para todos los bloques
/// que tiene debajo, en lugar de un AnimationController por bloque.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({super.key, required this.child, this.label = 'Cargando'});
  final Widget child;
  final String label;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: .45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.label,
        liveRegion: true,
        child: ExcludeSemantics(
          child: RepaintBoundary(child: FadeTransition(opacity: _c, child: widget.child)),
        ),
      );
}

/// Bloque gris con la forma del contenido final.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 10});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.skeleton,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Tarjeta skeleton genérica: título, dos líneas y una barra.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 150});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBox(width: 140, height: 22),
            SizedBox(height: 12),
            SkeletonBox(width: 200, height: 14),
            SizedBox(height: 8),
            SkeletonBox(width: 120, height: 14),
            Spacer(),
            SkeletonBox(height: 8, radius: 99),
          ]),
        ),
      );
}

/// Fila skeleton para listas (ejercicios, mediciones, clientes).
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key, this.leading = true});
  final bool leading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          if (leading) ...[
            const SkeletonBox(width: 40, height: 40, radius: 12),
            const SizedBox(width: 16),
          ],
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBox(width: 180, height: 16),
              SizedBox(height: 8),
              SkeletonBox(width: 120, height: 12),
            ]),
          ),
        ]),
      );
}

/// Título de página skeleton.
class SkeletonTitle extends StatelessWidget {
  const SkeletonTitle({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 12),
          SizedBox(height: 10),
          SkeletonBox(width: 260, height: 40),
          SizedBox(height: 10),
          SkeletonBox(width: 200, height: 14),
        ],
      );
}
