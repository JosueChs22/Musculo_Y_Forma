import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/fechas.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../controllers/consentimiento_controller.dart';
import 'enlaces_legales.dart';

/// Perfil › Privacidad y datos: consentimiento de datos de salud, descargar mis datos
/// (derecho de acceso) y solicitar la eliminación de la cuenta (derecho de supresión).
class PrivacidadPanel extends StatelessWidget {
  const PrivacidadPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final salud =
        context.select<ConsentimientoController, bool>((c) => c.datosSalud);
    final cargando =
        context.select<ConsentimientoController, bool>((c) => c.loading);
    final enviando =
        context.select<ConsentimientoController, bool>((c) => c.enviando);
    final pendiente = context
        .select<ConsentimientoController, bool>((c) => c.supresionPendiente);
    final error =
        context.select<ConsentimientoController, String?>((c) => c.errorAccion);
    final aceptadoEl = context.select<ConsentimientoController, DateTime?>(
        (c) => c.consentimiento?.fecha);

    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Eyebrow('Privacidad y datos'),
        const SizedBox(height: 4),
        if (aceptadoEl != null)
          Text('Aceptaste el aviso de privacidad el ${fechaCorta(aceptadoEl)}.',
              style: ts(13, color: AppColors.pizarra)),
        // Material propio: el Panel tiene fondo y ocultaría el efecto del ListTile
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            value: salud,
            onChanged:
                cargando || enviando ? null : (v) => _cambiarSalud(context, v),
            activeThumbColor: AppColors.cobalto,
            contentPadding: EdgeInsets.zero,
            title: Text('Autorizo el tratamiento de mis datos de salud',
                style: ts(15, weight: kSemi)),
            subtitle: Text(
                'Mediciones corporales y progreso. Puedes retirarlo cuando quieras.',
                style: ts(13, color: AppColors.pizarra)),
          ),
        ),
        if (error != null)
          Semantics(
              liveRegion: true,
              child: Text(error,
                  style: ts(13, weight: kSemi, color: AppColors.indigo))),
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Descargar mis datos',
          icon: Icons.download_outlined,
          onPressed: cargando ? null : () => _descargar(context),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: pendiente
              ? 'Eliminación solicitada'
              : 'Solicitar eliminación de mi cuenta',
          icon: Icons.person_remove_outlined,
          onPressed:
              cargando || pendiente ? null : () => _solicitarSupresion(context),
        ),
        const SizedBox(height: 6),
        const EnlacesLegales(alineacion: WrapAlignment.start),
      ]),
    );
  }

  Future<void> _cambiarSalud(BuildContext context, bool valor) async {
    final c = context.read<ConsentimientoController>();
    if (!valor) {
      final ok = await _confirmar(
        context,
        titulo: '¿Retirar la autorización?',
        texto:
            'Tu entrenador ya no podrá registrar mediciones y dejarás de ver tu progreso corporal. '
            'Las mediciones anteriores se conservan según el aviso de privacidad; si quieres que se '
            'eliminen, solicita la eliminación de tu cuenta o escríbenos.',
        accion: 'Retirar',
      );
      if (!ok) return;
    }
    await c.cambiarDatosSalud(valor);
  }

  Future<void> _descargar(BuildContext context) async {
    final c = context.read<ConsentimientoController>();
    final mensajero = ScaffoldMessenger.of(context);
    String json;
    try {
      json = await c.exportarDatos();
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    if (!context.mounted) return;
    // REGLA: sin dependencias nuevas (regla 23) no se guarda un archivo; se muestra el JSON
    // y se copia al portapapeles para que el usuario lo guarde donde quiera.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tus datos', style: ts(18, weight: kSemi)),
        content: SizedBox(
          width: 560,
          height: 360,
          child:
              SingleChildScrollView(child: SelectableText(json, style: ts(12))),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) Navigator.pop(ctx);
              mensajero.showSnackBar(const SnackBar(
                  content: Text(
                      'Copiado. Pégalo en un archivo .json para guardarlo.')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _solicitarSupresion(BuildContext context) async {
    final c = context.read<ConsentimientoController>();
    final mensajero = ScaffoldMessenger.of(context);
    final ok = await _confirmar(
      context,
      titulo: '¿Solicitar la eliminación de tu cuenta?',
      texto:
          'La administración revisará tu solicitud y eliminará o anonimizará tus datos, salvo los '
          'que la ley obligue a conservar (por ejemplo, registros de pagos). Mientras tanto tu cuenta '
          'sigue activa. Te contactaremos por correo.',
      accion: 'Enviar solicitud',
    );
    if (!ok) return;
    try {
      mensajero
          .showSnackBar(SnackBar(content: Text(await c.solicitarSupresion())));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

Future<bool> _confirmar(BuildContext context,
    {required String titulo,
    required String texto,
    required String accion}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo, style: ts(18, weight: kSemi)),
      content: Text(texto, style: ts(15, height: 1.45)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(accion)),
      ],
    ),
  );
  return r ?? false;
}
