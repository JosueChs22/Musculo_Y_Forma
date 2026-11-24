import '../../../core/base_controller.dart';
import '../../secretaria/models/clase.dart';
import '../models/horario_del_dia.dart';
import '../services/horarios_service.dart';

/// RF-095: horarios de clases (solo lectura) agrupados por día de la semana,
/// empezando por hoy. Solo clases y horarios activos.
class HorariosController extends BaseController {
  HorariosController(this._service, {DateTime Function()? ahora}) : _ahora = ahora ?? DateTime.now;

  final HorariosService _service;
  final DateTime Function() _ahora;

  List<HorarioDelDia> _dias = const [];

  /// Solo días con clases; el primero es hoy (si tiene) y luego los siguientes en orden circular.
  List<HorarioDelDia> get dias => _dias;

  /// 1 = lunes … 7 = domingo.
  int get hoy => _ahora().weekday;

  @override
  Future<void> fetch() async {
    _dias = agrupar(await _service.getClases(), hoy: hoy);
  }

  /// Agrupa por día, filtra lo inactivo, ordena por hora y rota para que [hoy] vaya primero.
  static List<HorarioDelDia> agrupar(List<Clase> clases, {required int hoy}) {
    final porDia = <int, List<SesionClase>>{};
    for (final c in clases) {
      if (!c.activa) continue;
      for (final h in c.horariosActivos) {
        for (final d in h.dias.toSet()) {
          if (d < 1 || d > 7) continue;
          (porDia[d] ??= []).add(SesionClase(
            idClase: c.id,
            nombre: c.nombre,
            descripcion: c.descripcion,
            horaInicio: h.horaInicio,
            horaFin: h.horaFin,
          ));
        }
      }
    }
    return [
      for (var i = 0; i < 7; i++)
        if (porDia[(hoy - 1 + i) % 7 + 1] case final s?)
          HorarioDelDia(
            dia: (hoy - 1 + i) % 7 + 1,
            sesiones: s..sort((a, b) => a.horaInicio.compareTo(b.horaInicio)),
          ),
    ];
  }
}
