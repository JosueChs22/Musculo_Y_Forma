import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/imagen_red.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/entrenamiento_controller.dart';
import '../controllers/rutinas_controller.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import 'widgets/ejercicio_detalle.dart';

/// Modo entrenamiento a pantalla completa (sin barras de navegación): un
/// ejercicio a la vez, series marcadas y descanso con cuenta regresiva.
class EntrenamientoView extends StatelessWidget {
  const EntrenamientoView({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final loading = context.select<RutinasController, bool>((c) => c.loading);
    final rutina = context.select<RutinasController, Routine?>(
      (c) => c.routines.where((r) => r.id == id).firstOrNull,
    );

    if (rutina == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: loading
                ? const SkeletonScope(child: Column(children: [SkeletonTitle(), SizedBox(height: 24), SkeletonBox(height: 280, radius: 22)]))
                : _Aviso(
                    titulo: 'No encontramos esta rutina',
                    texto: 'Puede que tu entrenador la haya cambiado. Revisa tus rutinas.',
                    onVolver: () => context.go('/rutinas'),
                  ),
          ),
        ),
      );
    }
    if (rutina.exercises.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _Aviso(
              titulo: 'Esta rutina no tiene ejercicios',
              texto: 'Pídele a tu entrenador que la complete.',
              onVolver: () => context.go('/rutinas'),
            ),
          ),
        ),
      );
    }
    // Un controlador por sesión; se descarta al salir de la pantalla.
    return ChangeNotifierProvider(
      key: ValueKey(rutina.id),
      create: (_) => EntrenamientoController(rutina),
      child: const _Sesion(),
    );
  }
}

class _Sesion extends StatelessWidget {
  const _Sesion();

  @override
  Widget build(BuildContext context) {
    final terminado = context.select<EntrenamientoController, bool>((c) => c.terminado);
    return PopScope(
      canPop: terminado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSalida(context);
      },
      child: Scaffold(
        body: SafeArea(
          // En curso usa todo el ancho (dos columnas en pantallas grandes); el resumen va centrado
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : kMedium,
            child: terminado
                ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: const _Resumen()))
                : const _EnCurso(),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmarSalida(BuildContext context) async {
  final c = context.read<EntrenamientoController>();
  if (c.terminado || c.seriesCompletadas == 0) {
    context.go('/rutinas');
    return;
  }
  final salir = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('¿Salir del entrenamiento?', style: ts(18, weight: kSemi)),
      content: Text('Llevas ${c.seriesCompletadas} de ${c.seriesTotales} series. El avance de esta sesión no se guarda.',
          style: ts(15, color: AppColors.pizarra)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir entrenando')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Salir'),
        ),
      ],
    ),
  );
  if (salir == true && context.mounted) context.go('/rutinas');
}

/// Pantalla durante el entrenamiento. Se adapta al ancho:
/// - teléfono y tableta vertical: una columna con las acciones fijas abajo;
/// - escritorio y tableta horizontal (900 px o más): el ejercicio a la izquierda
///   con la imagen grande y, a la derecha, series, lista de ejercicios y acciones.
class _EnCurso extends StatelessWidget {
  const _EnCurso();

  static const _anchoDosColumnas = 900.0;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EntrenamientoController>();
    return LayoutBuilder(builder: (context, caja) {
      final ancho = caja.maxWidth >= _anchoDosColumnas;
      final margen = ancho ? 32.0 : 20.0;
      return Column(children: [
        _Cabecera(c, margen: margen),
        Expanded(child: ancho ? _DosColumnas(c, margen: margen) : _UnaColumna(c)),
        if (!ancho) _Acciones(c),
      ]);
    });
  }
}

/// Cerrar, nombre de la rutina y avance general.
class _Cabecera extends StatelessWidget {
  const _Cabecera(this.c, {required this.margen});
  final EntrenamientoController c;
  final double margen;

  @override
  Widget build(BuildContext context) {
    final pct = (c.progreso * 100).round();
    return Padding(
      padding: EdgeInsets.fromLTRB(margen - 12, 8, margen, 0),
      child: Column(children: [
        Row(children: [
          IconButton(
            tooltip: 'Salir del entrenamiento',
            onPressed: () => _confirmarSalida(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.pizarra),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.rutina.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi)),
              Text('Ejercicio ${c.indice + 1} de ${c.ejercicios.length} · $pct%', style: ts(13, color: AppColors.pizarra)),
            ]),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 10),
          child: Semantics(
            label: 'Avance de la rutina $pct por ciento',
            child: MiniBar(value: c.progreso, fill: AppColors.ambar),
          ),
        ),
      ]),
    );
  }
}

/// Nombre, datos del ejercicio, nota del coach e instrucciones.
class _InfoEjercicio extends StatelessWidget {
  const _InfoEjercicio(this.e, {this.grande = false});
  final Exercise e;
  final bool grande;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.name.toUpperCase(), style: display(grande ? 40 : 30)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          InfoChip('${e.sets} × ${e.reps}'),
          if (e.pesoLabel != null) InfoChip(e.pesoLabel!),
          InfoChip(e.restLabel),
        ]),
        if (e.coachNote.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.ambarSoft, borderRadius: BorderRadius.circular(kRadiusControl)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.tips_and_updates_outlined, size: 20, color: AppColors.ambarOscuro),
              const SizedBox(width: 10),
              Expanded(child: Text(e.coachNote, style: ts(14))),
            ]),
          ),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => showEjercicioDetalle(context, e),
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: Text('Ver instrucciones', style: ts(14, weight: kSemi, color: AppColors.cobalto)),
        ),
      ]);
}

class _UnaColumna extends StatelessWidget {
  const _UnaColumna(this.c);
  final EntrenamientoController c;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          // Tableta vertical: la columna no se estira de borde a borde
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _Media(c.actual),
              const SizedBox(height: 18),
              _InfoEjercicio(c.actual),
              const SizedBox(height: 16),
              _Series(c),
              const SizedBox(height: 20),
              _Lista(c),
            ],
          ),
        ),
      );
}

class _DosColumnas extends StatelessWidget {
  const _DosColumnas(this.c, {required this.margen});
  final EntrenamientoController c;
  final double margen;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Padding(
            padding: EdgeInsets.fromLTRB(margen, 24, margen, 24),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Izquierda: el ejercicio, con la imagen grande
              // La imagen se ajusta al alto disponible para que el bloque completo
              // (imagen, nombre, datos y nota) quepa sin desplazarse.
              Expanded(
                flex: 6,
                child: LayoutBuilder(
                  builder: (context, caja) => ListView(children: [
                    _Media(c.actual, maximo: (caja.maxHeight - 270).clamp(180.0, 520.0)),
                    const SizedBox(height: 20),
                    _InfoEjercicio(c.actual, grande: true),
                  ]),
                ),
              ),
              const SizedBox(width: 32),
              // Derecha: series, ejercicios y acciones en una tarjeta fija
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    boxShadow: kShadowCard,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Eyebrow('Series'),
                        const SizedBox(height: 10),
                        _Series(c),
                        const SizedBox(height: 20),
                        const Eyebrow('Ejercicios de la rutina'),
                      ]),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 4),
                        child: _Lista(c, enTarjeta: true),
                      ),
                    ),
                    _Acciones(c),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _Media extends StatelessWidget {
  const _Media(this.e, {this.maximo});
  final Exercise e;
  final double? maximo;

  @override
  Widget build(BuildContext context) {
    final quieto = MediaQuery.disableAnimationsOf(context);
    final media = quieto ? (e.imageUrl ?? e.gifUrl) : (e.gifUrl ?? e.imageUrl);
    if (media == null || media.isEmpty) return const SizedBox.shrink(); // sin imagen no se deja un hueco
    return LayoutBuilder(builder: (context, c) {
      // En teléfonos la imagen deja a la vista las series y el botón principal
      final alto = MediaQuery.sizeOf(context).height;
      final lado = c.maxWidth.clamp(0.0, maximo ?? (alto < 760 ? 220.0 : 300.0));
      return Center(
        child: Semantics(
          image: true,
          label: 'Demostración del ejercicio ${e.name}',
          child: ImagenRed(media, size: lado, radius: 22),
        ),
      );
    });
  }
}

/// Una píldora por serie: llena las hechas y resalta la que sigue.
class _Series extends StatelessWidget {
  const _Series(this.c);
  final EntrenamientoController c;

  @override
  Widget build(BuildContext context) {
    final total = c.actual.sets;
    return Semantics(
      label: 'Series: ${c.hechasActual} de $total completadas',
      child: Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : kFast,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < c.hechasActual ? AppColors.indigo : (i == c.hechasActual ? AppColors.card : AppColors.track),
                borderRadius: BorderRadius.circular(kRadiusControl),
                border: i == c.hechasActual ? Border.all(color: AppColors.cobalto, width: 2) : null,
              ),
              child: i < c.hechasActual
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                  : Text('${i + 1}', style: ts(15, weight: kSemi, color: i == c.hechasActual ? AppColors.cobalto : AppColors.pizarra)),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Todos los ejercicios de la rutina, para saltar a cualquiera.
class _Lista extends StatelessWidget {
  const _Lista(this.c, {this.enTarjeta = false});
  final EntrenamientoController c;
  final bool enTarjeta; // en la tarjeta lateral (escritorio) no lleva su propio panel

  @override
  Widget build(BuildContext context) {
    final filas = Column(children: [
        for (var i = 0; i < c.ejercicios.length; i++)
          Pressable(
            onTap: () => c.irA(i),
            radius: 12,
            selected: i == c.indice,
            semanticLabel: '${c.ejercicios[i].name}, ${c.seriesHechas(i)} de ${c.ejercicios[i].sets} series',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Icon(
                  c.seriesHechas(i) >= c.ejercicios[i].sets
                      ? Icons.check_circle_rounded
                      : (i == c.indice ? Icons.play_circle_fill_rounded : Icons.radio_button_unchecked),
                  color: c.seriesHechas(i) >= c.ejercicios[i].sets || i == c.indice ? AppColors.cobalto : AppColors.pizarra,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(c.ejercicios[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(15, weight: i == c.indice ? kSemi : kRegular)),
                ),
                Text('${c.seriesHechas(i)}/${c.ejercicios[i].sets}', style: ts(13, color: AppColors.pizarra)),
              ]),
            ),
          ),
      ]);
    if (enTarjeta) return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: filas);
    return Panel(padding: const EdgeInsets.symmetric(vertical: 8), child: filas);
  }
}

/// Barra inferior: descanso en curso o el siguiente paso.
class _Acciones extends StatelessWidget {
  const _Acciones(this.c);
  final EntrenamientoController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      // Alineada con la columna de contenido (en tableta no se estira de borde a borde)
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: c.descansando ? _Descanso(c) : _Siguiente(c),
        ),
      ),
    );
  }
}

class _Descanso extends StatelessWidget {
  const _Descanso(this.c);
  final EntrenamientoController c;

  @override
  Widget build(BuildContext context) {
    final m = c.descanso ~/ 60, s = c.descanso % 60;
    return Row(children: [
      Expanded(
        child: Semantics(
          liveRegion: true,
          label: 'Descanso, quedan ${c.descanso} segundos',
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('Descanso'),
              Text('$m:${s.toString().padLeft(2, '0')}', style: display(40, color: AppColors.indigo)),
            ]),
          ),
        ),
      ),
      SecondaryButton(label: '+15 s', onPressed: c.sumarDescanso),
      const SizedBox(width: 10),
      PrimaryButton(label: 'Saltar', icon: Icons.skip_next_rounded, onPressed: c.saltarDescanso),
    ]);
  }
}

class _Siguiente extends StatelessWidget {
  const _Siguiente(this.c);
  final EntrenamientoController c;

  @override
  Widget build(BuildContext context) {
    final todoListo = c.seriesCompletadas == c.seriesTotales;
    final (String label, IconData icon, VoidCallback accion) = c.ejercicioCompleto
        ? (c.esUltimo || todoListo
            ? ('Terminar rutina', Icons.flag_rounded, c.terminar)
            : ('Siguiente ejercicio', Icons.arrow_forward_rounded, c.siguiente))
        : ('Completar serie ${c.hechasActual + 1} de ${c.actual.sets}', Icons.check_rounded, () {
            HapticFeedback.mediumImpact();
            c.completarSerie();
          });

    return Row(children: [
      IconButton.filledTonal(
        tooltip: 'Ejercicio anterior',
        onPressed: c.indice == 0 ? null : c.anterior,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      const SizedBox(width: 10),
      Expanded(child: PrimaryButton(label: label, icon: icon, onPressed: accion)),
      const SizedBox(width: 10),
      if (c.hechasActual > 0 && !c.ejercicioCompleto)
        IconButton.filledTonal(
          tooltip: 'Deshacer serie',
          onPressed: c.deshacerSerie,
          icon: const Icon(Icons.undo_rounded),
        )
      else
        IconButton.filledTonal(
          tooltip: c.esUltimo ? 'Terminar rutina' : 'Saltar ejercicio',
          onPressed: c.esUltimo ? c.terminar : c.siguiente,
          icon: Icon(c.esUltimo ? Icons.flag_outlined : Icons.chevron_right_rounded),
        ),
    ]);
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    final c = context.read<EntrenamientoController>();
    final min = c.duracion.inMinutes, seg = c.duracion.inSeconds % 60;
    return ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 24),
      const Center(child: Icon(Icons.emoji_events_rounded, size: 72, color: AppColors.ambar)),
      const SizedBox(height: 16),
      Center(child: Text('¡RUTINA TERMINADA!', textAlign: TextAlign.center, style: display(36))),
      const SizedBox(height: 6),
      Center(child: Text(c.rutina.title, style: ts(16, color: AppColors.pizarra))),
      const SizedBox(height: 28),
      Panel(
        child: Wrap(spacing: 28, runSpacing: 16, alignment: WrapAlignment.spaceAround, children: [
          _Dato('Duración', '$min:${seg.toString().padLeft(2, '0')}'),
          _Dato('Ejercicios', '${c.ejerciciosCompletos}/${c.ejercicios.length}'),
          _Dato('Series', '${c.seriesCompletadas}/${c.seriesTotales}'),
        ]),
      ),
      const SizedBox(height: 28),
      PrimaryButton(label: 'Volver a mis rutinas', icon: Icons.check_rounded, onPressed: () => context.go('/rutinas')),
      const SizedBox(height: 12),
      SecondaryButton(label: 'Ir al inicio', onPressed: () => context.go('/')),
    ]);
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(valor, style: display(34, color: AppColors.indigo)),
        Text(label, style: ts(14, color: AppColors.pizarra)),
      ]);
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.titulo, required this.texto, required this.onVolver});
  final String titulo;
  final String texto;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.fitness_center, size: 48, color: AppColors.pizarra),
          const SizedBox(height: 12),
          Text(titulo, textAlign: TextAlign.center, style: ts(18, weight: kSemi)),
          const SizedBox(height: 6),
          Text(texto, textAlign: TextAlign.center, style: ts(15, color: AppColors.pizarra)),
          const SizedBox(height: 20),
          SecondaryButton(label: 'Ver mis rutinas', onPressed: onVolver),
        ]),
      );
}
