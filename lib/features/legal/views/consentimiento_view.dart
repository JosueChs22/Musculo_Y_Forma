import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/brand.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/consentimiento_controller.dart';
import '../legal_textos.dart';
import 'widgets/aviso_borrador.dart';
import 'widgets/enlaces_legales.dart';

/// Pantalla bloqueante (/consentimiento): se muestra en el primer ingreso y cada vez que
/// cambia la versión del aviso. El router no deja salir de aquí hasta que se acepte.
/// La autorización de datos de salud es una casilla aparte y opcional (Ley 8968, art. 9).
class ConsentimientoView extends StatefulWidget {
  const ConsentimientoView({super.key});

  @override
  State<ConsentimientoView> createState() => _ConsentimientoViewState();
}

class _ConsentimientoViewState extends State<ConsentimientoView> {
  bool _aceptaTerminos = false;
  bool _datosSalud = false;

  Future<void> _continuar() async {
    // El router sale solo de esta pantalla cuando el controlador deja de pedir aceptación
    await context
        .read<ConsentimientoController>()
        .aceptar(datosSalud: _datosSalud);
  }

  @override
  Widget build(BuildContext context) {
    final enviando =
        context.select<ConsentimientoController, bool>((c) => c.enviando);
    final error =
        context.select<ConsentimientoController, String?>((c) => c.errorAccion);

    return Scaffold(
      backgroundColor: AppColors.niebla,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Panel(
                padding: const EdgeInsets.all(24),
                radius: 28,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandLockup(),
                      const SizedBox(height: 24),
                      Semantics(
                          header: true,
                          child: Text('TU PRIVACIDAD', style: display(30))),
                      const SizedBox(height: 6),
                      Text('Versión $kVersionLegal · $kFechaLegal',
                          style:
                              ts(13, weight: kSemi, color: AppColors.pizarra)),
                      const SizedBox(height: 14),
                      const AvisoBorrador(),
                      const SizedBox(height: 14),
                      Text(
                        'Antes de continuar, lee el Aviso de privacidad y los Términos y condiciones. '
                        'Ahí explicamos qué datos guardamos, para qué y cómo ejercer tus derechos de '
                        'acceso, rectificación, cancelación y oposición.',
                        style: ts(15, height: 1.45),
                      ),
                      const SizedBox(height: 4),
                      const EnlacesLegales(alineacion: WrapAlignment.start),
                      const SizedBox(height: 8),
                      _Casilla(
                        valor: _aceptaTerminos,
                        habilitada: !enviando,
                        alCambiar: (v) => setState(() => _aceptaTerminos = v),
                        titulo:
                            'Acepto el Aviso de privacidad y los Términos y condiciones (obligatorio).',
                      ),
                      const SizedBox(height: 8),
                      _Casilla(
                        valor: _datosSalud,
                        habilitada: !enviando,
                        alCambiar: (v) => setState(() => _datosSalud = v),
                        titulo:
                            'Autorizo de forma expresa el tratamiento de mis datos de salud '
                            '(peso, estatura, grasa corporal y demás mediciones) (opcional).',
                        detalle:
                            'Si no lo autorizas puedes usar la app, pero tu entrenador no podrá registrar '
                            'tus mediciones ni verás tu progreso corporal. Puedes cambiarlo cuando quieras en Perfil.',
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 18, color: AppColors.indigo),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(error,
                                        style: ts(14,
                                            weight: kSemi,
                                            color: AppColors.indigo))),
                              ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Continuar',
                        expand: true,
                        busy: enviando,
                        onPressed:
                            _aceptaTerminos && !enviando ? _continuar : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: enviando
                            ? null
                            : () =>
                                context.read<AuthController>().cerrarSesion(),
                        style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(44)),
                        child: Text('No acepto, cerrar sesión',
                            style: ts(14,
                                weight: kSemi, color: AppColors.pizarra)),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.valor,
    required this.habilitada,
    required this.alCambiar,
    required this.titulo,
    this.detalle,
  });

  final bool valor;
  final bool habilitada;
  final ValueChanged<bool> alCambiar;
  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) => Material(
        color: valor ? AppColors.indigoSoft : AppColors.niebla,
        borderRadius: BorderRadius.circular(kRadiusControl),
        child: CheckboxListTile(
          value: valor,
          onChanged: habilitada ? (v) => alCambiar(v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.cobalto,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusControl)),
          title: Text(titulo, style: ts(15, weight: kSemi)),
          subtitle: detalle == null
              ? null
              : Text(detalle!,
                  style: ts(13, color: AppColors.pizarra, height: 1.4)),
        ),
      );
}
