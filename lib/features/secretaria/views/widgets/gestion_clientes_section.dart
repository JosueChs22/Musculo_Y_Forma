import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../controllers/clientes_controller.dart';
import 'cliente_form_section.dart';
import 'clientes_list_section.dart';

class GestionClientesSection extends StatefulWidget {
  const GestionClientesSection({super.key});

  @override
  State<GestionClientesSection> createState() => _GestionClientesSectionState();
}

class _GestionClientesSectionState extends State<GestionClientesSection> {
  _OpcionGestionCliente _opcion = _OpcionGestionCliente.registrar;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            eyebrow: 'Gestión de clientes',
            title: 'Clientes',
          ),
          const SizedBox(height: 16),
          Panel(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<_OpcionGestionCliente>(
              segments: const [
                ButtonSegment(
                  value: _OpcionGestionCliente.registrar,
                  label: Text('Ingresar cliente'),
                  icon: Icon(Icons.person_add_alt_1),
                ),
                ButtonSegment(
                  value: _OpcionGestionCliente.lista,
                  label: Text('Lista de clientes'),
                  icon: Icon(Icons.groups_outlined),
                ),
              ],
              selected: {_opcion},
              showSelectedIcon: false,
              onSelectionChanged: (seleccion) => _seleccionar(context, seleccion.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.indigo,
                selectedForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Visibility(
            visible: _opcion == _OpcionGestionCliente.registrar,
            maintainState: true,
            child: const ClienteFormSection(),
          ),
          Visibility(
            visible: _opcion == _OpcionGestionCliente.lista,
            maintainState: true,
            child: const ClientesListSection(),
          ),
        ],
      );

  void _seleccionar(BuildContext context, _OpcionGestionCliente opcion) {
    setState(() => _opcion = opcion);
    if (opcion == _OpcionGestionCliente.lista) {
      context.read<ClientesController>().cargarClientes(reiniciar: true);
    }
  }
}

enum _OpcionGestionCliente { registrar, lista }
