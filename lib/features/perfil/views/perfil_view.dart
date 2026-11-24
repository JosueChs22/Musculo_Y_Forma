import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/fechas.dart';
import '../../../core/permisos.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/usuario.dart';
import '../../auth/views/widgets/cambiar_contrasena_dialog.dart';
import '../../legal/controllers/consentimiento_controller.dart';
import '../../legal/views/widgets/privacidad_panel.dart';
import '../controllers/perfil_controller.dart';
import '../models/user_profile.dart';

/// Perfil del usuario con sesión: sus datos de cuenta, su coach y su objetivo.
class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.select<AuthController, Usuario?>((c) => c.usuario);
    if (usuario == null) return const SizedBox.shrink(); // el router ya lo manda al login

    return SliverPage(slivers: [
      const Box(PageTitle(eyebrow: 'Tu cuenta', title: 'Perfil'), gapAfter: 24),
      // Escritorio: datos a la izquierda y acciones en un panel lateral. Móvil: apilado.
      Box(Columnas(
        flexIzquierda: 2,
        flexDerecha: 1,
        izquierda: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Cuenta(usuario),
          const SizedBox(height: 16),
          _Entrenamiento(esCliente: usuario.rol == RolUsuario.cliente),
        ]),
        derecha: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Acciones(usuario.rol),
          const SizedBox(height: 16),
          // Ley 8968: consentimiento de datos de salud y derechos ARCO
          const PrivacidadPanel(),
        ]),
      )),
    ]);
  }
}

/// Paneles de trabajo del rol, cambiar contraseña y cerrar sesión.
class _Acciones extends StatelessWidget {
  const _Acciones(this.rol);
  final RolUsuario rol;

  @override
  Widget build(BuildContext context) {
    final paneles = panelesDe(rol);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (paneles.isNotEmpty) ...[
          const Eyebrow('Paneles de trabajo'),
          const SizedBox(height: 10),
          for (final panel in paneles) ...[
            SecondaryButton(label: panel.titulo, icon: panel.icono, onPressed: () => context.go(panel.ruta)),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
        const Eyebrow('Seguridad'),
        const SizedBox(height: 10),
        // RF-035: cambiar la contraseña de la cuenta con sesión iniciada
        SecondaryButton(
          label: 'Cambiar contraseña',
          icon: Icons.lock_outline,
          onPressed: () {
            final auth = context.read<AuthController>();
            auth.limpiarErrorCambio();
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => CambiarContrasenaDialog(controller: auth),
            );
          },
        ),
        const SizedBox(height: 6),
        // Cerrar sesión: al limpiar la sesión, el router redirige solo a /login.
        OutlinedButton.icon(
          onPressed: () => context.read<AuthController>().cerrarSesion(),
          icon: const Icon(Icons.logout),
          label: Text('Cerrar sesión', style: ts(15, weight: kSemi)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.pizarra,
            minimumSize: const Size.fromHeight(50),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ]),
    );
  }
}

/// Datos de la cuenta: vienen de la sesión, así que se ven al instante.
class _Cuenta extends StatelessWidget {
  const _Cuenta(this.u);
  final Usuario u;

  String get _iniciales =>
      [u.nombre, u.primerApellido].where((s) => s.isNotEmpty).map((s) => s[0]).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(_iniciales, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.nombreCompleto.toUpperCase(), style: display(30)),
              const SizedBox(height: 6),
              Pill(u.rol.valor, tone: PillTone.cobalto),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 32, runSpacing: 14, children: [
          // Para los clientes el nombre de usuario es su carné
          _Dato(u.rol == RolUsuario.cliente ? 'Carné' : 'Usuario', u.usuario),
          _Dato('Correo', u.correo),
          _Dato('Teléfono', u.telefono),
          _Dato('Estado de la cuenta', u.estado.valor),
        ]),
      ]),
    );
  }
}

/// Coach y objetivo: vienen de la API (GET /mi/perfil).
class _Entrenamiento extends StatelessWidget {
  const _Entrenamiento({required this.esCliente});
  final bool esCliente;

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PerfilController, bool>((c) => c.loading);
    final error = context.select<PerfilController, String?>((c) => c.error);
    final p = context.select<PerfilController, UserProfile>((c) => c.profile);
    final salud = context.select<ConsentimientoController, bool>((c) => c.datosSalud);

    if (error != null) return ErrorPanel(message: error, onRetry: () => context.read<PerfilController>().load());
    if (loading) return const SkeletonScope(child: SkeletonBox(height: 96, radius: 18));

    return Panel(
      child: Wrap(spacing: 32, runSpacing: 14, children: [
        _Dato('Entrenador asignado', p.coachName ?? 'Sin entrenador asignado'),
        // Sin consentimiento de salud no se muestra nada que venga de sus mediciones
        if (salud) ...[
          _Dato('Objetivo actual', p.goal ?? 'Sin definir'),
          _Dato('Última medición', p.lastMeasurementLabel?.replaceFirst('Última medición · ', '') ?? 'Sin mediciones'),
        ],
        if (esCliente) _Dato('Fecha de pago', p.fechaPago == null ? 'Sin registrar' : fechaCorta(p.fechaPago!)),
      ]),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Eyebrow(label),
        const SizedBox(height: 2),
        Text(valor, style: ts(16, weight: kSemi)),
      ]);
}
