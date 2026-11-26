import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets.dart';
import '../../controllers/ejercicios_controller.dart';
import '../../models/ejercicio.dart';

/// Panel del Entrenador.
/// Crear y actualizar ejercicios.
///
/// RF-038 / RF-048: Ejercicios generales.
/// RF-045 / RF-052: Ejercicios de estiramiento.
class EjercicioFormDialog extends StatefulWidget {
  const EjercicioFormDialog({
    super.key,
    required this.controller,
    this.ejercicio,
  });

  final EjerciciosController controller;
  final Ejercicio? ejercicio;

  @override
  State<EjercicioFormDialog> createState() => _EjercicioFormDialogState();
}

class _EjercicioFormDialogState extends State<EjercicioFormDialog> {
  final _form = GlobalKey<FormState>();

  late final _nombre = TextEditingController(
    text: widget.ejercicio?.nombre,
  );

  late final _herramienta = TextEditingController(
    text: widget.ejercicio?.herramienta,
  );

  late final _tiempo = TextEditingController(
    text: widget.ejercicio?.tiempoRecomendado?.toString(),
  );

  late final _instrucciones = TextEditingController(
    text: widget.ejercicio?.instrucciones,
  );

  late final _recomendaciones = TextEditingController(
    text: widget.ejercicio?.recomendaciones,
  );

  late final _observaciones = TextEditingController(
    text: widget.ejercicio?.observaciones,
  );

  late String? _grupo = widget.ejercicio?.grupoMuscular;

  /// Sprint 3: tipo de ejercicio seleccionado.
  late String _tipo =
      widget.ejercicio?.tipo ?? widget.controller.tipoFiltro ?? 'entrenamiento';

  bool get _editando => widget.ejercicio != null;

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _herramienta,
      _tiempo,
      _instrucciones,
      _recomendaciones,
      _observaciones,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  num? get _minutos {
    if (_tiempo.text.trim().isEmpty) return null;

    return num.tryParse(
      _tiempo.text.trim().replaceAll(',', '.'),
    );
  }

  String? _validarTiempo(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return null;
    }

    final numero = _minutos;

    if (numero == null || numero < 0 || numero > 600) {
      return 'Ingrese los minutos, entre 0 y 600';
    }

    return null;
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;

    final ok = await widget.controller.guardar(
      DatosEjercicio(
        nombre: _nombre.text,

        // Sprint 3: enviar el tipo seleccionado.
        tipo: _tipo,

        grupoMuscular: _grupo,
        herramienta: _herramienta.text,
        tiempoRecomendado: _minutos,
        instrucciones: _instrucciones.text,
        recomendaciones: _recomendaciones.text,
        observaciones: _observaciones.text,
      ),
      id: widget.ejercicio?.id,
    );

    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _editando ? 'Ejercicio actualizado' : 'Ejercicio creado',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final enabled = !c.guardando;

        final grupos = [
          ...gruposMusculares,
          if (_grupo != null && !gruposMusculares.contains(_grupo)) _grupo!,
        ];

        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            _editando ? 'EDITAR EJERCICIO' : 'NUEVO EJERCICIO',
            style: display(28),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Nombre del ejercicio.
                          _campo(
                            _nombre,
                            'Nombre',
                            enabled,
                            max: 80,
                            validator: (v) => Validators.requerido(
                              v,
                              'El nombre',
                            ),
                          ),

                          // Sprint 3: seleccionar tipo.
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 14,
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _tipo,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de ejercicio',
                              ),
                              items: [
                                for (final tipo in tiposEjercicio)
                                  DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(
                                      etiquetaTipoEjercicio(tipo),
                                    ),
                                  ),
                              ],
                              onChanged: enabled
                                  ? (tipo) {
                                      if (tipo != null) {
                                        setState(() {
                                          _tipo = tipo;
                                        });
                                      }
                                    }
                                  : null,
                            ),
                          ),

                          // Grupo muscular.
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 14,
                            ),
                            child: DropdownButtonFormField<String?>(
                              initialValue: _grupo,
                              decoration: const InputDecoration(
                                labelText: 'Grupo muscular (opcional)',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Sin especificar'),
                                ),
                                for (final g in grupos)
                                  DropdownMenuItem<String?>(
                                    value: g,
                                    child: Text(g),
                                  ),
                              ],
                              onChanged: enabled
                                  ? (g) {
                                      setState(() {
                                        _grupo = g;
                                      });
                                    }
                                  : null,
                            ),
                          ),

                          _campo(
                            _herramienta,
                            'Herramienta o equipo (opcional)',
                            enabled,
                            max: 80,
                          ),

                          _campo(
                            _tiempo,
                            'Tiempo recomendado en minutos (opcional)',
                            enabled,
                            max: 6,
                            validator: _validarTiempo,
                            tipo: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formato: FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ),

                          _campo(
                            _instrucciones,
                            'Instrucciones (opcional)',
                            enabled,
                            max: 2000,
                            lineas: 4,
                          ),

                          _campo(
                            _recomendaciones,
                            'Recomendaciones (opcional)',
                            enabled,
                            max: 1000,
                            lineas: 2,
                          ),

                          _campo(
                            _observaciones,
                            'Observaciones (opcional)',
                            enabled,
                            max: 1000,
                            lineas: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Mostrar errores sin cerrar el formulario.
                if (c.errorGuardar != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                    ),
                    child: Text(
                      c.errorGuardar!,
                      style: ts(
                        14,
                        weight: kSemi,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: enabled ? () => Navigator.of(context).pop() : null,
              child: Text(
                'Cancelar',
                style: ts(
                  15,
                  weight: kSemi,
                  color: AppColors.cobalto,
                ),
              ),
            ),
            PrimaryButton(
              label: _editando ? 'Guardar cambios' : 'Crear ejercicio',
              busy: c.guardando,
              onPressed: _guardar,
            ),
          ],
        );
      },
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta,
    bool enabled, {
    required int max,
    String? Function(String?)? validator,
    TextInputType? tipo,
    TextInputFormatter? formato,
    int lineas = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: tipo,
        minLines: lineas,
        maxLines: lineas == 1 ? 1 : 8,
        inputFormatters: [
          LengthLimitingTextInputFormatter(max),
          if (formato != null) formato,
        ],
        decoration: InputDecoration(
          labelText: etiqueta,
          alignLabelWithHint: lineas > 1,
        ),
        validator: validator,
      ),
    );
  }
}
