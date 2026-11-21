import 'package:flutter/material.dart';

import '../../../core/api_exception.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../planes/models/plan.dart';
import '../../secretaria/utils/citas_utils.dart';
import '../models/comparacion_mediciones.dart';
import '../models/medicion_cliente.dart';
import '../services/mediciones_service.dart';

class ComparacionMedicionesView extends StatefulWidget {
  const ComparacionMedicionesView({
    super.key,
    required this.cliente,
    required this.service,
  });

  final UsuarioResumen cliente;
  final MedicionesService service;

  @override
  State<ComparacionMedicionesView> createState() =>
      _ComparacionMedicionesViewState();
}

class _ComparacionMedicionesViewState extends State<ComparacionMedicionesView> {
  late Future<PaginaMediciones> _consulta;

  @override
  void initState() {
    super.initState();
    _consulta = _cargar();
  }

  Future<PaginaMediciones> _cargar() =>
      widget.service.listarHistorial(widget.cliente.id, estado: 'Activo');

  String _fecha(DateTime fecha) {
    final local = fecha.toLocal();
    return '${fechaCitaLabel(local)} · ${horaCitaLabel(local)}';
  }

  String _numero(num? valor, String unidad) {
    if (valor == null) return '—';
    final texto = valor.toStringAsFixed(2);
    return unidad.isEmpty ? texto : '$texto $unidad';
  }

  Widget _valor(String titulo, String valor) => SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: ts(12, color: AppColors.pizarra)),
            const SizedBox(height: 4),
            Text(valor, style: ts(15, weight: kSemi)),
          ],
        ),
      );

  Widget _indicador(ComparacionIndicador indicador) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.niebla,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(indicador.nombre, style: ts(15, weight: kSemi)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _valor(
                    'Anterior', _numero(indicador.anterior, indicador.unidad)),
                _valor('Actual', _numero(indicador.actual, indicador.unidad)),
                _valor(
                  'Diferencia absoluta',
                  _numero(
                    indicador.diferenciaAbsoluta,
                    indicador.unidad == '%' ? 'p.p.' : indicador.unidad,
                  ),
                ),
                _valor(
                  'Variación',
                  indicador.variacionPorcentual == null
                      ? '—'
                      : '${indicador.variacionPorcentual! >= 0 ? '+' : ''}'
                          '${indicador.variacionPorcentual!.toStringAsFixed(2)} %',
                ),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Comparación de mediciones')),
        body: SliverPage(
          slivers: [
            Box(
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.cliente.nombre, style: ts(18, weight: kSemi)),
                    const SizedBox(height: 4),
                    Text('Carné ${widget.cliente.usuario}',
                        style: ts(14, color: AppColors.pizarra)),
                    const SizedBox(height: 16),
                    FutureBuilder<PaginaMediciones>(
                      future: _consulta,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          final error = snapshot.error;
                          if (error is! ApiException) {
                            debugPrint('Error al comparar mediciones: $error');
                          }
                          return ErrorPanel(
                            message: error is ApiException
                                ? error.mensaje
                                : 'No se pudo cargar la comparación.',
                            onRetry: () => setState(() {
                              _consulta = _cargar();
                            }),
                          );
                        }
                        final mediciones = snapshot.requireData.items;
                        if (mediciones.length < 2) {
                          return Text(
                            'Se necesitan al menos dos mediciones activas para comparar.',
                            style: ts(14, color: AppColors.pizarra),
                          );
                        }
                        final actual = mediciones[0];
                        final anterior = mediciones[1];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Anterior: ${_fecha(anterior.fecha)}',
                                style: ts(14, color: AppColors.pizarra)),
                            Text('Actual: ${_fecha(actual.fecha)}',
                                style: ts(14, color: AppColors.pizarra)),
                            const SizedBox(height: 12),
                            Text(
                              'La diferencia absoluta muestra la magnitud del cambio. '
                              'La variación porcentual indica su dirección respecto '
                              'al valor anterior. La diferencia de grasa corporal '
                              'se expresa en puntos porcentuales (p.p.). ',
                              style: ts(13, color: AppColors.pizarra),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '—: dato no registrado o porcentaje no calculable '
                              'cuando el valor anterior es cero.',
                              style: ts(13, color: AppColors.pizarra),
                            ),
                            for (final indicador
                                in compararMediciones(anterior, actual))
                              _indicador(indicador),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              gapAfter: 16,
            ),
          ],
        ),
      );
}
