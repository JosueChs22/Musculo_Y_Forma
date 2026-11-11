import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../auth/models/usuario.dart';
import '../controllers/usuarios_controller.dart';

/// Panel del Administrador: lista de secretarias y entrenadores (RF-103).
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
        gapAfter: 24,
      ),
      Box(
        TextField(
          onChanged: c.buscar,
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre, usuario o correo',
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
          child: Text('No hay usuarios que coincidan.', style: ts(15, color: AppColors.pizarra)),
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
        side: const BorderSide(color: AppColors.line),
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

String _dos(int n) => n.toString().padLeft(2, '0');

String _fecha(DateTime d) {
  final l = d.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)}/${l.year}';
}

String _fechaHora(DateTime d) {
  final l = d.toLocal();
  return '${_fecha(d)} ${_dos(l.hour)}:${_dos(l.minute)}';
}

void _mostrarDetalle(BuildContext context, Usuario u) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(u.nombreCompleto.toUpperCase(), style: display(26)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Dato('Rol', u.rol.valor),
          _Dato('Usuario', u.usuario),
          _Dato('Correo', u.correo),
          _Dato('Teléfono', u.telefono),
          _Dato('Estado', u.estado.valor),
          _Dato('Fecha de ingreso', _fecha(u.fechaIngreso)),
          _Dato('Último acceso', u.ultimoLogin == null ? 'Nunca' : _fechaHora(u.ultimoLogin!)),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Cerrar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
      ],
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(label),
          const SizedBox(height: 2),
          Text(valor, style: ts(16)),
        ]),
      );
}
