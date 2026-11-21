import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api_exception.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../secretaria/utils/citas_utils.dart';
import '../models/datos_medicion.dart';
import '../models/medicion_cliente.dart';
import '../services/mediciones_service.dart';

const _camposNumericos = <(String, String, String?, double?, bool, bool)>[
  ('peso_corporal', 'Peso corporal', 'kg', null, false, true),
  ('estatura', 'Estatura', 'cm', null, false, true),
  ('grasa_corporal', 'Grasa corporal', '%', 100, false, false),
  ('grasa_visceral', 'Grasa visceral', 'nivel', null, false, false),
  ('masa_muscular', 'Masa muscular', 'kg', null, false, false),
  ('edad', 'Edad', 'años', 120, true, false),
  ('frecuencia_semanal', 'Frecuencia semanal', 'días', 7, true, false),
];

const _camposPerimetros = <(String, String)>[
  ('hombros', 'Hombros'),
  ('pecho', 'Pecho'),
  ('espalda', 'Espalda'),
  ('cintura', 'Cintura'),
  ('cadera', 'Cadera'),
];

const _gruposLados = <(String, String)>[
  ('antebrazo', 'Antebrazo'),
  ('brazo', 'Brazo'),
  ('muslo', 'Muslo'),
  ('pantorrilla', 'Pantorrilla'),
];

class EditarMedicionDialog extends StatefulWidget {
  const EditarMedicionDialog({
    super.key,
    required this.medicion,
    required this.idUsuario,
    required this.service,
  });

  final MedicionCliente medicion;
  final String idUsuario;
  final MedicionesService service;

  static Future<MedicionCliente?> mostrar(
    BuildContext context, {
    required MedicionCliente medicion,
    required String idUsuario,
    required MedicionesService service,
  }) =>
      showDialog<MedicionCliente>(
        context: context,
        builder: (_) => EditarMedicionDialog(
          medicion: medicion,
          idUsuario: idUsuario,
          service: service,
        ),
      );

  @override
  State<EditarMedicionDialog> createState() => _EditarMedicionDialogState();
}

class _EditarMedicionDialogState extends State<EditarMedicionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _campos = <String, TextEditingController>{
    for (final (campo, _, _, _, _, _) in _camposNumericos)
      campo: TextEditingController(),
    for (final (campo, _) in _camposPerimetros) campo: TextEditingController(),
    for (final (grupo, _) in _gruposLados)
      '${grupo}_izq': TextEditingController(),
    for (final (grupo, _) in _gruposLados)
      '${grupo}_der': TextEditingController(),
  };
  late final _objetivo = TextEditingController(
    text: widget.medicion.objetivo ?? '',
  );
  late final _actividad = TextEditingController(
    text: widget.medicion.nivelActividadFisica ?? '',
  );
  late final _observaciones = TextEditingController(
    text: widget.medicion.observaciones ?? '',
  );
  late String _estado = widget.medicion.estado;
  String? _error;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final medicion = widget.medicion;
    final valores = <String, num?>{
      'peso_corporal': medicion.pesoCorporal,
      'estatura': medicion.estatura,
      'grasa_corporal': medicion.grasaCorporal,
      'grasa_visceral': medicion.grasaVisceral,
      'masa_muscular': medicion.masaMuscular,
      'edad': medicion.edad,
      'frecuencia_semanal': medicion.frecuenciaSemanal,
      for (final (campo, _) in _camposPerimetros)
        campo: medicion.medidas[campo] as num?,
      for (final (grupo, _) in _gruposLados)
        '${grupo}_izq': (medicion.medidas[grupo] as Map?)?['izq'] as num?,
      for (final (grupo, _) in _gruposLados)
        '${grupo}_der': (medicion.medidas[grupo] as Map?)?['der'] as num?,
    };
    for (final entry in valores.entries) {
      _campos[entry.key]!.text = entry.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final campo in _campos.values) {
      campo.dispose();
    }
    _objetivo.dispose();
    _actividad.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  double? _valor(String campo) {
    final texto = _campos[campo]!.text.trim().replaceAll(',', '.');
    return texto.isEmpty ? null : double.tryParse(texto);
  }

  int? _entero(String campo) => int.tryParse(_campos[campo]!.text.trim());

  String? _validarNumero(
    String? texto, {
    required String nombre,
    required bool requerido,
    double? maximo,
    required bool entero,
  }) {
    final valorTexto = texto?.trim() ?? '';
    if (valorTexto.isEmpty) return requerido ? '$nombre es obligatorio.' : null;
    final valor = double.tryParse(valorTexto.replaceAll(',', '.'));
    if (valor == null || !valor.isFinite || valor < 0) {
      return '$nombre debe ser un número mayor o igual a 0.';
    }
    if (maximo != null && valor > maximo) {
      return '$nombre no puede ser mayor que ${maximo.toStringAsFixed(0)}.';
    }
    if (entero && valor != valor.roundToDouble()) {
      return '$nombre debe ser un número entero.';
    }
    return null;
  }

  Widget _numero(
    String campo,
    String nombre, {
    String? unidad,
    bool requerido = false,
    double? maximo,
    bool entero = false,
  }) =>
      TextFormField(
        controller: _campos[campo],
        enabled: !_guardando,
        keyboardType: TextInputType.numberWithOptions(decimal: !entero),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(entero ? r'[0-9]' : r'[0-9,.]'),
          ),
        ],
        decoration: InputDecoration(
          labelText: requerido ? '$nombre *' : nombre,
          suffixText: unidad,
        ),
        validator: (valor) => _validarNumero(
          valor,
          nombre: nombre,
          requerido: requerido,
          maximo: maximo,
          entero: entero,
        ),
      );

  Widget _texto(TextEditingController controller, String label,
          {int maxLines = 1}) =>
      TextFormField(
        controller: controller,
        enabled: !_guardando,
        maxLength: 2000,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      );

  Future<void> _guardar() async {
    if (_guardando || !(_formKey.currentState?.validate() ?? false)) return;
    final medicion = widget.medicion;
    final datos = DatosMedicion(
      idUsuario: widget.idUsuario,
      pesoCorporal: _valor('peso_corporal')!,
      estatura: _valor('estatura')!,
      objetivo: _objetivo.text,
      grasaCorporal: _valor('grasa_corporal'),
      grasaVisceral: _valor('grasa_visceral'),
      masaMuscular: _valor('masa_muscular'),
      edad: _entero('edad'),
      nivelActividadFisica: _actividad.text,
      frecuenciaSemanal: _entero('frecuencia_semanal'),
      observaciones: _observaciones.text,
      estado: _estado,
      hombros: _valor('hombros'),
      pecho: _valor('pecho'),
      espalda: _valor('espalda'),
      cintura: _valor('cintura'),
      cadera: _valor('cadera'),
      antebrazoIzq: _valor('antebrazo_izq'),
      antebrazoDer: _valor('antebrazo_der'),
      brazoIzq: _valor('brazo_izq'),
      brazoDer: _valor('brazo_der'),
      musloIzq: _valor('muslo_izq'),
      musloDer: _valor('muslo_der'),
      pantorrillaIzq: _valor('pantorrilla_izq'),
      pantorrillaDer: _valor('pantorrilla_der'),
    );
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final actualizada =
          await widget.service.actualizarMedicion(medicion.id, datos);
      if (mounted) Navigator.of(context).pop(actualizada);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al actualizar medición: $e');
      setState(() => _error = 'No se pudo actualizar la medición.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('EDITAR MEDICIÓN', style: display(24)),
        content: SizedBox(
          width: 560,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Fecha registrada: '
                    '${fechaCitaLabel(widget.medicion.fecha.toLocal())} · '
                    '${horaCitaLabel(widget.medicion.fecha.toLocal())}. '
                    'La fecha no se puede modificar.',
                    style: ts(13, color: AppColors.pizarra),
                  ),
                  const SizedBox(height: 12),
                  _texto(_objetivo, 'Objetivo'),
                  for (final (campo, label, unidad, maximo, entero, requerido)
                      in _camposNumericos) ...[
                    const SizedBox(height: 12),
                    _numero(
                      campo,
                      label,
                      unidad: unidad,
                      maximo: maximo,
                      entero: entero,
                      requerido: requerido,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _texto(_actividad, 'Nivel de actividad física'),
                  const SizedBox(height: 12),
                  Text('Medidas corporales', style: ts(16, weight: kSemi)),
                  for (final (campo, label) in _camposPerimetros) ...[
                    const SizedBox(height: 12),
                    _numero(campo, label, unidad: 'cm'),
                  ],
                  for (final (grupo, label) in _gruposLados) ...[
                    const SizedBox(height: 16),
                    Text(label, style: ts(14, weight: kSemi)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _numero(
                            '${grupo}_izq',
                            'Izquierdo',
                            unidad: 'cm',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _numero(
                            '${grupo}_der',
                            'Derecho',
                            unidad: 'cm',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _texto(_observaciones, 'Observaciones', maxLines: 4),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Activo',
                        child: Text('Activo'),
                      ),
                      DropdownMenuItem(
                        value: 'Inhabilitado',
                        child: Text('Inhabilitado'),
                      ),
                    ],
                    onChanged: _guardando
                        ? null
                        : (value) {
                            if (value != null) setState(() => _estado = value);
                          },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: ts(14, weight: kSemi, color: AppColors.danger),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _guardando ? null : () => Navigator.pop(context),
            child: Text('Cancelar', style: ts(15, weight: kSemi)),
          ),
          PrimaryButton(
            label: 'Guardar cambios',
            icon: Icons.save_outlined,
            busy: _guardando,
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      );
}
