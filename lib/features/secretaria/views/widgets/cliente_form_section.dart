import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets.dart';
import '../../controllers/clientes_controller.dart';

class ClienteFormSection extends StatefulWidget {
  const ClienteFormSection({super.key});

  @override
  State<ClienteFormSection> createState() => _ClienteFormSectionState();
}

class _ClienteFormSectionState extends State<ClienteFormSection> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _primerApellido = TextEditingController();
  final _segundoApellido = TextEditingController();
  final _correo = TextEditingController();
  final _cedula = TextEditingController();
  final _telefono = TextEditingController();
  final _carne = TextEditingController();
  late final TextEditingController _fechaIngreso;
  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateUtils.dateOnly(DateTime.now());
    _fechaIngreso =
        TextEditingController(text: _fechaLabel(_fechaSeleccionada));
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
    final creado = await controller.crearCliente(
      nombre: _nombre.text,
      primerApellido: _primerApellido.text,
      segundoApellido: _segundoApellido.text,
      correo: _correo.text,
      cedula: _cedula.text,
      telefono: _telefono.text,
      carne: _carne.text,
      fechaIngreso: _fechaSeleccionada,
    );
    if (!creado || !mounted) return;
    for (final field in [
      _nombre,
      _primerApellido,
      _segundoApellido,
      _correo,
      _cedula,
      _telefono,
      _carne,
    ]) {
      field.clear();
    }
    _fechaSeleccionada = DateUtils.dateOnly(DateTime.now());
    _fechaIngreso.text = _fechaLabel(_fechaSeleccionada);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cliente registrado. Puede configurar su contraseña desde “Recuperar contraseña”.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ClientesController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Panel(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                eyebrow: 'Registro de clientes',
                title: 'Agregar cliente nuevo',
              ),
              const SizedBox(height: 8),
              Text(
                'Completa todos los campos para registrar al cliente.',
                style: ts(14, color: AppColors.pizarra),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoChip('Rol: Cliente'),
                  InfoChip('Estado: Activo'),
                ],
              ),
              const SizedBox(height: 20),
              ResponsiveGrid(
                desktopCols: 2,
                spacing: 14,
                children: [
                  _campo(_nombre, 'Nombre', controller,
                      (v) => Validators.requerido(v, 'El nombre')),
                  _campo(
                    _primerApellido,
                    'Primer apellido',
                    controller,
                    (v) => Validators.requerido(v, 'El primer apellido'),
                  ),
                  _campo(
                    _segundoApellido,
                    'Segundo apellido',
                    controller,
                    (v) => Validators.requerido(v, 'El segundo apellido'),
                  ),
                  _campo(
                    _correo,
                    'Correo electrónico',
                    controller,
                    Validators.correo,
                    tipo: TextInputType.emailAddress,
                  ),
                  _campo(
                    _cedula,
                    'Cédula',
                    controller,
                    (v) => Validators.requerido(v, 'La cédula'),
                  ),
                  _campo(
                    _telefono,
                    'Teléfono (8 dígitos)',
                    controller,
                    Validators.telefono,
                    tipo: TextInputType.phone,
                  ),
                  _campo(
                    _carne,
                    'Carné',
                    controller,
                    (v) => Validators.requerido(v, 'El carné'),
                  ),
                  _fechaCampo(controller),
                ],
              ),
              if (controller.errorCrear != null) ...[
                const SizedBox(height: 4),
                Text(
                  controller.errorCrear!,
                  style: ts(14, weight: kSemi, color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Registrar cliente',
                icon: Icons.person_add_alt_1,
                expand: true,
                busy: controller.guardando,
                onPressed:
                    controller.guardando ? null : () => _guardar(controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController textController,
    String etiqueta,
    ClientesController controller,
    String? Function(String?) validator, {
    TextInputType? tipo,
  }) =>
      TextFormField(
        controller: textController,
        enabled: !controller.guardando,
        keyboardType: tipo,
        decoration: InputDecoration(labelText: etiqueta),
        validator: validator,
        onChanged: (_) => controller.limpiarErrorCrear(),
      );

  Widget _fechaCampo(ClientesController controller) => TextFormField(
        controller: _fechaIngreso,
        readOnly: true,
        enabled: !controller.guardando,
        decoration: const InputDecoration(
          labelText: 'Fecha de registro',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        validator: (v) => Validators.requerido(v, 'La fecha de registro'),
        onTap: () => _seleccionarFecha(),
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
