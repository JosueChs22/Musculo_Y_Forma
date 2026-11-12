import 'package:flutter/material.dart';

import 'theme.dart';

/// Emblema circular GMYF (Dirección B): círculo índigo, aro ámbar,
/// barra olímpica blanca y monograma en Barlow Condensed.
class GmyfEmblem extends StatelessWidget {
  const GmyfEmblem({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Músculo y Forma',
        image: true,
        child: RepaintBoundary(
          child: CustomPaint(size: Size.square(size), painter: const _EmblemPainter()),
        ),
      );
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Se dibuja en un lienzo de 200 x 200 y se escala.
    final k = size.width / 200;
    canvas.save();
    canvas.scale(k);

    canvas.drawCircle(const Offset(100, 100), 96, Paint()..color = AppColors.indigo);
    canvas.drawCircle(
      const Offset(100, 100),
      84,
      Paint()
        ..color = AppColors.ambar
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final white = Paint()..color = Colors.white;
    canvas.drawLine(
      const Offset(38, 84),
      const Offset(162, 84),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    for (final r in const [
      Rect.fromLTWH(50, 62, 11, 44),
      Rect.fromLTWH(64, 68, 9, 32),
      Rect.fromLTWH(139, 62, 11, 44),
      Rect.fromLTWH(127, 68, 9, 32),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), white);
    }

    final tp = TextPainter(
      text: TextSpan(text: 'GMYF', style: display(42, color: Colors.white, spacing: 2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(100 - tp.width / 2, 116));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) => false;
}

/// Emblema + nombre del gimnasio.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
        const GmyfEmblem(size: 44),
        const SizedBox(width: 12),
        Flexible(
          child: Text('MÚSCULO\nY FORMA', style: display(22, height: .95)),
        ),
      ]);
}
