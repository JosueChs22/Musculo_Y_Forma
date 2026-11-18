import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../auth/models/usuario.dart';
import '../controllers/usuarios_controller.dart';
import 'widgets/usuario_detalle_dialog.dart';
import 'widgets/usuario_form_dialog.dart';

/// Panel del Administrador: secretarias y entrenadores. Lista, búsqueda y
/// filtros (RF-103, 104, 105), alta (RF-096), edición (RF-099) e inhabilitación (RF-100).
class UsuariosView extends StatefulWidget {
  const UsuariosView({super.key});

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  @override
  void initState() {
    super.initState();
    // Se recarga cada vez que se abre la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UsuariosController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<UsuariosController>();
    final visibles = c.visibles;

    return SliverPage(slivers: [
      Box(
        Align(alignment: Alignment.centerLeft, child: BackLink(onTap: () => context.go('/'))),
        gapAfter: 8,
      ),
      const Box(
        PageTitle(
          eyebrow: 'Panel del administrador',
          title: 'Usuarios',
          subtitle: 'Secretarias y entrenadores del gimnasio.',
        ),
        gapAfter: 16,
      ),
      Box(
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            PrimaryButton(
              label: 'Nuevo usuario',
              icon: Icons.person_add_alt_1,
              onPressed: () => _nuevoUsuario(context),
            ),
            // Reglamento del gimnasio (RF-097, 098, 101, 102)
            TextButton.icon(
              onPressed: () => context.go('/admin/reglamentos'),
              icon: const Icon(Icons.gavel_outlined, color: AppColors.cobalto),
              label: Text('Reglamento del gimnasio',
                  style: ts(15, weight: kSemi, color: AppColors.cobalto)),
            ),
          ]),
        ),
        gapAfter: 16,
      ),
      Box(
        TextField(
          onChanged: c.buscar,
          decoration: const InputDecoration(
            hintText: 'Buscar por identificador, nombre, apellido, correo o rol',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        gapAfter: 12,
      ),
      Box(
        Wrap(spacing: 8, runSpacing: 8, children: [
          _FiltroChip('Todos', c.rolFiltro == null, () => c.filtrarRol(null)),
          _FiltroChip('Secretaria', c.rolFiltro == RolUsuario.secretaria,
              () => c.filtrarRol(RolUsuario.secretaria)),
          _FiltroChip('Entrenador', c.rolFiltro == RolUsuario.entrenador,
              () => c.filtrarRol(RolUsuario.entrenador)),
        ]),
        gapAfter: 8,
      ),
      Box(
        Wrap(spacing: 8, runSpacing: 8, children: [
          _FiltroChip('Todos los estados', c.estadoFiltro == null, () => c.filtrarEstado(null)),
          _FiltroChip('Activos', c.estadoFiltro == EstadoUsuario.activo,
              () => c.filtrarEstado(EstadoUsuario.activo)),
          _FiltroChip('Inhabilitados', c.estadoFiltro == EstadoUsuario.inhabilitado,
              () => c.filtrarEstado(EstadoUsuario.inhabilitado)),
        ]),
        gapAfter: 16,
      ),
      if (c.error != null)
        Box(ErrorPanel(message: c.error!, onRetry: () => c.load()))
      else if (c.loading)
        Box(SkeletonScope(
          child: Column(children: [
            for (var i = 0; i < 5; i++)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Panel(child: SkeletonRow())),
          ]),
        ))
      else if (visibles.isEmpty)
        Box(Panel(
          child: Text(
            c.hayFiltros
                ? 'No hay usuarios que coincidan con la búsqueda o los filtros.'
                : 'Aún no hay usuarios registrados.',
            style: ts(15, color: AppColors.pizarra),
          ),
        ))
      else
        SliverList.builder(
          itemCount: visibles.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UsuarioTile(visibles[i]),
          ),
        ),
    ]);
  }
}

/// RF-096: abre el formulario para crear una Secretaria o un Entrenador.
void _nuevoUsuario(BuildContext context) {
  final c = context.read<UsuariosController>();
  c.limpiarErrorCrear();
  showDialog<void>(
    context: context,
    barrierDismissible: false, // no se cierra por accidente a mitad de un formulario
    builder: (_) => UsuarioFormDialog(controller: c),
  );
}

/// RF-099: abre el mismo formulario con los datos del usuario.
void _editarUsuario(BuildContext context, Usuario u) {
  final c = context.read<UsuariosController>();
  c.limpiarErrorEditar();
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UsuarioFormDialog(controller: c, usuario: u),
  );
}

/// RF-100: pide confirmación y luego inhabilita. Avisa con un mensaje al terminar.
Future<void> _inhabilitarUsuario(BuildContext context, Usuario u) async {
  final c = context.read<UsuariosController>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('¿INHABILITAR USUARIO?', style: display(26)),
      content: Text(
        '${u.nombreCompleto} ya no podrá iniciar sesión. Su información se conserva '
        'y no se elimina nada.',
        style: ts(15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Inhabilitar', style: ts(15, weight: kSemi, color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (confirmar != true) return;

  final ok = await c.inhabilitarUsuario(u.id);
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? 'Usuario inhabilitado correctamente'
        : (c.errorAccion ?? 'No se pudo inhabilitar el usuario.')),
  ));
}

/// Reactiva a un usuario inhabilitado, con confirmación y mensaje al terminar.
Future<void> _habilitarUsuario(BuildContext context, Usuario u) async {
  final c = context.read<UsuariosController>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('¿HABILITAR USUARIO?', style: display(26)),
      content: Text(
        '${u.nombreCompleto} volverá a poder iniciar sesión con su misma contraseña.',
        style: ts(15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Habilitar', style: ts(15, weight: kSemi, color: AppColors.success)),
        ),
      ],
    ),
  );
  if (confirmar != true) return;

  final ok = await c.habilitarUsuario(u.id);
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? 'Usuario habilitado correctamente'
        : (c.errorAccion ?? 'No se pudo habilitar el usuario.')),
  ));
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: AppColors.card,
        selectedColor: AppColors.indigo,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: ts(14, weight: kSemi, color: selected ? Colors.white : AppColors.ink),
      );
}

class _UsuarioTile extends StatelessWidget {
  const _UsuarioTile(this.u);
  final Usuario u;

  @override
  Widget build(BuildContext context) => SelectableCard(
        selected: false,
        semanticLabel: '${u.nombreCompleto}, ${u.rol.valor}, ${u.estado.valor}',
        onTap: () => _mostrarDetalle(context, u),
        child: Row(children: [
          Avatar(_iniciales(u), size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.nombreCompleto,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, weight: kSemi)),
              Text('${u.usuario} · ${u.correo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(14, color: AppColors.pizarra)),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Pill(u.rol.valor, tone: PillTone.cobalto),
            const SizedBox(height: 6),
            Text(u.estado.valor,
                style: ts(13, weight: kSemi, color: u.estaActivo ? AppColors.success : AppColors.danger)),
          ]),
        ]),
      );
}

String _iniciales(Usuario u) {
  final a = u.nombre.isEmpty ? '' : u.nombre[0];
  final b = u.primerApellido.isEmpty ? '' : u.primerApellido[0];
  return '$a$b'.toUpperCase();
}

/// Detalle completo del usuario. Editar e inhabilitar se abren con el contexto de
/// la pantalla (no el del diálogo, que ya se cerró).
void _mostrarDetalle(BuildContext context, Usuario u) {
  showDialog<void>(
    context: context,
    builder: (_) => UsuarioDetalleDialog(
      usuario: u,
      onEditar: () => _editarUsuario(context, u),
      onInhabilitar: () => _inhabilitarUsuario(context, u),
      onHabilitar: () => _habilitarUsuario(context, u),
    ),
  );
}
