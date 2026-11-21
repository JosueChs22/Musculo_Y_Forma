import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api_exception.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../planes/models/plan.dart';
import '../../planes/views/widgets/cliente_picker_dialog.dart';
import '../../planes/views/widgets/menu_entrenador.dart';
import '../models/datos_medicion.dart';
import '../services/mediciones_service.dart';

const _camposNumericos = [
  'peso_corporal',
  'grasa_corporal',
  'grasa_visceral',
  'masa_muscular',
  'edad',
  'estatura',
  'frecuencia_semanal',
  'hombros',
  'pecho',
  'espalda',
  'cintura',
  'cadera',
  'antebrazo_izq',
  'antebrazo_der',
  'brazo_izq',
  'brazo_der',
  'muslo_izq',
  'muslo_der',
  'pantorrilla_izq',
  'pantorrilla_der',
];

class MedicionesEntrenadorView extends StatefulWidget {
  const MedicionesEntrenadorView({super.key});

  @override
  State<MedicionesEntrenadorView> createState() =>
      _MedicionesEntrenadorViewState();
}

class _MedicionesEntrenadorViewState extends State<MedicionesEntrenadorView> {
  final _formKey = GlobalKey<FormState>();
  final _objetivo = TextEditingController();
  final _actividad = TextEditingController();
  final _observaciones = TextEditingController();
  final _imc = TextEditingController();
  final _campos = {
    for (final campo in _camposNumericos) campo: TextEditingController(),
  };

  UsuarioResumen? _cliente;
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _objetivo.dispose();
    _actividad.dispose();
    _observaciones.dispose();
    _imc.dispose();
    for (final campo in _campos.values) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _seleccionarCliente() async {
    final elegido = await ClientePickerDialog.mostrar(
      context,
      titulo: 'SELECCIONAR CLIENTE',
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _cliente = elegido.cliente;
      _error = null;
    });
  }

  double? _valor(String campo) {
    final texto = _campos[campo]!.text.trim().replaceAll(',', '.');
    return texto.isEmpty ? null : double.tryParse(texto);
  }

  int? _entero(String campo) => int.tryParse(_campos[campo]!.text.trim());

  double? get _imcCalculado {
    final peso = _valor('peso_corporal');
    final estatura = _valor('estatura');
    if (peso == null || estatura == null || estatura <= 0) return null;
    final metros = estatura / 100;
    return peso / (metros * metros);
  }

  void _actualizarImc(String _) {
    final valor = _imcCalculado;
    _imc.text = valor == null ? '' : valor.toStringAsFixed(1);
    setState(() {});
  }

  String? _validarNumero(
    String? texto, {
    required String nombre,
    bool requerido = false,
    double? maximo,
    bool entero = false,
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
    ValueChanged<String>? onChanged,
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
        onChanged: onChanged,
      );

  Widget _texto(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        enabled: !_guardando,
        maxLength: 2000,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      );

  Widget _seccion(String titulo, IconData icono, List<Widget> contenido,
          {bool inicialAbierta = false}) =>
      Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: AppColors.niebla,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ExpansionTile(
          initiallyExpanded: inicialAbierta,
          leading: Icon(icono, color: AppColors.cobalto),
          title: Text(titulo, style: ts(15, weight: kSemi)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: contenido,
        ),
      );

  Widget _campoLados(String grupo, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
      );

  Future<void> _guardar() async {
    if (_guardando) return;
    final cliente = _cliente;
    if (cliente == null) {
      setState(() => _error = 'Selecciona un cliente activo.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mediciones = context.read<MedicionesService>();
    final datos = DatosMedicion(
      idUsuario: cliente.id,
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
      await mediciones.crearMedicion(datos);
      if (!mounted) return;
      for (final campo in _campos.values) {
        campo.clear();
      }
      _imc.clear();
      _objetivo.clear();
      _actividad.clear();
      _observaciones.clear();
      _formKey.currentState?.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medición registrada correctamente.')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al guardar la medición del cliente: $e');
      setState(() => _error = 'No se pudo registrar la medición.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SliverPage(
        slivers: [
          const Box(
            PageTitle(
              eyebrow: 'Panel del entrenador',
              title: 'Mediciones',
              subtitle: 'Registra la evaluación física de un cliente.',
            ),
            gapAfter: 16,
          ),
          const Box(
            MenuEntrenador(seccion: SeccionEntrenador.mediciones),
            gapAfter: 16,
          ),
          Box(
            Panel(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      eyebrow: 'Nueva evaluación',
                      title: 'Datos de medición',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _guardando ? null : _seleccionarCliente,
                      icon: const Icon(Icons.person_search_outlined),
                      label: Text(
                        _cliente == null
                            ? 'Seleccionar cliente'
                            : 'Cambiar cliente',
                      ),
                    ),
                    if (_cliente != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_cliente!.nombre} · Carné ${_cliente!.usuario}',
                        style: ts(14, weight: kSemi),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _seccion(
                      'Datos generales',
                      Icons.person_outline,
                      [
                        _texto(_objetivo, 'Objetivo'),
                        const SizedBox(height: 12),
                        _numero(
                          'peso_corporal',
                          'Peso corporal',
                          unidad: 'kg',
                          requerido: true,
                          onChanged: _actualizarImc,
                        ),
                        const SizedBox(height: 12),
                        _numero(
                          'estatura',
                          'Estatura',
                          unidad: 'cm',
                          requerido: true,
                          onChanged: _actualizarImc,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _imc,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'IMC calculado',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _numero(
                          'edad',
                          'Edad',
                          unidad: 'años',
                          maximo: 120,
                          entero: true,
                        ),
                        const SizedBox(height: 12),
                        _texto(_actividad, 'Nivel de actividad física'),
                        const SizedBox(height: 12),
                        _numero(
                          'frecuencia_semanal',
                          'Frecuencia semanal',
                          unidad: 'días',
                          maximo: 7,
                          entero: true,
                        ),
                      ],
                      inicialAbierta: true,
                    ),
                    _seccion(
                      'Composición corporal',
                      Icons.monitor_weight_outlined,
                      [
                        _numero(
                          'grasa_corporal',
                          'Grasa corporal',
                          unidad: '%',
                          maximo: 100,
                        ),
                        const SizedBox(height: 12),
                        _numero(
                          'grasa_visceral',
                          'Grasa visceral',
                          unidad: 'nivel',
                        ),
                        const SizedBox(height: 12),
                        _numero(
                          'masa_muscular',
                          'Masa muscular',
                          unidad: 'kg',
                        ),
                      ],
                    ),
                    _seccion(
                      'Medidas corporales',
                      Icons.straighten_outlined,
                      [
                        _numero('hombros', 'Hombros', unidad: 'cm'),
                        const SizedBox(height: 12),
                        _numero('pecho', 'Pecho', unidad: 'cm'),
                        const SizedBox(height: 12),
                        _numero('espalda', 'Espalda', unidad: 'cm'),
                        const SizedBox(height: 12),
                        _numero('cintura', 'Cintura', unidad: 'cm'),
                        const SizedBox(height: 12),
                        _numero('cadera', 'Cadera', unidad: 'cm'),
                        const SizedBox(height: 16),
                        _campoLados('antebrazo', 'Antebrazo'),
                        const SizedBox(height: 12),
                        _campoLados('brazo', 'Brazo'),
                        const SizedBox(height: 12),
                        _campoLados('muslo', 'Muslo'),
                        const SizedBox(height: 12),
                        _campoLados('pantorrilla', 'Pantorrilla'),
                      ],
                    ),
                    _seccion(
                      'Observaciones',
                      Icons.notes_outlined,
                      [_texto(_observaciones, 'Observaciones', maxLines: 4)],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: ts(
                          14,
                          weight: kSemi,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PrimaryButton(
                        label: 'Guardar medición',
                        icon: Icons.save_outlined,
                        busy: _guardando,
                        onPressed: _guardando ? null : _guardar,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            gapAfter: 16,
          ),
        ],
      );
}
