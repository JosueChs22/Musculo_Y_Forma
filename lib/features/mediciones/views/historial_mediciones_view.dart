import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_exception.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../planes/models/plan.dart';
import '../../planes/views/widgets/cliente_picker_dialog.dart';
import '../../planes/views/widgets/menu_entrenador.dart';
import '../../secretaria/utils/citas_utils.dart';
import '../models/medicion_cliente.dart';
import '../services/mediciones_service.dart';
import 'comparacion_mediciones_view.dart';
import 'editar_medicion_dialog.dart';
import 'evolucion_mediciones_view.dart';

class HistorialMedicionesView extends StatefulWidget {
  const HistorialMedicionesView({super.key});

  @override
  State<HistorialMedicionesView> createState() =>
      _HistorialMedicionesViewState();
}

class _HistorialMedicionesViewState extends State<HistorialMedicionesView> {
  UsuarioResumen? _cliente;
  final List<MedicionCliente> _mediciones = [];
  String? _nextCursor;
  String? _error;
  bool _cargando = false;
  bool _cargandoMas = false;
  int _version = 0;
  String _estadoSeleccionado = 'Activo';
  final Set<String> _cambiandoEstados = {};

  bool get _cargandoAccion =>
      _cargando || _cargandoMas || _cambiandoEstados.isNotEmpty;

  Future<void> _seleccionarCliente() async {
    final elegido = await ClientePickerDialog.mostrar(
      context,
      titulo: 'BUSCAR CLIENTE',
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _version++;
      _cliente = elegido.cliente;
      _mediciones.clear();
      _nextCursor = null;
      _error = null;
      _cargando = false;
      _cargandoMas = false;
      _estadoSeleccionado = 'Activo';
    });
    await _cargarHistorial();
  }

  Future<void> _cargarHistorial({bool cargarMas = false}) async {
    final cliente = _cliente;
    if (cliente == null || _cargando || _cargandoMas) return;
    final version = cargarMas ? _version : ++_version;
    setState(() {
      _error = null;
      if (cargarMas) {
        _cargandoMas = true;
      } else {
        _cargando = true;
      }
    });
    try {
      final pagina = await context.read<MedicionesService>().listarHistorial(
            cliente.id,
            estado: _estadoSeleccionado,
            cursor: cargarMas ? _nextCursor : null,
          );
      if (!mounted || version != _version) return;
      setState(() {
        _mediciones.addAll(pagina.items);
        _nextCursor = pagina.nextCursor;
      });
    } on ApiException catch (e) {
      if (mounted && version == _version) setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted || version != _version) return;
      debugPrint('Error inesperado al consultar historial de mediciones: $e');
      setState(() => _error = 'No se pudo cargar el historial de mediciones.');
    } finally {
      if (mounted && version == _version) {
        setState(() {
          _cargando = false;
          _cargandoMas = false;
        });
      }
    }
  }

  Future<void> _editar(MedicionCliente medicion) async {
    final cliente = _cliente;
    if (cliente == null) return;
    final actualizada = await EditarMedicionDialog.mostrar(
      context,
      medicion: medicion,
      idUsuario: cliente.id,
      service: context.read<MedicionesService>(),
    );
    if (actualizada == null || !mounted) return;
    setState(() {
      final indice =
          _mediciones.indexWhere((item) => item.id == actualizada.id);
      if (indice >= 0) _mediciones[indice] = actualizada;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medición actualizada correctamente.')),
      );
    }
  }

  void _seleccionarEstado(String estado) {
    if (_estadoSeleccionado == estado || _cambiandoEstados.isNotEmpty) return;
    setState(() {
      _version++;
      _estadoSeleccionado = estado;
      _mediciones.clear();
      _nextCursor = null;
      _error = null;
      _cargando = false;
      _cargandoMas = false;
    });
    _cargarHistorial();
  }

  Future<void> _cambiarEstado(MedicionCliente medicion) async {
    if (_cargando || _cargandoMas || _cambiandoEstados.contains(medicion.id)) {
      return;
    }
    final nuevoEstado = medicion.estado == 'Activo' ? 'Inhabilitado' : 'Activo';
    setState(() => _cambiandoEstados.add(medicion.id));
    try {
      await context
          .read<MedicionesService>()
          .cambiarEstadoMedicion(medicion.id, nuevoEstado);
      if (!mounted) return;
      setState(() {
        _mediciones.clear();
        _nextCursor = null;
        _error = null;
      });
      await _cargarHistorial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado == 'Activo'
                  ? 'Medición habilitada. Está disponible en Activos.'
                  : 'Medición inhabilitada. Está disponible en Inactivos.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.mensaje)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al cambiar estado de medición: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cambiar el estado.')),
      );
    } finally {
      if (mounted) setState(() => _cambiandoEstados.remove(medicion.id));
    }
  }

  String _numero(num? valor, {String unidad = ''}) =>
      valor == null ? '—' : '$valor$unidad';

  String _medidas(MedicionCliente medicion) {
    final lineas = <String>[];
    for (final (campo, nombre) in const [
      ('hombros', 'Hombros'),
      ('pecho', 'Pecho'),
      ('espalda', 'Espalda'),
      ('cintura', 'Cintura'),
      ('cadera', 'Cadera'),
    ]) {
      final valor = medicion.medidas[campo] as num?;
      if (valor != null) {
        lineas.add('$nombre: ${_numero(valor, unidad: ' cm')}');
      }
    }
    for (final (grupo, nombre) in const [
      ('antebrazo', 'Antebrazo'),
      ('brazo', 'Brazo'),
      ('muslo', 'Muslo'),
      ('pantorrilla', 'Pantorrilla'),
    ]) {
      final lados = medicion.medidas[grupo] as Map?;
      if (lados == null) continue;
      final izquierdo = lados['izq'] as num?;
      final derecho = lados['der'] as num?;
      if (izquierdo != null || derecho != null) {
        lineas.add(
          '$nombre: izq. ${_numero(izquierdo, unidad: ' cm')} · '
          'der. ${_numero(derecho, unidad: ' cm')}',
        );
      }
    }
    return lineas.isEmpty
        ? 'Sin medidas corporales adicionales'
        : lineas.join('\n');
  }

  Widget _dato(String titulo, String valor) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 145,
              child: Text(titulo, style: ts(13, color: AppColors.pizarra)),
            ),
            Expanded(child: Text(valor, style: ts(14, color: AppColors.ink))),
          ],
        ),
      );

  Widget _estadistica(String titulo, String valor) => Container(
        constraints: const BoxConstraints(minWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.niebla,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: ts(12, color: AppColors.pizarra)),
            const SizedBox(height: 3),
            Text(valor, style: ts(15, weight: kSemi)),
          ],
        ),
      );

  Widget _seccion(String titulo, IconData icono, List<Widget> contenido) =>
      Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: AppColors.cobalto),
                const SizedBox(width: 8),
                Text(titulo, style: ts(15, weight: kSemi)),
              ],
            ),
            const SizedBox(height: 8),
            ...contenido,
          ],
        ),
      );

  Widget _tarjeta(MedicionCliente medicion, int indice) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    indice == 0 ? 'Más reciente' : 'Medición',
                    style: ts(16, weight: kSemi),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        medicion.estado,
                        style: ts(
                          13,
                          weight: kSemi,
                          color: medicion.estado == 'Activo'
                              ? AppColors.success
                              : AppColors.pizarra,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _cargando ||
                                _cargandoMas ||
                                _cambiandoEstados.contains(medicion.id)
                            ? null
                            : () => _cambiarEstado(medicion),
                        icon: Icon(
                          medicion.estado == 'Activo'
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(
                          medicion.estado == 'Activo'
                              ? 'Inhabilitar'
                              : 'Habilitar',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar medición',
                        onPressed:
                            _cargandoAccion ? null : () => _editar(medicion),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${fechaCitaLabel(medicion.fecha.toLocal())} · '
                '${horaCitaLabel(medicion.fecha.toLocal())}',
                style: ts(13, color: AppColors.pizarra),
              ),
              const Divider(height: 20),
              _seccion(
                'Resumen corporal',
                Icons.monitor_weight_outlined,
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _estadistica(
                        'Peso',
                        _numero(medicion.pesoCorporal, unidad: ' kg'),
                      ),
                      _estadistica(
                        'Estatura',
                        _numero(medicion.estatura, unidad: ' cm'),
                      ),
                      _estadistica('IMC', _numero(medicion.imc)),
                      _estadistica(
                        'Grasa corporal',
                        _numero(medicion.grasaCorporal, unidad: '%'),
                      ),
                      _estadistica(
                        'Grasa visceral',
                        _numero(medicion.grasaVisceral),
                      ),
                      _estadistica(
                        'Masa muscular',
                        _numero(medicion.masaMuscular, unidad: ' kg'),
                      ),
                    ],
                  ),
                ],
              ),
              _seccion(
                'Información general',
                Icons.person_outline,
                [
                  _dato('Edad', _numero(medicion.edad, unidad: ' años')),
                  _dato(
                    'Objetivo',
                    medicion.objetivo?.isNotEmpty == true
                        ? medicion.objetivo!
                        : '—',
                  ),
                  _dato(
                    'Actividad física',
                    medicion.nivelActividadFisica?.isNotEmpty == true
                        ? medicion.nivelActividadFisica!
                        : '—',
                  ),
                  _dato(
                    'Frecuencia semanal',
                    _numero(medicion.frecuenciaSemanal, unidad: ' días'),
                  ),
                ],
              ),
              _seccion(
                'Medidas corporales',
                Icons.straighten_outlined,
                [_dato('Perímetros', _medidas(medicion))],
              ),
              _seccion(
                'Observaciones',
                Icons.notes_outlined,
                [
                  Text(
                    medicion.observaciones?.isNotEmpty == true
                        ? medicion.observaciones!
                        : 'Sin observaciones',
                    style: ts(14, color: AppColors.ink),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cliente = _cliente;
    return SliverPage(
      slivers: [
        const Box(
          PageTitle(
            eyebrow: 'Panel del entrenador',
            title: 'Historial de mediciones',
            subtitle: 'Consulta y actualiza las evaluaciones de tus clientes.',
          ),
          gapAfter: 16,
        ),
        const Box(
          MenuEntrenador(seccion: SeccionEntrenador.historial),
          gapAfter: 16,
        ),
        Box(
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _cargandoAccion ? null : _seleccionarCliente,
                  icon: const Icon(Icons.search),
                  label: Text(
                    cliente == null
                        ? 'Buscar cliente por nombre o carné'
                        : 'Cambiar cliente',
                  ),
                ),
                if (cliente != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${cliente.nombre} · Carné ${cliente.usuario}',
                    style: ts(14, weight: kSemi),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cargandoAccion
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ComparacionMedicionesView(
                                  cliente: cliente,
                                  service: context.read<MedicionesService>(),
                                ),
                              ),
                            ),
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Comparar mediciones'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _cargandoAccion
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EvolucionMedicionesView(
                                  cliente: cliente,
                                  service: context.read<MedicionesService>(),
                                ),
                              ),
                            ),
                    icon: const Icon(Icons.show_chart),
                    label: const Text('Ver evolución histórica'),
                  ),
                ],
              ],
            ),
          ),
          gapAfter: 16,
        ),
        if (cliente != null)
          Box(
            Panel(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Activo',
                    label: Text('Activos'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: 'Inhabilitado',
                    label: Text('Inactivos'),
                    icon: Icon(Icons.block_outlined),
                  ),
                ],
                selected: {_estadoSeleccionado},
                showSelectedIcon: false,
                onSelectionChanged: _cambiandoEstados.isNotEmpty
                    ? null
                    : (seleccion) => _seleccionarEstado(seleccion.first),
              ),
            ),
            gapAfter: 16,
          ),
        if (_error != null)
          Box(
              ErrorPanel(
                message: _error!,
                onRetry: () => _cargarHistorial(cargarMas: _nextCursor != null),
              ),
              gapAfter: 12),
        if (_cargando)
          const Box(
            SkeletonScope(
              child: Column(
                children: [
                  SkeletonRow(),
                  SizedBox(height: 8),
                  SkeletonRow(),
                ],
              ),
            ),
            gapAfter: 12,
          ),
        if (cliente != null &&
            !_cargando &&
            _mediciones.isEmpty &&
            _error == null)
          Box(
            Panel(
              child: Text(
                'No hay mediciones ${_estadoSeleccionado == 'Activo' ? 'activas' : 'inactivas'} para este cliente.',
                style: ts(14, color: AppColors.pizarra),
              ),
            ),
            gapAfter: 12,
          ),
        if (_mediciones.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _tarjeta(_mediciones[index], index),
              childCount: _mediciones.length,
            ),
          ),
        if (_nextCursor != null)
          Box(
            Center(
              child: _cargandoMas
                  ? const SkeletonScope(
                      child: SkeletonBox(width: 180, height: 40, radius: 18),
                    )
                  : SecondaryButton(
                      label: 'Ver mediciones anteriores',
                      onPressed: () => _cargarHistorial(cargarMas: true),
                    ),
            ),
            gapAfter: 12,
          ),
      ],
    );
  }
}
