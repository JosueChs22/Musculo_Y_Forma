import 'package:flutter/material.dart';

import '../../models/horario_especial.dart';

class HorarioEspecialFormDialog extends StatefulWidget {
  const HorarioEspecialFormDialog({
    super.key,
    this.horario,
  });

  final HorarioEspecial? horario;

  static Future<HorarioEspecial?> show(
    BuildContext context, {
    HorarioEspecial? horario,
  }) {
    return showDialog<HorarioEspecial>(
      context: context,
      builder: (_) => HorarioEspecialFormDialog(horario: horario),
    );
  }

  @override
  State<HorarioEspecialFormDialog> createState() =>
      _HorarioEspecialFormDialogState();
}

class _HorarioEspecialFormDialogState extends State<HorarioEspecialFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _motivo;
  late final TextEditingController _observaciones;

  late DateTime _fecha;
  late TimeOfDay _horaApertura;
  late TimeOfDay _horaCierre;
  late bool _cierreTotal;

  @override
  void initState() {
    super.initState();

    final horario = widget.horario;

    _motivo = TextEditingController(text: horario?.motivo ?? '');
    _observaciones = TextEditingController(text: horario?.observaciones ?? '');

    _fecha = DateTime.tryParse(horario?.fecha ?? '') ?? DateTime.now();

    _horaApertura = _parseHora(horario?.horaApertura, 8);
    _horaCierre = _parseHora(horario?.horaCierre, 17);

    _cierreTotal = horario?.cierreTotal ?? false;
  }

  TimeOfDay _parseHora(String? hora, int defecto) {
    if (hora == null) {
      return TimeOfDay(hour: defecto, minute: 0);
    }

    final partes = hora.split(':');

    if (partes.length != 2) {
      return TimeOfDay(hour: defecto, minute: 0);
    }

    return TimeOfDay(
      hour: int.parse(partes[0]),
      minute: int.parse(partes[1]),
    );
  }

  String _formatearHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatearFecha(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (fecha == null || !mounted) return;

    setState(() => _fecha = fecha);
  }

  Future<void> _seleccionarHora(bool apertura) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: apertura ? _horaApertura : _horaCierre,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true,
        ),
        child: child!,
      ),
    );

    if (hora == null || !mounted) return;

    setState(() {
      if (apertura) {
        _horaApertura = hora;
      } else {
        _horaCierre = hora;
      }
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final inicio = _horaApertura.hour * 60 + _horaApertura.minute;
    final fin = _horaCierre.hour * 60 + _horaCierre.minute;

    if (!_cierreTotal && fin <= inicio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La hora de cierre debe ser posterior a la apertura.',
          ),
        ),
      );
      return;
    }

    final horario = HorarioEspecial(
      id: widget.horario?.id ?? '',
      estado: widget.horario?.estado ?? 'Activo',
      motivo: _motivo.text.trim(),
      fecha: _formatearFecha(_fecha),
      cierreTotal: _cierreTotal,
      horaApertura: _cierreTotal ? null : _formatearHora(_horaApertura),
      horaCierre: _cierreTotal ? null : _formatearHora(_horaCierre),
      observaciones: _observaciones.text.trim().isEmpty
          ? null
          : _observaciones.text.trim(),
    );

    Navigator.of(context).pop(horario);
  }

  @override
  void dispose() {
    _motivo.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.horario != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editando
                      ? 'Editar horario especial'
                      : 'Nuevo horario especial',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _motivo,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El motivo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Fecha: ${_formatearFecha(_fecha)}'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Cierre total'),
                  subtitle: const Text(
                    'El gimnasio permanecerá cerrado todo el día.',
                  ),
                  contentPadding: EdgeInsets.zero,
                  value: _cierreTotal,
                  onChanged: (valor) {
                    setState(() => _cierreTotal = valor);
                  },
                ),
                if (!_cierreTotal) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _seleccionarHora(true),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      'Apertura: ${_formatearHora(_horaApertura)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _seleccionarHora(false),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      'Cierre: ${_formatearHora(_horaCierre)}',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observaciones,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _guardar,
                      child: Text(
                        editando ? 'Guardar cambios' : 'Crear horario',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
