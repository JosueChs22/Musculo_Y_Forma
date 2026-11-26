import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/skeleton.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../controllers/clientes_controller.dart';
import '../../models/cliente.dart';
import 'cliente_edit_dialog.dart';

class ClientesListSection extends StatelessWidget {
  const ClientesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ClientesController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              eyebrow: 'Clientes registrados',
              title: 'Lista de clientes',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FiltroCliente(
                    label: 'Todos',
                    seleccionado: controller.estadoFiltro == null,
                    habilitado:
                        !controller.cargandoLista && !controller.cargandoMas,
                    onTap: () => controller.filtrarEstado(null),
                  ),
                  _FiltroCliente(
                    label: 'Activos',
                    seleccionado:
                        controller.estadoFiltro == EstadoCliente.activo.valor,
                    habilitado:
                        !controller.cargandoLista && !controller.cargandoMas,
                    onTap: () =>
                        controller.filtrarEstado(EstadoCliente.activo.valor),
                  ),
                  _FiltroCliente(
                    label: 'Inactivos',
                    seleccionado: controller.estadoFiltro ==
                        EstadoCliente.inhabilitado.valor,
                    habilitado:
                        !controller.cargandoLista && !controller.cargandoMas,
                    onTap: () => controller
                        .filtrarEstado(EstadoCliente.inhabilitado.valor),
                  ),
                  SizedBox(
                    width: constraints.maxWidth >= 700
                        ? 320
                        : constraints.maxWidth,
                    child: TextField(
                      onChanged: controller.buscar,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o carné',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (controller.errorLista != null)
              ErrorPanel(
                message: controller.errorLista!,
                onRetry: () => controller.cargarClientes(reiniciar: true),
              )
            else if (controller.cargandoLista && controller.clientes.isEmpty)
              const SkeletonScope(
                child: Column(children: [
                  SkeletonCard(height: 128),
                  SizedBox(height: 12),
                  SkeletonCard(height: 128),
                  SizedBox(height: 12),
                  SkeletonCard(height: 128),
                ]),
              )
            else if (controller.clientes.isEmpty)
              Text(
                controller.busqueda.isEmpty
                    ? 'No hay clientes en esta categoría.'
                    : 'No se encontraron clientes con ese nombre o carné.',
                style: ts(14, color: AppColors.pizarra),
              )
            else ...[
              if (controller.errorAccion != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    controller.errorAccion!,
                    style: ts(14, weight: kSemi, color: AppColors.danger),
                  ),
                ),
              ],
              // Clientes en cuadrícula: hasta 3 por fila en escritorio
              ResponsiveGrid(desktopCols: 3, spacing: 12, children: [
                for (final cliente in controller.clientes)
                  _ClienteCard(cliente: cliente, controller: controller),
              ]),
              if (controller.hayMas) ...[
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Cargar más clientes',
                  icon: Icons.expand_more,
                  busy: controller.cargandoMas,
                  onPressed: controller.cargandoMas
                      ? null
                      : () => controller.cargarClientes(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FiltroCliente extends StatelessWidget {
  const _FiltroCliente({
    required this.label,
    required this.seleccionado,
    required this.habilitado,
    required this.onTap,
  });

  final String label;
  final bool seleccionado;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: seleccionado,
        onSelected: habilitado ? (_) => onTap() : null,
        showCheckmark: false,
        backgroundColor: AppColors.card,
        selectedColor: AppColors.indigo,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: ts(
          14,
          weight: kSemi,
          color: seleccionado ? Colors.white : AppColors.ink,
        ),
      );
}

class _ClienteCard extends StatelessWidget {
  const _ClienteCard({
    required this.cliente,
    required this.controller,
  });

  final Cliente cliente;
  final ClientesController controller;

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(_iniciales(cliente), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombreCompleto,
                        style: ts(16, weight: kSemi),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cliente.correo,
                        style: ts(13, color: AppColors.pizarra),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Carné ${cliente.carne} · Cédula ${cliente.cedula}',
                        style: ts(13, color: AppColors.pizarra),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tel. ${cliente.telefono}',
                        style: ts(13, color: AppColors.pizarra),
                      ),
                      Text(
                        'Registro: ${_fechaLabel(cliente.fechaIngreso)}',
                        style: ts(13, color: AppColors.pizarra),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _EstadoClientePill(estado: cliente.estado),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed:
                      controller.actualizando ? null : () => _editar(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar información'),
                ),
                TextButton.icon(
                  onPressed: controller.actualizando
                      ? null
                      : () => _cambiarEstado(context),
                  icon: Icon(
                    cliente.estado == EstadoCliente.activo
                        ? Icons.block
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    cliente.estado == EstadoCliente.activo
                        ? 'Inactivar'
                        : 'Activar',
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Future<void> _editar(BuildContext context) async {
    controller.limpiarErrorAccion();
    final guardado = await ClienteEditDialog.show(context, cliente);
    if (!guardado || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Información del cliente actualizada.')),
    );
  }

  Future<void> _cambiarEstado(BuildContext context) async {
    final nuevoEstado = cliente.estado == EstadoCliente.activo
        ? EstadoCliente.inhabilitado
        : EstadoCliente.activo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(nuevoEstado == EstadoCliente.activo
            ? 'Activar cliente'
            : 'Inactivar cliente'),
        content: Text(
          nuevoEstado == EstadoCliente.activo
              ? '¿Deseas activar a ${cliente.nombreCompleto}?'
              : '¿Deseas inactivar a ${cliente.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    controller.limpiarErrorAccion();
    final actualizado =
        await controller.cambiarEstadoCliente(cliente, nuevoEstado);
    if (!context.mounted) return;
    final mensaje = actualizado
        ? 'Estado del cliente actualizado.'
        : controller.errorAccion ?? 'No se pudo cambiar el estado del cliente.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }
}

class _EstadoClientePill extends StatelessWidget {
  const _EstadoClientePill({required this.estado});

  final EstadoCliente estado;

  @override
  Widget build(BuildContext context) {
    final activo = estado == EstadoCliente.activo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFE6F4EE) : const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        estado.valor,
        style: ts(
          12,
          weight: kSemi,
          color: activo ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

String _iniciales(Cliente cliente) {
  final a = cliente.nombre.isEmpty ? '' : cliente.nombre[0];
  final b = cliente.primerApellido.isEmpty ? '' : cliente.primerApellido[0];
  return '$a$b'.toUpperCase();
}

String _fechaLabel(DateTime fecha) {
  final local = fecha.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
