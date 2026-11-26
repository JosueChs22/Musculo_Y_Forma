import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/horario_clase.dart';

/// Diálogo para agregar o actualizar un horario de clase.
class HorarioFormDialog extends StatefulWidget {
  const HorarioFormDialog({
    super.key,
    this.horario,
  });

  final HorarioClase? horario;

  static Future<HorarioClase?> show(
    BuildContext context, {
    HorarioClase? horario,
  }) =>
      showDialog<HorarioClase>(
        context: context,
        builder: (_) => HorarioFormDialog(horario: horario),
      );

  @override
  State<HorarioFormDialog> createState() => _HorarioFormDialogState();
}

class _HorarioFormDialogState extends State<HorarioFormDialog> {
  static const _diaLabels = [
    '',
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  late Set<int> _diasSeleccionados;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  String? _errorDias;
  String? _errorHora;
  String? _errorFecha;

  @override
  void initState() {
    super.initState();

    _diasSeleccionados = Set<int>.from(widget.horario?.dias ?? <int>[]);

    _horaInicio = _parse(widget.horario?.horaInicio ?? '07:00');
    _horaFin = _parse(widget.horario?.horaFin ?? '08:00');

    _fechaInicio = _parseDate(widget.horario?.fechaInicio);
    _fechaFin = _parseDate(widget.horario?.fechaFin);
  }

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');

    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _format(TimeOfDay time) {
    final hora = time.hour.toString().padLeft(2, '0');
    final minuto = time.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _pickTime(bool esInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          alwaysUse24HourFormat: true,
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (esInicio) {
        _horaInicio = picked;
      } else {
        _horaFin = picked;
      }

      _errorHora = null;
    });
  }

  Future<void> _pickDate(bool esInicio) async {
    final actual = esInicio ? _fechaInicio : _fechaFin;

    final picked = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: esInicio
          ? 'Seleccionar fecha de inicio'
          : 'Seleccionar fecha de finalización',
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (esInicio) {
        _fechaInicio = picked;
      } else {
        _fechaFin = picked;
      }

      _errorFecha = null;
    });
  }

  bool _validate() {
    bool ok = true;

    setState(() {
      _errorDias = null;
      _errorHora = null;
      _errorFecha = null;

      if (_diasSeleccionados.isEmpty) {
        _errorDias = 'Selecciona al menos un día';
        ok = false;
      }

      final inicioMins = _horaInicio.hour * 60 + _horaInicio.minute;

      final finMins = _horaFin.hour * 60 + _horaFin.minute;

      if (finMins <= inicioMins) {
        _errorHora = 'La hora de fin debe ser posterior a la de inicio';
        ok = false;
      }

      if (_fechaInicio != null &&
          _fechaFin != null &&
          _fechaFin!.isBefore(_fechaInicio!)) {
        _errorFecha = 'La fecha final no puede ser anterior a la inicial';
        ok = false;
      }
    });

    return ok;
  }

  void _submit() {
    if (!_validate()) return;

    Navigator.of(context).pop(
      HorarioClase(
        dias: _diasSeleccionados.toList()..sort(),
        horaInicio: _format(_horaInicio),
        horaFin: _format(_horaFin),
        fechaInicio: _formatDate(_fechaInicio),
        fechaFin: _formatDate(_fechaFin),
        estado: widget.horario?.estado ?? 'Activo',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.horario != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        // Permitir desplazamiento en ventanas de poca altura.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageTitle(
                eyebrow: esEdicion ? 'Editar' : 'Agregar',
                title: esEdicion ? 'Editar horario' : 'Nuevo horario',
              ),

              const SizedBox(height: 24),

              // Días de la semana.
              Text(
                'Días',
                style: ts(14, weight: kSemi),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int d = 1; d <= 7; d++)
                    _DayChip(
                      label: _diaLabels[d],
                      selected: _diasSeleccionados.contains(d),
                      onTap: () {
                        setState(() {
                          if (_diasSeleccionados.contains(d)) {
                            _diasSeleccionados.remove(d);
                          } else {
                            _diasSeleccionados.add(d);
                          }

                          _errorDias = null;
                        });
                      },
                    ),
                ],
              ),

              if (_errorDias != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorDias!,
                  style: ts(12, color: AppColors.danger),
                ),
              ],

              const SizedBox(height: 20),

              // Horas de inicio y fin.
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Hora inicio',
                      time: _horaInicio,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimeField(
                      label: 'Hora fin',
                      time: _horaFin,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),

              if (_errorHora != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorHora!,
                  style: ts(12, color: AppColors.danger),
                ),
              ],

              const SizedBox(height: 24),

              // Fechas de vigencia.
              Text(
                'Vigencia del horario',
                style: ts(14, weight: kSemi),
              ),

              const SizedBox(height: 6),

              Text(
                'Las fechas son opcionales.',
                style: ts(
                  12,
                  color: AppColors.pizarra,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Fecha inicio',
                      date: _formatDate(_fechaInicio),
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateField(
                          label: 'Fecha fin',
                          date: _formatDate(_fechaFin),
                          onTap: () => _pickDate(false),
                        ),
                        if (_fechaFin != null) ...[
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _fechaFin = null;
                                _errorFecha = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Quitar fecha'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (_errorFecha != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorFecha!,
                  style: ts(12, color: AppColors.danger),
                ),
              ],

              const SizedBox(height: 28),

              // Acciones.
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  SecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  PrimaryButton(
                    label: esEdicion ? 'Guardar cambios' : 'Agregar horario',
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        radius: 12,
        selected: selected,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.indigo : AppColors.niebla,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.indigo : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: ts(
              13,
              weight: kSemi,
              color: selected ? Colors.white : AppColors.pizarra,
            ),
          ),
        ),
      );
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  String get _formatted {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        radius: kRadiusControl,
        semanticLabel: '$label: $_formatted. Cambiar hora',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(kRadiusControl),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: ts(12, color: AppColors.pizarra)),
                    const SizedBox(height: 2),
                    Text(_formatted, style: ts(16, weight: kSemi)),
                  ],
                ),
              ),
              const Icon(Icons.access_time, size: 18, color: AppColors.pizarra),
            ],
          ),
        ),
      );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final String? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      radius: kRadiusControl,
      semanticLabel: '$label: ${date ?? 'Sin fecha'}. Elegir fecha',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(kRadiusControl),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ts(
                      12,
                      color: AppColors.pizarra,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date ?? 'Sin fecha',
                    style: ts(
                      14,
                      weight: kSemi,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppColors.pizarra,
            ),
          ],
        ),
      ),
    );
  }
}
