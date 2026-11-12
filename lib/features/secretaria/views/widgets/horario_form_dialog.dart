import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/horario_clase.dart';

/// Diálogo para agregar o actualizar un Horario de clase (RF-015 / RF-020).
class HorarioFormDialog extends StatefulWidget {
  const HorarioFormDialog({super.key, this.horario});

  final HorarioClase? horario;

  static Future<HorarioClase?> show(BuildContext context, {HorarioClase? horario}) =>
      showDialog<HorarioClase>(
        context: context,
        builder: (_) => HorarioFormDialog(horario: horario),
      );

  @override
  State<HorarioFormDialog> createState() => _HorarioFormDialogState();
}

class _HorarioFormDialogState extends State<HorarioFormDialog> {
  static const _diaLabels = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  late Set<int> _diasSeleccionados;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;
  String? _errorDias;
  String? _errorHora;

  @override
  void initState() {
    super.initState();
    _diasSeleccionados = Set<int>.from(widget.horario?.dias ?? <int>[]);
    _horaInicio = _parse(widget.horario?.horaInicio ?? '07:00');
    _horaFin = _parse(widget.horario?.horaFin ?? '08:00');
  }

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool esInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _horaInicio = picked;
      } else {
        _horaFin = picked;
      }
      _errorHora = null;
    });
  }

  bool _validate() {
    bool ok = true;
    if (_diasSeleccionados.isEmpty) {
      setState(() => _errorDias = 'Selecciona al menos un día');
      ok = false;
    }
    final inicioMins = _horaInicio.hour * 60 + _horaInicio.minute;
    final finMins = _horaFin.hour * 60 + _horaFin.minute;
    if (finMins <= inicioMins) {
      setState(() => _errorHora = 'La hora de fin debe ser posterior a la de inicio');
      ok = false;
    }
    return ok;
  }

  void _submit() {
    if (!_validate()) return;
    Navigator.of(context).pop(HorarioClase(
      dias: _diasSeleccionados.toList()..sort(),
      horaInicio: _format(_horaInicio),
      horaFin: _format(_horaFin),
      estado: 'Activo',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.horario != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
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

              // Días de la semana
              Text('Días', style: ts(14, weight: kSemi)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (int d = 1; d <= 7; d++)
                    _DayChip(
                      label: _diaLabels[d],
                      selected: _diasSeleccionados.contains(d),
                      onTap: () => setState(() {
                        _diasSeleccionados.contains(d)
                            ? _diasSeleccionados.remove(d)
                            : _diasSeleccionados.add(d);
                        _errorDias = null;
                      }),
                    ),
                ],
              ),
              if (_errorDias != null) ...[
                const SizedBox(height: 6),
                Text(_errorDias!, style: ts(12, color: AppColors.danger)),
              ],

              const SizedBox(height: 20),

              // Horas
              Row(children: [
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
              ]),
              if (_errorHora != null) ...[
                const SizedBox(height: 6),
                Text(_errorHora!, style: ts(12, color: AppColors.danger)),
              ],

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
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
  const _DayChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.indigo : AppColors.niebla,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.indigo : AppColors.line),
          ),
          child: Text(
            label,
            style: ts(13, weight: kSemi, color: selected ? Colors.white : AppColors.pizarra),
          ),
        ),
      );
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  String get _formatted =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: ts(12, color: AppColors.pizarra)),
                const SizedBox(height: 2),
                Text(_formatted, style: ts(16, weight: kSemi)),
              ]),
            ),
            const Icon(Icons.access_time, size: 18, color: AppColors.pizarra),
          ]),
        ),
      );
}
