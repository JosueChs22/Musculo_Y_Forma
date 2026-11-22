import '../../../core/base_controller.dart';
import '../../admin/models/reglamento.dart';
import '../../admin/services/reglamentos_service.dart';

/// RF-093: reglamento vigente que consulta el cliente (solo lectura).
class ReglamentoController extends BaseController {
  ReglamentoController(this._service);

  final ReglamentosService _service;

  List<Reglamento> _reglamentos = const [];
  List<Reglamento> get reglamentos => _reglamentos;

  @override
  Future<void> fetch() async {
    _reglamentos = await _service.getReglamentosVigentes();
  }
}
