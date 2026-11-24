import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';

/// Enlaces a Privacidad y Términos (pie del login, pantalla de consentimiento, Perfil).
/// Se abren con push para volver a la pantalla anterior.
class EnlacesLegales extends StatelessWidget {
  const EnlacesLegales({super.key, this.alineacion = WrapAlignment.center});

  final WrapAlignment alineacion;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: alineacion,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          _Enlace('Aviso de privacidad', () => context.push('/privacidad')),
          // Separador decorativo: no se anuncia al lector de pantalla
          ExcludeSemantics(
              child: Text('·', style: ts(14, color: AppColors.pizarra))),
          _Enlace('Términos y condiciones', () => context.push('/terminos')),
        ],
      );
}

class _Enlace extends StatelessWidget {
  const _Enlace(this.texto, this.alTocar);
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: alTocar,
        style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: AppColors.cobalto),
        child: Text(texto,
            style: ts(14, weight: kSemi, color: AppColors.cobalto).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColors.cobalto)),
      );
}
