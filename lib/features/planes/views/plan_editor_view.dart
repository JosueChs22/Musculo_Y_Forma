import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/imagen_red.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/plan_editor_controller.dart';
import '../models/plan.dart';
import '../services/planes_service.dart';
import 'widgets/cliente_picker_dialog.dart';
import 'widgets/selector_ejercicios_dialog.dart';

/// Crear o editar un plan: datos generales, ejercicios del catálogo con series,
/// repeticiones y descanso, y a quién se asigna.
class PlanEditorView extends StatefulWidget {
  const PlanEditorView({super.key, this.id});

  /// null para un plan nuevo.
  final String? id;

  @override
  State<PlanEditorView> createState() => _PlanEditorViewState();
}

class _PlanEditorViewState extends State<PlanEditorView> {
  late final _c = PlanEditorController(context.read<PlanesService>(), id: widget.id);
  final _nombre = TextEditingController();
  final _observaciones = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.cargar().then((_) {
      if (!mounted) return;
      _nombre.text = _c.nombre;
      _observaciones.text = _c.observaciones;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _nombre.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final messenger = ScaffoldMessenger.of(context);
    final nuevo = _c.esNuevo;
    final ok = await _c.guardar();
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(nuevo ? 'Plan creado' : 'Plan actualizado')));
    context.go('/coach');
  }

  Future<void> _elegirCliente() async {
    final elegido = await ClientePickerDialog.mostrar(context, actual: _c.cliente);
    if (elegido != null) _c.cambiarCliente(elegido.cliente);
  }

  void _agregarEjercicios() {
    showDialog<void>(
      context: context,
      builder: (_) => SelectorEjerciciosDialog(yaEsta: _c.tieneEjercicio, onAgregar: _c.agregar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final encabezado = [
          Box(
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/coach'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.cobalto,
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('Volver a los planes', style: ts(14, weight: kSemi, color: AppColors.cobalto)),
              ),
            ),
            gapAfter: 8,
          ),
          Box(
            PageTitle(eyebrow: 'Panel del entrenador', title: _c.esNuevo ? 'Nuevo plan' : 'Editar plan'),
            gapAfter: 20,
          ),
        ];

        if (_c.errorCarga != null) {
          return SliverPage(slivers: [
            ...encabezado,
            Box(ErrorPanel(message: _c.errorCarga!, onRetry: _c.cargar)),
          ]);
        }
        if (_c.cargando) {
          return SliverPage(slivers: [
            ...encabezado,
            const Box(SkeletonScope(child: SkeletonBox(height: 260, radius: 18)), gapAfter: 16),
            const Box(SkeletonScope(child: Column(children: [SkeletonRow(), SizedBox(height: 12), SkeletonRow()]))),
          ]);
        }

        final ejercicios = _c.ejercicios;
        final habilitado = _c.editable && !_c.guardando;

        return SliverPage(slivers: [
          ...encabezado,
          if (!_c.editable)
            Box(
              Panel(
                child: Row(children: [
                  const Icon(Icons.block, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Este plan está inhabilitado. Reactívalo desde la lista para poder editarlo.',
                        style: ts(14, weight: kSemi)),
                  ),
                ]),
              ),
              gapAfter: 16,
            ),
          Box(_DatosGenerales(controller: _c, nombre: _nombre, observaciones: _observaciones, habilitado: habilitado),
              gapAfter: 16),
          Box(_Asignacion(controller: _c, habilitado: habilitado, onElegir: _elegirCliente), gapAfter: 24),
          Box(
            SectionHeader(
              eyebrow: 'Ejercicios',
              title: '${ejercicios.length} en el plan',
              trailing: PrimaryButton(
                label: 'Agregar ejercicios',
                icon: Icons.add,
                onPressed: habilitado && _c.puedeAgregar ? _agregarEjercicios : null,
              ),
            ),
            gapAfter: 16,
          ),
          if (ejercicios.isEmpty)
            Box(
              Panel(
                child: Text('Todavía no hay ejercicios. Agrégalos desde el catálogo con "Agregar ejercicios".',
                    style: ts(15, color: AppColors.pizarra)),
              ),
              gapAfter: 16,
            )
          else
            // REGLA 4: lista virtualizada (máximo 50 ejercicios por plan)
            SliverList.builder(
              itemCount: ejercicios.length,
              findChildIndexCallback: (key) {
                if (key is! ValueKey<String>) return null;
                final i = ejercicios.indexWhere((e) => e.idEjercicio == key.value);
                return i == -1 ? null : i;
              },
              itemBuilder: (context, i) => Padding(
                key: ValueKey(ejercicios[i].idEjercicio),
                padding: const EdgeInsets.only(bottom: 12),
                child: _FilaEjercicio(
                  controller: _c,
                  ejercicio: ejercicios[i],
                  posicion: i,
                  total: ejercicios.length,
                  habilitado: habilitado,
                ),
              ),
            ),
          Box(
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_c.errorGuardar != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_c.errorGuardar!, style: ts(14, weight: kSemi, color: AppColors.danger)),
                ),
              Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.end, children: [
                SecondaryButton(
                  label: 'Cancelar',
                  onPressed: _c.guardando ? null : () => context.go('/coach'),
                ),
                PrimaryButton(
                  label: _c.esNuevo ? 'Crear plan' : 'Guardar cambios',
                  busy: _c.guardando,
                  onPressed: _c.editable ? _guardar : null,
                ),
              ]),
            ]),
          ),
        ]);
      },
    );
  }
}

class _DatosGenerales extends StatelessWidget {
  const _DatosGenerales({
    required this.controller,
    required this.nombre,
    required this.observaciones,
    required this.habilitado,
  });

  final PlanEditorController controller;
  final TextEditingController nombre;
  final TextEditingController observaciones;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Eyebrow('Tipo de plan'),
        const SizedBox(height: 8),
        SegmentedButton<CategoriaPlan>(
          segments: [
            for (final cat in CategoriaPlan.values) ButtonSegment(value: cat, label: Text(cat.etiqueta)),
          ],
          selected: {c.categoria},
          showSelectedIcon: false,
          onSelectionChanged: habilitado ? (s) => c.cambiarCategoria(s.first) : null,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.indigo,
            selectedForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nombre,
          enabled: habilitado,
          onChanged: c.cambiarNombre,
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          decoration: const InputDecoration(labelText: 'Nombre del plan'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int?>(
          initialValue: c.diaSemana,
          decoration: const InputDecoration(labelText: 'Día de la semana (opcional)'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Sin día fijo')),
            for (var i = 0; i < diasSemana.length; i++) DropdownMenuItem<int?>(value: i + 1, child: Text(diasSemana[i])),
          ],
          onChanged: habilitado ? c.cambiarDia : null,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: observaciones,
          enabled: habilitado,
          onChanged: c.cambiarObservaciones,
          minLines: 2,
          maxLines: 5,
          inputFormatters: [LengthLimitingTextInputFormatter(1000)],
          decoration: const InputDecoration(labelText: 'Observaciones (opcional)', alignLabelWithHint: true),
        ),
      ]),
    );
  }
}

class _Asignacion extends StatelessWidget {
  const _Asignacion({required this.controller, required this.habilitado, required this.onElegir});

  final PlanEditorController controller;
  final bool habilitado;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final cliente = controller.cliente;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Avatar(cliente?.iniciales ?? '?', size: 44, bg: AppColors.indigoSoft, fg: AppColors.indigo),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Eyebrow('Asignado a'),
              const SizedBox(height: 2),
              Text(cliente?.nombre ?? 'Sin asignar', style: ts(16, weight: kSemi)),
              if (cliente == null && controller.esNuevo)
                Text('Puedes asignarlo ahora o después, desde la lista.', style: ts(13, color: AppColors.pizarra)),
            ]),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: [
            SecondaryButton(
              label: cliente == null ? 'Asignar a un usuario' : 'Cambiar usuario',
              icon: Icons.person_search_outlined,
              onPressed: habilitado ? onElegir : null,
            ),
            if (cliente != null)
              TextButton(
                onPressed: habilitado ? () => controller.cambiarCliente(null) : null,
                child: Text('Quitar', style: ts(15, weight: kSemi, color: AppColors.danger)),
              ),
          ]),
        ],
      ),
    );
  }
}

/// Un ejercicio del plan: imagen, nombre y sus campos de dosificación.
class _FilaEjercicio extends StatefulWidget {
  const _FilaEjercicio({
    required this.controller,
    required this.ejercicio,
    required this.posicion,
    required this.total,
    required this.habilitado,
  });

  final PlanEditorController controller;
  final PlanEjercicio ejercicio;
  final int posicion;
  final int total;
  final bool habilitado;

  @override
  State<_FilaEjercicio> createState() => _FilaEjercicioState();
}

class _FilaEjercicioState extends State<_FilaEjercicio> {
  late final _series = TextEditingController(text: '${widget.ejercicio.series}');
  late final _reps = TextEditingController(text: '${widget.ejercicio.repeticiones}');
  late final _descanso = TextEditingController(text: '${widget.ejercicio.descanso}');
  late final _peso = TextEditingController(text: widget.ejercicio.pesoSugerido?.toString() ?? '');
  late final _nota = TextEditingController(text: widget.ejercicio.nota ?? '');

  String? _errSeries, _errReps, _errDescanso, _errPeso;

  @override
  void dispose() {
    for (final c in [_series, _reps, _descanso, _peso, _nota]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _id => widget.ejercicio.idEjercicio;

  // Un entero dentro de [min, max]: si el valor es válido se guarda; si no, se marca el campo.
  void _entero(String texto, int min, int max, void Function(String?) error, PlanEjercicio Function(PlanEjercicio, int) cambio) {
    final n = int.tryParse(texto.trim());
    final valido = n != null && n >= min && n <= max;
    setState(() => error(valido ? null : 'De $min a $max'));
    if (valido) widget.controller.actualizarEjercicio(_id, (e) => cambio(e, n));
  }

  void _pesoCambio(String texto) {
    final t = texto.trim().replaceAll(',', '.');
    if (t.isEmpty) {
      setState(() => _errPeso = null);
      widget.controller.actualizarEjercicio(_id, (e) => e.copyWith(quitarPeso: true));
      return;
    }
    final n = num.tryParse(t);
    final valido = n != null && n >= 0 && n <= 1000;
    setState(() => _errPeso = valido ? null : 'De 0 a 1000');
    if (valido) widget.controller.actualizarEjercicio(_id, (e) => e.copyWith(pesoSugerido: n));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.ejercicio;
    final h = widget.habilitado;

    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(10)),
            child: Text('${widget.posicion + 1}'.padLeft(2, '0'), style: display(18, color: AppColors.indigo)),
          ),
          const SizedBox(width: 12),
          ImagenRed(e.imagenUrl, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi)),
              Text(
                e.activo ? (e.grupoMuscular ?? '') : 'Ejercicio inhabilitado: quítalo para guardar el plan',
                style: ts(13, weight: e.activo ? kRegular : kSemi, color: e.activo ? AppColors.pizarra : AppColors.danger),
              ),
            ]),
          ),
          IconButton(
            tooltip: 'Subir ${e.nombre}',
            icon: const Icon(Icons.arrow_upward, size: 20),
            onPressed: h && widget.posicion > 0 ? () => widget.controller.mover(_id, -1) : null,
          ),
          IconButton(
            tooltip: 'Bajar ${e.nombre}',
            icon: const Icon(Icons.arrow_downward, size: 20),
            onPressed: h && widget.posicion < widget.total - 1 ? () => widget.controller.mover(_id, 1) : null,
          ),
          IconButton(
            tooltip: 'Quitar ${e.nombre}',
            icon: const Icon(Icons.close, size: 20, color: AppColors.danger),
            onPressed: h ? () => widget.controller.quitar(_id) : null,
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Campo(
            etiqueta: 'Series',
            controller: _series,
            error: _errSeries,
            habilitado: h,
            onChanged: (t) => _entero(t, 1, 20, (m) => _errSeries = m, (e, n) => e.copyWith(series: n)),
          ),
          _Campo(
            etiqueta: 'Repeticiones',
            controller: _reps,
            error: _errReps,
            habilitado: h,
            ancho: 120,
            onChanged: (t) => _entero(t, 1, 500, (m) => _errReps = m, (e, n) => e.copyWith(repeticiones: n)),
          ),
          _Campo(
            etiqueta: 'Descanso (s)',
            controller: _descanso,
            error: _errDescanso,
            habilitado: h,
            ancho: 120,
            onChanged: (t) => _entero(t, 0, 1800, (m) => _errDescanso = m, (e, n) => e.copyWith(descanso: n)),
          ),
          _Campo(
            etiqueta: 'Peso (kg)',
            controller: _peso,
            error: _errPeso,
            habilitado: h,
            ancho: 120,
            decimal: true,
            onChanged: _pesoCambio,
          ),
          _Campo(
            etiqueta: 'Nota (opcional)',
            controller: _nota,
            habilitado: h,
            ancho: 260,
            numerico: false,
            maxLargo: 200,
            onChanged: (t) => widget.controller.actualizarEjercicio(_id, (e) => e.copyWith(nota: t)),
          ),
        ]),
      ]),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.etiqueta,
    required this.controller,
    required this.onChanged,
    required this.habilitado,
    this.error,
    this.ancho = 100,
    this.numerico = true,
    this.decimal = false,
    this.maxLargo = 6,
  });

  final String etiqueta;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool habilitado;
  final String? error;
  final double ancho;
  final bool numerico;
  final bool decimal;
  final int maxLargo;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ancho,
        child: TextField(
          controller: controller,
          enabled: habilitado,
          onChanged: onChanged,
          keyboardType: numerico ? TextInputType.numberWithOptions(decimal: decimal) : TextInputType.text,
          inputFormatters: [
            LengthLimitingTextInputFormatter(maxLargo),
            if (numerico) FilteringTextInputFormatter.allow(decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
          ],
          decoration: InputDecoration(labelText: etiqueta, errorText: error, isDense: true),
        ),
      );
}
