import 'package:flutter/material.dart';

import 'theme.dart';

/// Imagen de la red con recuadro del tamaño final mientras carga (el diseño no
/// salta, REGLA 6) y un ícono si no se pudo cargar. Se decodifica al tamaño
/// mostrado para no gastar memoria con imágenes más grandes que su recuadro.
class ImagenRed extends StatelessWidget {
  const ImagenRed(this.url, {super.key, this.size = 56, this.radius = 12});

  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.niebla,
      child: Icon(Icons.fitness_center, size: size * .4, color: AppColors.pizarra),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
                errorBuilder: (context, error, stack) => placeholder,
              ),
      ),
    );
  }
}
