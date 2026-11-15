import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets.dart';
import '../../controllers/clientes_controller.dart';
import '../../models/cliente.dart';

class ClienteEditDialog extends StatefulWidget {
  const ClienteEditDialog({super.key, required this.cliente});

  final Cliente cliente;

  static Future<bool> show(BuildContext context, Cliente cliente) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ClienteEditDialog(cliente: cliente),
      ) ??
      false;

  @override
  State<ClienteEditDialog> createState() => _ClienteEditDialogState();
}

class _ClienteEditDialogState extends State<ClienteEditDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _primerApellido;
  late final TextEditingController _segundoApellido;
  late final TextEditingController _correo;
  late final TextEditingController _cedula;
  late final TextEditingController _telefono;
  late final TextEditingController _carne;
  late final TextEditingController _fechaIngreso;
  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    final cliente = widget.cliente;
    _nombre = TextEditingController(text: cliente.nombre);
    _primerApellido = TextEditingController(text: cliente.primerApellido);
    _segundoApellido = TextEditingController(text: cliente.segundoApellido);
    _correo = TextEditingController(text: cliente.correo);
    _cedula = TextEditingController(text: cliente.cedula);
    _telefono = TextEditingController(text: cliente.telefono);
    _carne = TextEditingController(text: cliente.carne);
    _fechaSeleccionada = DateUtils.dateOnly(cliente.fechaIngreso.toLocal());
    _fechaIngreso = TextEditingController(text: _fechaLabel(_fechaSeleccionada));
  }

  @override
  void dispose() {
    for (final controller in [
      _nombre,
      _primerApellido,
      _segundoApellido,
      _correo,
      _cedula,
      _telefono,
      _carne,
      _fechaIngreso,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar(ClientesController controller) async {
    if (!_form.currentState!.validate()) return;
    final actualizado = await controller.actualizarCliente(
      original: widget.cliente,
      nombre: _nombre.text,
      primerApellido: _primerApellido.text,
      segundoApellido: _segundoApellido.text,
      correo: _correo.text,
      cedula: _cedula.text,
      telefono: _telefono.text,
      carne: _carne.text,
      fechaIngreso: _fechaSeleccionada,
    );
    if (!actualizado || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ClientesController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final enabled = !controller.actualizando;
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('EDITAR CLIENTE', style: display(26)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _campo(
                      _nombre,
                      'Nombre',
                      enabled,
                      (v) => Validators.requerido(v, 'El nombre'),
                      controller,
                    ),
                    _campo(
                      _primerApellido,
                      'Primer apellido',
                      enabled,
                      (v) => Validators.requerido(v, 'El primer apellido'),
                      controller,
                    ),
                    _campo(
                      _segundoApellido,
                      'Segundo apellido',
                      enabled,
                      (v) => Validators.requerido(v, 'El segundo apellido'),
                      controller,
                    ),
                    _campo(
                      _correo,
                      'Correo electrónico',
                      enabled,
                      Validators.correo,
                      controller,
                      tipo: TextInputType.emailAddress,
                    ),
                    _campo(
                      _cedula,
                      'Cédula',
                      enabled,
                      (v) => Validators.requerido(v, 'La cédula'),
                      controller,
                    ),
                    _campo(
                      _telefono,
                      'Teléfono (8 dígitos)',
                      enabled,
                      Validators.telefono,
                      controller,
                      tipo: TextInputType.phone,
                    ),
                    _campo(
                      _carne,
                      'Carné',
                      enabled,
                      (v) => Validators.requerido(v, 'El carné'),
                      controller,
                    ),
                    _fechaCampo(enabled),
                    if (controller.errorAccion != null)
                      Text(
                        controller.errorAccion!,
                        style: ts(14, weight: kSemi, color: AppColors.danger),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: enabled ? () => Navigator.of(context).pop(false) : null,
              child: Text(
                'Cancelar',
                style: ts(14, weight: kSemi, color: AppColors.pizarra),
              ),
            ),
            PrimaryButton(
              label: 'Guardar cambios',
              busy: controller.actualizando,
              onPressed: enabled ? () => _guardar(controller) : null,
            ),
          ],
        );
      },
    );
  }

  Widget _campo(
    TextEditingController textController,
    String etiqueta,
    bool enabled,
    String? Function(String?) validator,
    ClientesController controller, {
    TextInputType? tipo,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: textController,
          enabled: enabled,
          keyboardType: tipo,
          decoration: InputDecoration(labelText: etiqueta),
          validator: validator,
          onChanged: (_) => controller.limpiarErrorAccion(),
        ),
      );

  Widget _fechaCampo(bool enabled) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _fechaIngreso,
          enabled: enabled,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Fecha de registro',
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          validator: (v) => Validators.requerido(v, 'La fecha de registro'),
          onTap: _seleccionarFecha,
        ),
      );

  Future<void> _seleccionarFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada.isAfter(hoy) ? hoy : _fechaSeleccionada,
      firstDate: DateTime(1900),
      lastDate: hoy,
    );
    if (fecha == null || !mounted) return;
    setState(() {
      _fechaSeleccionada = DateUtils.dateOnly(fecha);
      _fechaIngreso.text = _fechaLabel(_fechaSeleccionada);
    });
  }
}

String _fechaLabel(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
